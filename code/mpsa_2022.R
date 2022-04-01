library(tidyverse)
library(tidytext)
library(stm)
library(quanteda)
library(future)
library(ggthemes)
library(scales)
library(ggridges)



## load data
speech_days <- read_csv("../data/clean/combined_speeches.csv")
merged_speech_data <- read_csv("../data/clean/merged_speech_data.csv")
clean_speech_data <- read_csv("../data/clean/clean_speech_data.csv")

## clean_speech_data %>%
speech_days %>%
  group_by(collection) %>%
  count()

speech_days %>%
  filter(
    pdf_filename == "clad_04_03_02-04-1932.pdf"
  ) %>%
  slice(17) %>%
  pull(body) %>%
  cat()


## simplest: stm where every document is a day of speeches
speech_days_clean <- speech_days %>%
  mutate(collection = case_when(
           str_detect(collection, "clad") ~ "clad",
           str_detect(collection, "cosd") ~ "cosd",
           str_detect(collection, "ilcd") ~ "ilcd"
         ),
         id = 1:nrow(.))


corpus <- speech_days_clean %>%
  mutate(year = lubridate::year(date)) %>%
  select(collection, id, body, year) %>%
  corpus(
    text_field = "body", docid_field = "id",
  )

corpus2 <- merged_speech_data %>%
  select(
    collection = institution, date,
    id = speech_id, speaker, speeches
  ) %>%
  corpus(
    text_field = "speeches", docid_field = "id"
  )

dfm <- corpus %>%
  tokens(
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_numbers = TRUE,
    remove_separators = FALSE
  ) %>%
  tokens_keep(
    min_nchar = 3
  ) %>%
  tokens_remove(
    c(stopwords("en"), "sir", "honourable")
  ) %>%
  tokens_wordstem() %>%
  dfm()

dfm2 <- corpus2 %>%
  tokens(
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_numbers = TRUE,
    remove_separators = FALSE
  ) %>%
  tokens_keep(
    min_nchar = 3
  ) %>%
  tokens_remove(
    c(stopwords("en"), "sir", "honourable")
  ) %>%
  tokens_wordstem() %>%
  dfm()

stm_out <- readRDS("../data/clean/stm_full_day_out.rds")
stm2_out <- readRDS("../data/clean/stm_speech_out.rds")

## ANALYZE FIRST MODEL
td_beta <- tidy(stm_out)
td_gamma <- tidy(
  stm_out, matrix = "gamma"
)

top_terms <- td_beta %>%
  arrange(beta) %>%
  group_by(topic) %>%
  top_n(7, beta) %>%
  arrange(-beta) %>%
  select(topic, term) %>%
  summarise(terms = list(term)) %>%
  mutate(terms = map(terms, paste, collapse = ", ")) %>%
  unnest()

gamma_terms <- td_gamma %>%
  group_by(topic) %>%
  summarise(gamma = mean(gamma)) %>%
  arrange(desc(gamma)) %>%
  left_join(top_terms, by = "topic")

time_gamma <- td_gamma %>%
  left_join(gamma_terms %>% select(-gamma)) %>%
  ## filter(topic == 20) %>%
  left_join(
    speech_days_clean %>%
    mutate(year = lubridate::year(date)) %>%
    select(document = id, date, year, collection)
  )

time_gamma %>%
  ggplot(aes(x = date, y = gamma, color = collection)) +
  geom_point()


## by year
time_gamma %>%
  mutate(
    topic_terms = paste0(topic, ": ", terms),
    month = lubridate::floor_date(date, "month"),
  ) %>%
  filter(!is.na(date)) %>%
  mutate(
    treated = case_when(
      year <= 1919 | collection == "ilcd" ~ "1: Before 1919 Reform",
      year > 1920 & year < 1935 ~ "2: Before 1935 Reform",
      year >= 1935 ~ "3: After 1935 Reform"
    )
  ) %>%
  ## filter(topic == 20) %>%
  filter(topic %in% c(1, 20, 54, 17, 46,
                      41, 45, 33, 11, 37,
                      38, 32, 22, 35, 51)) %>%
  group_by(month, topic_terms, treated) %>%
  summarize(mean_gamma = mean(gamma)) %>%
  ggplot(aes(x = month, y = log(mean_gamma),
             ## color = collection,
             linetype = as.factor(treated))) +
  geom_point(alpha = 1, size = 0.5) +
  geom_vline(xintercept = as.Date("1921-01-01"), linetype = "dashed") +
  geom_vline(xintercept = as.Date("1935-01-01"), linetype = "dashed") +
  facet_wrap(~topic_terms, ncol = 4) +
  geom_smooth(method = "lm", size = 0.75) +
  theme_bw() +
  theme(strip.text.x = element_text(size = 4.5)) +
  theme(legend.position = c(0.875, 0.07)) +
  labs(x = "Month", y = "Average Topic Prevalence (Log)",
       linetype = "Institutional Period")


