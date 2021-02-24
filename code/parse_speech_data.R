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
## 4. parse speakers DONE
## 5. parse topics TODO

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

parse_speeches <- function(debate_speeches_collapsed, regex_long,
                           regex_short, collection_str) {
  #' parses speeches.

  debate_speeches_collapsed %>%
    ## filter out the specifieed collection, then parse the speeches
    filter(collection == collection_str) %>%
    mutate(
      speeches = str_extract_all(
        body, regex(parsing_regex, multiline = TRUE)
      )
    ) %>%
    select(-body) %>%
    unnest_longer(speeches) %>%
    mutate(
      ## extract speaker from each speech
      ## an explanation of the regex:
      ## - (^.(1,60):) looks for the speaker name
      speaker = str_extract(speeches, regex_short),
      speeches = str_remove(speeches, regex_short)
    ) %>%
    return()
}

##### IMPLEMENTATION #####

library(tidyverse)

## 1. Get relevant pages, and concatenate by collection day

## load data (download from google drive to relevant folder;
## use the Makefile if you want.)
speeches_all <- read_csv("data/raw/speeches_google.csv")

## split data by date, then apply get_debate_pages()
## function to get only the debate pages
no_cores <- future::availableCores() - 1
future::plan("multicore", workers = no_cores)

debate_speeches <- speeches_all %>%
  split(.$pdf_filename) %>%
  furrr::future_map_dfr(get_debate_pages, .progress = TRUE)

## this code snippet efficiently concatenates speeches
## by group and does some other cleaning
debate_speeches_collapsed <- debate_speeches %>%
  # removes lines with less than 15 characters, but preserves empty lines
  mutate(
    body = str_remove_all(
      body, regex("^.{1,15}((\\n)|$)", multiline = TRUE)
    )
  ) %>%
  # cuts the first line from each page and imputes as page topic
  mutate(
    page_topic = str_extract(body, "\\A.*\\n+"),
    body = str_remove(body, "\\A.*\\n+")
  ) %>%
  group_by(collection, date, pdf_filename) %>% # groups by relevant variables
  summarize(body = paste(body, collapse = "")) # concatenates by grouped vars

## 2. Parse concatenated data

## split the clad debates into individual speeches
## an explanation of the regex:
## - (^.(1,60):) looks for the initial match of the speaker name
## - ([\\s\\S]+?) looks for all text and line breaks until the next speaker
## - (?=(\\n{2}^.{1,60}:)|\\Z) is a positive lookahead looks for a new
##   and ensures that the next speaker is preceded by
##   two new lines, or alternatively, the end of the string is reached.
## - (?!\\n{2}.+:.*\\n{2}) is a negative lookahead that ensures that
##   there is not a double line break after the identified next speaker
##   chunk, which indicates that it is not actually as speaker.
parsing_regex <- "(^.{1,60}:)([\\s\\S]+?)(?=(\\n{2}^.{1,60}:)|\\Z)(?!\\n{2}.+:.*\\n{2})"
clad_speeches <- parse_speeches(
  debate_speeches_collapsed,
  regex_long = parsing_regex,
  regex_short = "^.{1,60}(?=:)",
  collection_str = "clad"
)

## now do the same for cosd collection, which thankfully
## has the same structure as the clad collection

cosd_speeches <- parse_speeches(
  debate_speeches_collapsed,
  regex_long = parsing_regex,
  regex_short = "^.{1,60}(?=:)",
  collection_str = "cosd"
)
## now do the same for ilcd collection, which unfortunately
## is structured different from the clad and cosd collections,
## and as a result needs a different regex
##
## regex explanation:
## - (^.{1,60}:(—|-){1,2}) looks for the speaker
## - ([\\s\\S]+?) looks for the speech
## - (?=(\\n^.{1,60}:(—|-){1,2})|\\Z) looks for the next speaker
ilcd_regex <- "(^.{1,60}:(—|-){1,2})([\\s\\S]+?)(?=(\\n^.{1,60}:(—|-){1,2})|\\Z)"
ilcd_speeches <- parse_speeches(
  debate_speeches_collapsed,
  regex_long = ilcd_regex,
  regex_short = "^.{1,60}(?=:(—|-){1,2})",
  collection_str = "ilcd"
)

## write to disk in clean data folder
bind_rows(clad_speeches, cosd_speeches, ilcd_speeches) %>%
  write_csv("data/clean/clean_speech_data.csv")
