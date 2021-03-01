###############################################################################
## TITLE : Text-Based Ideal Points Figs
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-27
###############################################################################

library(tidyverse)
library(ggridges)

## load data
speech_data <- read_csv("data/clean/merged_speech_data.csv") %>%
  mutate(
    position = case_when(
      position %in% c("Non-Muhammadan Rural",
                      "Non-Muhammadan Rura") ~ "Non-Muslim",
      position %in% c("Non-Muhammadan Urban",
                      "Non-Muhammadan urban",
                      "Non-MuhammadanUrban") ~ "Non-Muslim",
      position == "Muhammadan Urban" ~ "Muslim",
      position %in% c("Muhammadan Rural",
                      "Muhammadan rural") ~ "Muslim",
      position == "Muhammadan" ~ "Muslim",
      position == "Non-Muhammadan" ~ "Non-Muslim",
      position == "Nominated Member" ~ "Unelected",
      position == "Landholders" ~ "Landholders",
      is.na(position) ~ "Other",
      TRUE ~ "Other"
    )
  )

speaker_position_data <- speech_data %>%
  select(speaker, position, elected) %>%
  unique()

tbip_results <- read_csv("data/clean/tbip_results.csv") %>%
  select(-X1) %>%
  mutate(speaker = str_remove(speaker, "\\s\\(.\\)")) %>%
  left_join(speaker_position_data, by = c("speaker", "elected"))

## DESCRIPTIVE PLOTS ##
speaker_position_data %>%
  group_by(position) %>%
  summarize(`Number of Speakers` = n()) %>%
  mutate(`Number of Speeches` = speech_nums) %>%
  gather(
    key = "att", value = "Number",
    "Number of Speakers", "Number of Speeches", -position
  ) %>%
  rename(Type = position) %>%
  ggplot(aes(x = Number,
             y = Type)) +
  geom_bar(width = .5, stat = "identity") +
  facet_wrap(vars(att), scales="free_x") +
  ggsave("figs/speech-speaker-prop.pdf")

## speech proportion
speech_data %>%
  group_by(position) %>%
  count() %>%
  ggplot(aes(x = "", y = n, fill = position)) +
  geom_bar(stat = "identity") +
  ggsave("figs/speech-proportion.pdf")

speaker_position_data%>%
  group_by(position) %>%
  count() %>%
  ggplot(aes(x = "", y = n, fill = position)) +

  geom_bar(stat = "identity")
## MODEL PLOTS ##

## boxplot pooled
tbip_results %>%
  mutate(elected = ifelse(elected == 0, "Unelected", "Elected")) %>%
  drop_na() %>%
  ggplot(aes(as.factor(elected), ideal_point)) +
  geom_boxplot() +
  ggsave("figs/boxplot-pooled.pdf")

## boxplot by position
tbip_results %>%
  drop_na() %>%
  ggplot(aes(position, ideal_point)) +
  geom_boxplot() +
  ggsave("figs/boxplot-separate.pdf")

## ridges plot by position
tbip_results %>%
  drop_na() %>%
  ggplot(
    aes(x = ideal_point,
        y = position)
  ) +
  geom_density_ridges(scale = 0.9) +
  ggsave("figs/ridgesplot-seperate.pdf")

## ridges plot by elected or not
tbip_results %>%
  drop_na() %>%
  ggplot(
    aes(x = ideal_point,
        y = as.factor(elected))
  ) +
  geom_density_ridges(scale = 0.9) +
  ggsave("figs/ridgesplot-pooled.pdf")

## pooled distribution of ideal points
tbip_results %>%
  drop_na() %>%
  ggplot(aes(x = ideal_point,
             y = reorder(speaker, ideal_point),
             color = position)) +
  geom_vline(xintercept = 0, color = "gray30") +
  geom_point(size = 2) +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  ) +
  ggsave("figs/pointplot.pdf")