gamma_terms %>%
  arrange(gamma) %>%
  print(n = 60)

### ANALYZE SECOND MODEL
td_beta2 <- tidy(stm2_out)
td_gamma2 <- tidy(
  stm2_out, matrix = "gamma"
)

td_gamma2$gamma %>% quantile()
scales::percent(td_gamma2$gamma)

  ggplot(aes(log(gamma))) +
  geom_density()

top_terms2 <- td_beta2 %>%
  arrange(beta) %>%
  group_by(topic) %>%
  top_n(7, beta) %>%
  arrange(-beta) %>%
  select(topic, term) %>%
  summarise(terms = list(term)) %>%
  mutate(terms = map(terms, paste, collapse = ", ")) %>%
  unnest()

gamma_terms2 <- td_gamma2 %>%
  group_by(topic) %>%
  summarise(gamma = mean(gamma)) %>%
  arrange(desc(gamma)) %>%
  left_join(top_terms2, by = "topic")

gamma_terms2 %>%
  top_n(20, gamma) %>%
  ggplot(aes(topic, gamma, label = terms, fill = topic)) +
  geom_col(show.legend = FALSE) +
  geom_text(hjust = 0, nudge_y = 0.0005, size = 3) +
  coord_flip() +
  scale_y_continuous(expand = c(0,0),
                     limits = c(0, 0.09),
                     labels = percent_format()) +
  theme_tufte(ticks = FALSE) +
  theme(plot.title = element_text(size = 16),
        plot.subtitle = element_text(size = 13)) +
  labs(x = NULL, y = expression(gamma),
       title = "Top 20 topics by prevalence in the Hacker News corpus",
       subtitle = "With the top words that contribute to each topic")

effects <- estimateEffect(1:60 ~ collection, stm_out, metadata = docvars(dfm))

time_gamma2 <- td_gamma2 %>%
  left_join(gamma_terms2 %>% select(-gamma)) %>%
  ## filter(topic == 20) %>%
  left_join(
    merged_speech_data %>%
    mutate(id = 1:nrow(.)) %>%
    mutate(year = lubridate::year(date)) %>%
    select(
      document = id, date,
      year, collection = institution,
      representation, elected, occupation,
      party, tenure
    )
  )

time_gamma %>%
  ggplot(aes(x = date, y = gamma, color = collection)) +
  geom_point()


## by year
time_gamma2 %>%
  filter(!is.na(date)) %>%
  mutate(decade = round(year, -1)) %>%
  filter(topic %in% c(1, 20, 54, 17, 46, 41, 45, 33)) %>%
  ## filter(topic == 20) %>%
  ## group_by(year, collection, topic, terms) %>%
  ## summarize(mean_gamma = mean(gamma)) %>%
  ggplot(aes(x = log(gamma), y = as.factor(year))) +
  ## ggplot(aes(x = date, y = gamma, color = as.factor(terms))) +
  geom_density_ridges() +
  ## geom_smooth(method = "lm") +
  facet_grid(~collection)
  ## facet_wrap(~collection, ncol = 1, scales = "free_x")


time_gamma_2_clean <- time_gamma2 %>%
  mutate(
    group = case_when(
      str_detect(representation, "Non-Muham") ~ "Non-Muslim",
      str_detect(representation, "Muham") &
      !str_detect(representation, "Non-Muham") ~ "Muslim",
      str_detect(representation, "Nominated") ~ "Unelected",
      str_detect(representation, "Landholder") ~ "Landholder",
      ## TRUE ~ "Other"
      TRUE ~ representation
    ),
    rural = case_when(
      str_detect(representation, "(R|r)ur") ~ 1,
      str_detect(representation, "(U|u)rb") ~ 0#,
      ## TRUE ~ NA
    )
  ) %>%
  mutate(
    month = lubridate::floor_date(date, "month"),
    topic_terms = paste0(topic, ": ", terms)
  ) %>%
  filter(!is.na(date)) %>%
  mutate(
    treated = case_when(
      year <= 1935 ~ "1: Before 1935 Reform",
      year > 1935 ~ "2: After 1935 Reform"
    )
  ) %>%
  ## filter(collection == "clad") %>%
  ## filter(topic %in% 1:20) %>%
  filter(!is.na(elected)) %>%
  filter(topic %in% c(30, 5, 34, 41, 14, 18, 15)) %>%
  group_by(
    month, topic_terms,
    treated, elected#,
    ## party, rural
    ## representation,
    ## occupation, party, tenure
  ) %>%
  summarize(mean_gamma = mean(gamma))

