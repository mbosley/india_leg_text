###############################################################################
## TITLE : Testing out daiR
## PROJECT : India Colonial Legislature
## NAME : Mitchell Bosley
## DATE : 2022-03-01
###############################################################################

library(tidyverse)
library(daiR)
library(googleCloudStorageR)

project_id <- daiR::get_project_id()


## create buckets
gcs_create_bucket("india-leg-bucket", project_id, location = "US")
gcs_list_buckets(project_id)

## set bucket
gcs_global_bucket("india-leg-bucket")

## upload file
setwd(tempdir())

## test it out
test2 <- dai_sync(
  "/Users/mitchellbosley/Desktop/clad_04_02_02-10-1931 (dragged).pdf",
  loc = "us"
  )

text <- text_from_dai_response(test2)
cat(text)

## it can do tables too
table_test <- dai_sync_tab(
  "~/Desktop/test_pic.png",
  loc = "us"
)

tables <- tables_from_dai_response(table_test)

tables[[1]] %>%
  as_tibble(.name_repair = "unique") %>%
  mutate(across(everything(), str_squish))
