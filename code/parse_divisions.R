###############################################################################
## TITLE : Parse Divisions from Raw Speech Data
## PROJECT : India Leg Text
## NAME : Mitchell Bosley
## DATE : 2022-01-17
###############################################################################

library(tidyverse)
if (interactive()) {
  setwd("~/Desktop/projects/india_leg_text")
}
speeches_all <- read_csv("data/raw/speeches_all.csv")

## get example speech for dev

speeches_example <- speeches_all %>%
  filter(pdf_filename == "clad_03_18-07-1923.pdf") %>%
  filter(str_detect(body, "The Assembly divided"))

speeches_example$body %>% cat()