## models <- time_gamma_2_clean %>%
##   split(.$topic_terms) %>%
##   map(
##     function (x)
##       lm(gamma ~ elected*treated, data = x)
##   )

## models %>%
##   map(summary)

time_gamma_2_clean %>%
  ggplot(aes(x = month, y = log(mean_gamma),
             color = as.factor(elected),
             linetype = as.factor(treated)
             )
         ) +
  ## ggplot(aes(x = month, y = log(mean_gamma), color = collection,
  ##            linetype = as.factor(treated))) +
  ## geom_point(alpha = 0.5, position = "jitter") +
  geom_point(size = 0.5, alpha = 1) +
  ## geom_vline(xintercept = as.Date("1921-01-01"), linetype = "dashed") +
  geom_vline(xintercept = as.Date("1936-01-01"), linetype = "dashed") +
  ## geom_vline(xintercept = 1936, linetype = "dashed") +
  ## geom_vline(xintercept = as.Date("1939-01-01"), linetype = "dashed") +
  ## geom_line() +
  ## facet_grid(elected~topic_terms) +
  facet_wrap(~topic_terms) +
  geom_smooth(method = "lm") +
  scale_color_brewer(palette = "Paired") +
  theme_bw() +
  theme(strip.text.x = element_text(size = 4.75)) +
  theme(legend.position = c(0.65, 0.12), legend.direction = "vertical",
        legend.box = "horizontal") +
  labs(x = "Month", y = "Average Topic Prevalence (Log)",
       color = "Elected", linetype = "Institutional Period")

time_gamma_2_clean %>%
  group_by(month, topic_terms, treated) %>%
  pivot_wider(names_from = elected, values_from = mean_gamma) %>%
  mutate(diff_mean_gamma = `1` - `0`) %>%
  ggplot(aes(x = month, y = diff_mean_gamma,
             linetype = as.factor(treated))) +
  geom_point(size = 0.5) +
  geom_smooth(method = "lm", size = 0.75) +
  geom_vline(xintercept = as.Date("1936-01-01"), linetype = "dashed") +
  facet_wrap(~topic_terms) +
  theme(strip.text.x = element_text(size = 5)) +


gamma_terms %>%
  arrange(gamma) %>%
  print(n = 60)

#### analyze tbip


range_to_keep <- td_gamma2 %>%
  filter(topic == 30) %>%
  mutate(decile = ntile(gamma, 10)) %>%
  filter(decile == 10) %>%
  arrange(desc(gamma)) %>%
  pull(document)

## educ_speech_data <-

merged_speech_data %>%
  slice(range_to_keep) %>%
  mutate(decade_group = ifelse(date < as.Date("1930-01-01"), 0, 1)) %>%
  mutate(speaker = paste0(speaker, "-", decade_group)) %>%
  write_csv("../data/clean/educ_speech_data.csv")

educ_speech_data %>%
  group_by(date, elected) %>%
  count() %>%
  mutate(treated = ifelse(date > as.Date("1936-01-1"), 1, 0)) %>%
  ggplot(aes(x = date, y = n, color = as.factor(elected), linetype = as.factor(treated))) +
  geom_point(alpha = 0.7, position = "jitter") +
  geom_smooth(method = "lm") +
  labs(x = "Date", y = "Number of Speeches about Education", color = "Elected")

library(ggridges)

## tbip_df <- read_csv("~/Downloads/ideal_point_df.csv")
tbip_df <- read_csv("~/Downloads/results.csv")

## tbip_df_clean <-


tbip_df_clean <- tbip_df %>%
  select(ideal_points, names) %>%
  ## separate(names, c("names", "meta"), sep = "-") %>%
  ## separate(meta, c("decade", "elected"), sep = " ")
  mutate(
    elected = str_extract(names, "\\(.\\)"),
    elected = as.numeric(str_remove_all(elected, "[^0-9]")),
    names = str_remove(names, " \\(.\\)"),
    decade = names %>% str_extract("..$") %>% str_remove("-"),
    names = names %>% str_remove("..$"),
    decade = ifelse(decade == 0, "1921 - 1930", "1930 - 1940")
  ) %>%
  left_join(
    merged_speech_data %>%
    select(names = speaker, representation, occupation, party) %>%
    unique( )
  ) %>%
  mutate(
    representation = case_when(
      str_detect(representation, "Non-Muham") ~ "Non-Muslim",
      str_detect(representation, "Muham") &
      !str_detect(representation, "Non-Muham") ~ "Muslim",
      str_detect(representation, "Nominated") ~ "Nominated",
      str_detect(representation, "Sikh") ~ "Non-Muslim",
      str_detect(representation, "Non-Official") ~ "Other",
      str_detect(representation, "European") ~ "Other",
      str_detect(representation, "Land") ~ "Other",
      TRUE ~ "Other"
    )
  ) %>%
  mutate(elected = ifelse(elected == 1, "Elected", "Unelected"))

