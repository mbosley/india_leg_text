###############################################################################
## TITLE : Run Structural Topic Model
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-23
###############################################################################

#### IMPLEMENTATION ####

library(tidyverse)

merged_data <- read_csv("data/clean/merged_speech_data.csv") %>%
  mutate(
    speech_id = 1:nrow(.),
    date = format(date, "%j")
  ) %>%
  slice(1:1000) %>%
  unique()

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
