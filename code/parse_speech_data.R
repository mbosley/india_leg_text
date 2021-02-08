###############################################################################
## TITLE : Parsing OCR'd Data
## PROJECT : India Leg Text
## NAME : Mitchell Bosley
## DATE : 2021-02-07
###############################################################################

##### NOTES #####

## MB: processing steps:
## 1. use page structure to 'label' what's going on in each page DONE
## 2. use this information to pull the types of pages we want DONE
## 3. concatenate the extracted subtype DONE
## 4. parse speakers and topics TODO

##### FUNCTIONS #####

get_page_head <- function(speeches_all) {
  #' Grabs first lines from page body for easier analysis
  speeches_all %>%
    mutate(
      page_head = str_extract(body, "^(.*?\\n){20}"), ## grabs first 20 lines
      page_head = str_remove_all(page_head, "\\d") ## removes digits
    ) %>%
    return()
}

get_debate_pages <- function(speeches_sub, debug = FALSE) {
  #' Takes a subset of `speeches_all` for a single day and strips
  #' away all pages except for those thatcontain debates.

  ## get collection id
  collection_id <- speeches_sub[["collection"]][1]
  if (collection_id == "clad") {
    speech_keywords <- "LEGISLATIVE"
  } else if (collection_id == "cosd") {
    speech_keywords <- "COUNCIL"
  } else if (collection_id == "ilcd") {
    speech_keywords <- c(
      "QUESTIONS",
      "ANSWERS",
      "QUESTIONS AND ANSWERS",
      "PROCEEDINGS OF"
    )
  }

  ## remove first page
  speeches_sub <- speeches_sub[-1, ]

  ## gets index value where CONTENTS starts
  contents_ind <- speeches_sub %>%
    pull(body) %>%
    fuzzy_match_keywords("CONTENTS")

  ## if CONTENTS exists, deletes up to that point
  if (!is.na(contents_ind)) {
    speeches_sub <- speeches_sub[-(1:contents_ind), ]
  }

  ## gets index value where speeches starts
  first_speech_ind <- speeches_sub %>%
    pull(body) %>%
    fuzzy_match_keywords(speech_keywords)

  ## gets index value where INDEX starts
  first_index_ind <- speeches_sub %>%
    pull(body) %>%
    fuzzy_match_keywords("INDEX TO ")

  if (debug) {
    print(speeches_sub)
    cat("contents_index:", contents_ind, "\n")
    cat("speech_index:", first_speech_ind, "\n")
    cat("index_index:", first_index_ind, "\n")

    if (is.na(first_speech_ind)) {
      browser()
    }
  }


  ## If there is an INDEX, pulls pages between start of
  ## LEGISLATIVE and start of INDEX, otherwise pulls everything
  ## after the start of LEGISLATIVE
  if (is.na(first_index_ind)) {
    return(speeches_sub[(first_speech_ind):nrow(speeches_sub), ])
  } else {
    return(speeches_sub[(first_speech_ind):(first_index_ind - 1), ])
  }

}

fuzzy_match_keywords <- function(body_vec, keywords_vec) {
  #' tries fuzzy matching across a vector of keywords
  fuzzy_ind_vec <- unlist(map(keywords_vec, function (keyword) agrep(keyword, body_vec)))
  first_ind <- ifelse(length(fuzzy_ind_vec) != 0, min(fuzzy_ind_vec), NA)

  return(first_ind[1])

}

##### IMPLEMENTATION #####

library(tidyverse)

## 1. Get relevant pages, and concatenate by collection day

## load data (download from google drive to relevant folder;
## use the Makefile if you want.)
speeches_all <- read_csv("../data/raw/speeches_google.csv")

## split data by date, then apply get_debate_pages()
## function to get only the debate pages
no_cores <- future::availableCores() - 1
future::plan(multicore, workers = no_cores)

debate_speeches <- speeches_all %>%
  split(.$pdf_filename) %>%
  furrr::future_map_dfr(get_debate_pages, .progress = TRUE)

## this code snippet efficiently concatenates speeches by group
debate_speeches_collapsed <- debate_speeches %>%
  group_by(collection, date, pdf_filename) %>%
  summarize(body = paste(body, collapse = ''))

## 2. Parse concatenated data
## THIS IS WHAT I NEED TO DO NEXT
## Looks like I need to trim the title text off each page.
## Then, for CLAD collection, the important signifiers are:
##
## 1): Topic in upper case followed by colon (e.g. "ELECTION OF DEPUTY PRESIDENT")
## with two new lines (\n\n) before and after signifies new topic.
##
## 2): Name in normal case follwed by colon (e.g. Mr. Sachchidananda Sinha:)
## signifies new speaker.