tbip_df_clean %>%
  ggplot(aes(
    ideal_points, y = forcats::fct_rev(elected),
    fill = forcats::fct_rev(elected),
    ## color = forcats::fct_rev(elected)
  )) +
  ## geom_density()
  geom_density_ridges(
    alpha = 0.6, point_alpha = 1, point_size = 0.5,
    scale = 200, jittered_points = TRUE
  ) +
  scale_fill_brewer(palette = "Paired") +
  scale_color_brewer(palette = "Paired") +
  ## scale_discrete_manual(aesthetics = "point_color", values = "black") +
  facet_wrap(~decade, ncol = 1) +
  theme_bw() +
  scale_y_discrete(expand = expand_scale(add = c(0.2, 225)), breaks = NULL) +
  labs(x = "Education Ideal Point", y = "",
       fill = "Elected", color = "Elected") +
  theme(legend.position = "bottom")

tbip_df_clean %>%
  ggplot(aes(
    ideal_points, y = representation,
    fill = representation,
    ## color = representation
  )) +
  geom_density_ridges(
    alpha = 0.6, point_alpha = 1, point_size = 0.5,
    scale = 0.9, jittered_points = TRUE
  ) +
  scale_fill_brewer(palette = "Set1") +
  scale_color_brewer(palette = "Set1") +
  facet_grid(forcats::fct_rev(elected)~decade, scales = "free_y") +
  theme_bw() +
  scale_y_discrete(expand = expand_scale(add = c(0.2, .8)), breaks = NULL) +
  labs(x = "Education Ideal Point", y = "",
       fill = "Representation", color = "Representation") +
  theme(legend.position = "bottom") +
  coord_cartesian(clip = "off")

tbip_df_clean %>%
  mutate(
    party = case_when(
      str_detect(party, "Muslim") ~ "Muslim League",
      str_detect(party, "Congress") ~ "National Congress",
      is.na(party) |
      str_detect(party, "British") |
      str_detect(party, "Independent") ~ "None",
      TRUE ~ "Other"
    )
  ) %>%
  ggplot(aes(
    ideal_points, y = party,
    fill = party,
    ## color = party
  )) +
  geom_density_ridges(
    alpha = 0.6, point_alpha = 1, point_size = 0.5,
    scale = 0.9, jittered_points = TRUE
  ) +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Set2") +
  facet_grid(~decade, scales = "free_y") +
  theme_bw() +
  scale_y_discrete(expand = expand_scale(add = c(0.2, 1)), breaks = NULL) +
  labs(x = "Education Ideal Point", y = "",
       fill = "Party", color = "Party") +
  theme(legend.position = "bottom") +
  coord_cartesian(clip = "off")

tbip_df_clean %>%
  group_by(occupation) %>%
  count() %>%
  print(n = 100)

merged_speech_data

tbip_df_clean <-
  ggplot(aes(x = ideal_points, fill = as.factor(elected))) +
  geom_density(alpha = 0.4)

library(huxtable)

tbip_df_clean %>%
  lm(ideal_points ~ elected * decade, data = .) %>%
  huxreg() %>%
  print_latex()

t.test(
  tbip_df_clean %>% filter(elected == 0) %>% pull (ideal_points),
  tbip_df_clean %>% filter(elected == 1) %>% pull (ideal_points),
)


## analyze schools
schools <- read_csv("../data/clean/schools_panel.csv")

schools$district_name %>% unique()

schools %>%
  filter(!is.na(district_name)) %>%
  mutate(district_name = case_when(
           str_detect(district_name, "BIH|BEH|ORI") ~ "Bihar and Orissa",
           str_detect(district_name, "CHHOTA") ~ "Chhota",
           str_detect(district_name, "BEN") ~ "Bengal",
           str_detect(district_name, "JAL") ~ "Jalpatiguri",
           str_detect(district_name, "BUR") ~ "Burma",
           str_detect(district_name, "ASS|EASTER") ~ "Eastern Bengal and Assam",
           str_detect(district_name, "DACC") ~ "Dacca",
           str_detect(district_name, "RAJSHAHI") ~ "Rajshahi"
         )) %>%
  mutate(year = str_extract(year, "[0-9]{4}")) %>%
  group_by(district_name, year) %>%
  summarize(sum_schools = sum(schools_num)) %>%
  ungroup() %>%
  ggplot(aes(x = year, y = sum_schools, color = district_name)) +
  geom_point() +
  geom_line()

schools$district_name
