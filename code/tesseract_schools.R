library(tesseract)
library(tidyverse)
library(pdftools)
library(furrr)
library(magick)
library(foreach)
library(parallel)
library(doParallel)

get_year <- function(file) {
  file %>%
    str_extract("(?>_).*(?=.pdf)") %>%
    str_remove("_") %>%
    return()
}

clean_img <- function(path) {
  path %>%
    image_read() %>%
    image_deskew() %>%
    ## image_chop("0x600") %>%
    ## image_crop("3238x3800") %>%
    ## image_resize("2000x") %>%
    image_convert(type = "Grayscale") %>%
    image_trim() %>%
    ## image_contrast() %>%
    ## image_median(radius = 10) %>%
    ## image_contrast(sharpen = 3) %>%
    ## image_reducenoise(radius = 2) %>%
    ## image_quantize() %>%
    ## image_fuzzycmeans(smoothing = 500) %>%
    return()
}


clean_text <- function(string) {
  string %>%
    str_remove_all(regex(".*RECOGNI(S|Z)ED.*")) %>%
    str_remove_all(".*OLS.*") %>%
    str_remove_all("(?<=[A-Z]) (?=[A-Z]{2,})") %>%
    str_remove_all("(?<=[A-Z]\\b).*(C|c)on.*") %>%
    ## remove everything up to first district
    str_remove(regex("^.*?(?=[A-Z\\b]{3,})", dotall = TRUE)) %>%
    ## remove everything after disctrict name on line
    str_remove_all("(?<=[A-Z]{2}[^\\w\\s]).*") %>%
    ## remove everything before disctrict name on line
    str_remove_all("(S|s)choo.*") %>%
    str_remove_all("(H|h)igh.*") %>%
    ## remove academny and everything after
    str_remove_all("(A|a)cademy.*") %>%
    ## remove institute and everything after
    str_remove_all("[A-Za-z]\\.") %>%
    str_remove_all("(I|i)nstitute.*|(?=\\s|\\W).*(titut|tion|(I|i)nsti).*") %>%
    str_remove_all("[^0-9A-Za-z\n+\\s]") %>%
    str_remove_all("\\=|\\+") %>%
    str_remove_all("(?<=[A-Z])\\b(?=[A-Z])") %>%
    str_remove_all("\\b\\w{1,2}\\b") %>%
    str_remove_all(".*Authorised.*") %>%
    str_remove_all(".*eography.*") %>%
    str_remove_all(".*ygiene.*") %>%
    str_remove_all(".*echanics.*") %>%
    str_remove_all(".*(P|p)rov.*") %>%
    str_replace_all("\n +\n", "\n\n") %>%
    str_replace_all("\\s+\n", "\n") %>%
    str_replace_all("\n\\s+", "\n") %>%
    str_replace_all("\n+", "\n") %>%
    str_remove_all(regex("^.$", multiline = FALSE)) %>%
    str_trim() %>%
    return()
}

get_dist_tbl <- function(tess_out, date) {
  district_tbl <- tibble()
  for (i in 1:length(tess_out)) {

    ## clean text
    clean <- clean_text(tess_out[[i]])

    ## split up into districts
    district <- clean %>%
      str_extract_all(
        regex(
          "([A-Z]+\n){2}.*?(?=([A-Z]+\n){2}|$)",
          dotall = TRUE
        )
      )

    for (j in 1:length(district[[1]])) {
      if (
        length(district[[1]]) != 0 &&
          str_count(str_extract(clean, "[[A-Z]+\n]+"), "\n") == 2
      ) {
        district_name <- district[[1]][j] %>%
          str_extract("^[A-Z]+\n") %>%
          str_squish()

        sub_district <- district[[1]][j] %>%
          str_remove("^[A-Z]+\n") %>%
          str_extract_all(
            regex(
              "([A-Z]+\n).*?(?=([A-Z]{5,}\n)|$)",
              dotall = TRUE
            )
          )

        for (k in 1:length(sub_district[[1]])) {
          subdist_name <- sub_district[[1]][k] %>%
            str_extract("^[A-Z]+\n") %>%
            str_trim()

          schools_num <- sub_district[[1]][k] %>%
            str_remove("^[A-Z]+\n") %>%
            str_count("\n")

          district_tbl <- bind_rows(
            district_tbl,
            tibble(
              year = date,
              page = i,
              district_name = district_name,
              subdist_name = subdist_name,
              schools_num = schools_num,
            )
          )
        }
      } else {
        message(paste("Page", i, "Problem Detected, Skipping..."))
        district_tbl <- bind_rows(
          district_tbl,
          tibble(
            year = date,
            page = i,
            district_name = NA,
            subdist_name = NA,
            schools_num = NA,
          )
        )
      }
    }
  }
  return(district_tbl)
}



## get files
path <- "../data/raw/schools"
files <- list.files(path, full.names = TRUE)
## file <- files[19]
eng <- tesseract(language = "eng", options = list(tessedit_pageseg_mode = 1))

main <- function(file, engine = eng) {
  pngfile <- pdftools::pdf_convert(file, dpi = 500)
  test <- pdf_ocr_data(file)
  n.cores <- parallel::detectCores() - 1
  my.cluster <- parallel::makeCluster(
    n.cores,
    type = "PSOCK"
  )
  registerDoParallel()
  out <- foreach(i = 1:length(pngfile), .combine = "c") %dopar% {
    ocr(clean_img(pngfile[i]), engine = eng)
  }
  parallel::stopCluster(cl = my.cluster)
  get_dist_tbl(out, date = get_year(file)) %>%
    return()
}

output <- map_df(files, main)

write_csv(output, "../data/clean/schools_panel.csv")
