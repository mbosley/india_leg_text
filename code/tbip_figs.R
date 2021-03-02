###############################################################################
## TITLE : Text-Based Ideal Points Figs
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-27
###############################################################################

library(tidyverse)
library(ggridges)
library(patchwork)

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
speech_nums <- speech_data %>%
  group_by(position) %>%
  summarize(speech_nums = n()) %>%
  pull(speech_nums)
speaker_position_data %>%
  group_by(position) %>%
  summarize(`Number of Speakers` = n()) %>%
  mutate(`Number of Speeches` = speech_nums) %>%
  gather(
    key = "att", value = "Number",
    "Number of Speakers", "Number of Speeches", -position
  ) %>%
  rename(`Member Type` = position) %>%
  ggplot(aes(x = Number,
             y = `Member Type`)) +
  geom_bar(width = .5, stat = "identity") +
  facet_wrap(vars(att), scales="free_x") +
  theme_bw() +
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
ridge_sep <- tbip_results %>%
  drop_na() %>%
  filter(position != "Unelected") %>%
  ggplot(
    aes(x = ideal_point,
        y = position)
  ) +
  geom_density_ridges(scale = 0.9) +
  theme_bw() +
  xlab("Ideal Point") +
  theme(
    axis.title.y = element_blank()
  ) +
  ggsave("figs/ridgesplot-seperate.pdf")

## ridges plot by elected or not
ridge_pooled <- tbip_results %>%
  mutate(elected = ifelse(elected == 1, "Elected", "Appointed")) %>%
  drop_na() %>%
  ggplot(
    aes(x = ideal_point,
        y = elected)
  ) +
  geom_density_ridges(scale = 0.9) +
  theme_bw() +
  xlab("Ideal Point") +
  theme(
    axis.title.y = element_blank(),
    axis.title.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.x = element_blank()
  ) +
  ggsave("figs/ridgesplot-pooled.pdf")

(ridge_pooled / ridge_sep) + ggsave("figs/ridges_combined.pdf")

## pooled distribution of ideal points
tbip_results %>%
  drop_na() %>%
  ggplot(aes(x = ideal_point,
             y = reorder(speaker, ideal_point))) +
  geom_vline(xintercept = 0, color = "gray30") +
  geom_point(size = 2) +
  theme_bw() +
  xlab("Ideal Point") +
  ylab("Members of Legislative Assembly") +
  facet_wrap(vars(position)) +
  theme_bw() +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  ggsave("figs/pointplot.pdf")
