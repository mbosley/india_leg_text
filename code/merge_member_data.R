###############################################################################
## TITLE : Merge Colonial India Member Data to Speech Dataset
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-19
###############################################################################

##### FUNCTIONS #####
fuzzy_join_inst <- function(year_val, inst) {
  clean_speech_data %>%
    filter(
      institution == inst,
      speaker != "the President",
      year == year_val
    ) %>%
    drop_na() %>%
    fuzzyjoin::stringdist_left_join(
                member_data_clean %>% filter(
                                        institution == inst,
                                        year == year_val
                                      ),
                by = "speaker",
                max_dist = 5, distance_col = "distance"
              ) %>%
    return()
}

fuzzy_join_no_year <- function(inst) {
  test <- clean_speech_data %>%
    filter(
      institution == inst,
      !str_detect(speaker, "^*.resid.*")
    ) %>%
    drop_na() %>%
    fuzzyjoin::stringdist_left_join(
                 member_data_clean %>%
                 filter(institution == inst),
                 by = "speaker",
                 max_dist = 5, distance_col = "distance"
               ) %>%
    return()
}

##### IMPLEMENTATION #####

library(tidyverse)

## load and clean data
speech_data <- read_csv("data/clean/clean_speech_data.csv")

## member_data <- read_csv("data/raw/member_data.csv")
member_data <- readxl::read_xlsx(
                          "~//Dropbox (University of Michigan)/Colonial Legislatures Project/Data/British India Legislature Members.xlsx"
                        ) %>%
  select(
    institution = Institution, year_position = Year_Position,
    year_nominated = Year_Nominated, speaker = Name,
    tenure = Tenure, elected = Elected, representation = Representation,
    constit = Constituency, occupation = Occupation, party = Party...13
  ) %>%
  mutate(
    institution = case_when(
        institution == "Imperial Legislative Council" ~ "ilcd",
        institution == "The Council of State" ~ "cosd",
        institution == "The Legislative Assembly" ~ "clad"
    )
  )

clean_speech_data <- speech_data %>%
  mutate(speech_id = 1:nrow(.)) %>%
  mutate(
    speaker = str_remove(speaker, "^.*(The).*(Honourable)\\s"),
    speaker = str_remove(speaker, "^.*([0-9]|l){1,3}.\\s"),
    speaker = str_remove(speaker, "^.{1,2}(?=[A-Z])"),
    year = lubridate::year(date),
  ) %>%
  rename(institution = collection)

member_data_clean <- member_data %>%
  rename(year = year_position) %>%
  filter(!is.na(institution))

## fuzzy match speeches to speaker data
## clad_tbl <- tibble()
## ilcd_tbl <- tibble()
## cosd_tbl <- tibble()
## for (year in na.exclude(unique(clean_speech_data$year))) {
##   print(paste("Doing: ", year))
##   clad_tbl <- bind_rows(clad_tbl, fuzzy_join_no_year("clad"))
##   ilcd_tbl <- bind_rows(ilcd_tbl, fuzzy_join_no_year("ilcd"))
##   cosd_tbl <- bind_rows(cosd_tbl, fuzzy_join_no_year("cosd"))
## }

all_speeches <-
  bind_rows(
    fuzzy_join_no_year("clad"),
    fuzzy_join_no_year("ilcd"),
    fuzzy_join_no_year("cosd")
  )

## summarize and write to disk
all_speeches_clean <- all_speeches %>%
  group_by(speech_id) %>%
  filter(distance == min(distance)) %>%
  select(speech_id, institution = institution.x, date,
         pdf_filename, speaker = speaker.y, speeches,
         elected, representation, occupation, party, tenure) %>%
  ungroup() %>%
  write_csv("data/clean/merged_speech_data.csv")



## inspect breakdown
all_speeches_clean %>%
  mutate(representation = coalesce(representation, "None")) %>%
  group_by(representation, institution, elected) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = reorder(representation, (count)),
             y = count, fill = as.factor(elected))) +
  geom_bar(stat = "identity") +
  facet_wrap(~institution) +
  coord_flip()

all_speeches_clean %>%
  filter(institution == "clad") %>%
  mutate(elected = as.factor(elected)) %>%
  group_by(date, elected) %>%
  count() %>%
  ggplot(aes(x = date, y = n, color = elected))
