library(tidyverse)
library(quanteda)
library(argparser)


## arg parser


speech_days <- read_csv("data/clean/combined_speeches.csv")
merged_speech_data <- read_csv("data/clean/merged_speech_data.csv")
clean_speech_data <- read_csv("data/clean/clean_speech_data.csv")

## clean_speech_data %>%
speech_days %>%
  group_by(collection) %>%
  count()

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

## docvars(corpus) <- speech_days_clean %>%
##   select(date, collection)

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
