###############################################################################
## TITLE : Merge Colonial India Member Data to Speech Dataset
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-19
###############################################################################

##### FUNCTIONS #####
fuzzy_join_clad <- function(year_val) {
  clean_speech_data %>%
    filter(
      institution == "clad",
      speaker != "the President",
      year == year_val
    ) %>%
    drop_na() %>%
    fuzzyjoin::stringdist_left_join(
                member_data_clean %>% filter(
                                        institution == "clad",
                                        year == year_val
                                      ),
                by = "speaker",
                max_dist = 5, distance_col = "distance"
              ) %>%
    return()
}

##### IMPLEMENTATION #####

library(tidyverse)

## load and clean data
speech_data <- read_csv("data/clean/clean_speech_data.csv")
member_data <- read_csv("data/raw/member_data.csv") %>%
  select(
    institution = Institution, year_position = Year_Position,
    year_nominated = Year_Nominated, speaker = Name,
    tenure = Tenure, elected = Elected, position = Position
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
output_tbl <- tibble()
for (year in 1921:1925) {
  print(paste("Doing: ", year))
  output_tbl <- bind_rows(output_tbl, fuzzy_join_clad(year))
}

## summarize and write to disk
clad_out <- output_tbl %>%
  group_by(speech_id) %>%
  filter(distance == min(distance)) %>%
  select(speech_id, institution = institution.x, date,
         pdf_filename, speaker = speaker.x,
         elected, position, tenure) %>%
  ungroup() %>%
  write_csv("data/clean/merged_speech_data.csv")



## inspect breakdown
clad_out %>%
  mutate(position = replace_na(position, "None")) %>%
  group_by(position, elected) %>%
  summarize(count = n()) %>%
  ggplot(aes(x = reorder(position, (count)),
             y = count, fill = as.factor(elected))) +
  geom_bar(stat = "identity") +
  coord_flip()
