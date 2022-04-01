###############################################################################
## TITLE : Run Structural Topic Model
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-23
###############################################################################

#### IMPLEMENTATION ####

library(tidyverse)
library(tidytext)
library(stm)
library(quanteda)


members_data <- readxl::read_xlsx("~/Dropbox (University of Michigan)/Colonial Legislatures Project/British India Legislature - Winter 2022/British India Legislature Members.xlsx")

members_clean <- members_data %>%
  select(
    body = Institution, elected = Elected,
    year = Year_Position, name = Name, occupation = Occupation,
    representation = Representation,
    position = Position, religion = Religion, urb_rural = `Urban/Rural`,
    prov = Province, party1 = Party...13, party2 = Party...22
  ) %>%
  arrange(year) %>%
  filter(name != ".") %>%
  mutate(body = body %>% str_remove("(T|t)(H|h)(E|e)") %>% str_trim())

merged_data$speaker %>% unique()

members_clean %>%
  select(body, year, name, elected, occupation, position, representation) %>%
  pull(representation) %>%
  unique()

  group_by(body, year, elected, occupation, position, representation) %>%
  count() %>%
  arrange(year) %>%
  pivot_wider(names_from = elected, values_from = n) %>%
  rename(n_appointed = `0`, n_elected = `1`, n_other = `NA`) %>%
  mutate(across(everything(), function (x) coalesce(x, 0))) %>%
  mutate(prop_elected = n_elected / (n_appointed + n_elected + n_other)) %>%
  ggplot(aes(x = year, y = prop_elected, color = body)) +
  geom_line()


actual_merged_data <- read_csv("data/clean/merged_speech_data.csv")

actual_merged_data %>%
  mutate(elected = as.factor(elected)) %>%
  group_by(date, elected, .drop = FALSE) %>%
  count() %>%
  ## pivot_wider(names_from = elected, values_from = n)  %>%
  ## mutate(across(everything(), function (x) coalesce(x, 0))) %>%
  ## rename(n_appointed = `0`, n_elected = `1`) %>%
  ggplot(aes(x = date, y = n, color = elected)) +
  geom_point()




merged_data <- read_csv("data/clean/clean_speech_data.csv") %>%
  mutate(
    speech_id = 1:nrow(.)
  ) %>%
  ## slice(1:1000) %>%
  unique()

## tidy_data <- merged_data %>%
##   unnest_tokens(word, speeches) %>%
##   anti_join(get_stopwords()) %>%
##   filter(!str_detect(word, "[0-9+]")) %>%
##   add_count(word) %>%
##   filter(n > 100) %>%
##   select(-n)

dfm <- merged_data %>%
  corpus(text_field = "speeches", docid_field = "speech_id") %>%
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
  dfm()

dfm

dfm_remove()

stm_test <- stm(dfm, K = 10, verbose = TRUE)

plot(stm_test)

test_effect <- stm_test %>%
  estimateEffect(1:10 ~ collection, ., metadata = docvars(dfm_subset(dfm, ntoken(dfm) > 0))
                 )


processed <- stm::textProcessor(merged_data$speeches, metadata = merged_data)
out <- stm::prepDocuments(processed$documents, processed$vocab, processed$meta)
docs <- out$documents
vocab <- out$vocab
meta <- out$meta

## run stm
stm_out <- stm::stm(
  documents = docs, vocab = vocab, K = 40,
  prevalence = ~elected + splines::bs(date), content = ~elected,
  max.em.its = 75, init.type = "Spectral",
  data = meta, verbose = TRUE
)

## inspect topic proportions
plot(stm_out, type = "summary")

## regress
prep <- stm::estimateEffect(
               formula = 1:20 ~ elected + splines::bs(date),
               stmobj = stm_out, metadata = meta,
               uncertainty = "Global"
             )

## inspect regression results
summary(prep)


## see coefficents
plot(
  prep, covariate = "elected", topics = 1:20,
  model = stm_out, method = "difference",
  cov.value1 = "Elected", cov.value2 = "Appointed"
)

## inspect word prevalence for topic
plot(
  stm_out, type = "perspectives", topics = 12
)


#####
test <- actual_merged_data  %>%
  mutate(year = lubridate::year(date)) %>%
  select(speeches, elected, year) %>%
  unite(elec_year, elected, year, remove = FALSE)

test_clean <- test %>%
  unnest_tokens(word, speeches) %>%
  anti_join(stop_words) %>%
  filter(
    str_detect(word, "[[A-Za-z]]"),
    str_count(word) >= 4,
    !str_detect(word, "india|govern|question|house")
  ) %>%
  count(elec_year, word) %>%
  mutate(word = str_remove_all(word, "[^A-Za-z]"))

test_sparse <- test_clean %>%
  cast_sparse(elec_year, word, n)

metadata <- test %>%
  select(elec_year, year, elected) %>%
  unique()

topic_model <- stm(
  test_sparse,
  K = 20,
  init.type = "Spectral",
  verbose = TRUE
)

effects <- estimateEffect(1:20 ~ elected + as.factor(year), topic_model, metadata)

summary(effects)

library(tidyverse)
library(tidytext)
library(stm)
#> stm v1.3.5 successfully loaded. See ?stm for help.
#>  Papers, resources, and other materials at structuraltopicmodel.com
library(janeaustenr)

books <- austen_books() %>%
  group_by(book) %>%
  mutate(chapter = cumsum(str_detect(text, regex("^chapter ", ignore_case = TRUE)))) %>%
  ungroup() %>%
  filter(chapter > 0) %>%
  unite(document, book, chapter, remove = FALSE)

austen <- books %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(document, word)

austen_sparse <- books %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(document, word) i%>%
  cast_sparse(document, word, n)
#> Joining, by = "word"

topic_model <- stm(
  austen_sparse,
  K = 6,
  init.type = "Spectral",
  verbose = FALSE
)
