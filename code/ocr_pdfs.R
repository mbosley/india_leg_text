library(argparser)
library(tesseract)
library(tidyverse)

## functions
get_date_from_pdf_name <- function(str) {
  str %>%
    str_remove(".pdf") %>%
    str_remove(".*_") %>%
    as.Date(format = "%d-%m-%y") %>%
    return()
}

get_collection_from_pdf_name <- function(str) {
  str %>%
    str_remove(".pdf") %>%
    str_remove("_.*") %>%
    str_remove(".*/") %>%
    return()
}

## load path to pdf
if (interactive()) {
  args <- list(
    pdf_in = "../data/raw/cald/cald_01_01-12-1947.pdf"
  )
} else {
  args <- arg_parser("OCR") %>%
    add_argument(
      "pdf_in",
      help = "Path to PDF",
      type = "character"
    ) %>%
    add_argument(
      "csv_out",
      help = "Path to CSV outfile",
      type = "character"
    ) %>%
    parse_args()
}

## run ocr
ocr_out <- ocr(args$pdf_in, engine = tesseract("eng"))

## convert to table, then save to disk
tibble(
  collection = get_collection_from_pdf_name(args$pdf_in),
  date = get_date_from_pdf_name(args$pdf_in),
  body = ocr_out
) %>%
  write_csv(args$csv_out)
