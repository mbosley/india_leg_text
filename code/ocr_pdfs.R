library(argparser)
library(tesseract)
library(tidyverse)
library(pdftools)

## functions
get_date_from_pdf_name <- function(str) {
  str %>%
    str_remove(".pdf") %>%
    str_remove(".*_") %>%
    as.Date(format = "%d-%m-%Y") %>%
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
    pdf_in = "data/raw/test_pdf.pdf"
  )
} else {
  args <- arg_parser("OCR") %>%
    add_argument(
      "pdf_in",
      help = "Path to PDF",
      type = "character"
    ) %>% add_argument(
      "csv_out",
      help = "Path to CSV outfile",
      type = "character"
    ) %>%
    parse_args()
}

## run ocr
#page_num <- pdf_pagesize(args$pdf_in) %>% nrow()
#base_file <- args$pdf_in %>%
#  basename() %>%
#  str_remove(".pdf")
#temp_names <- paste0(tempdir(), "/", base_file, "-", 1:page_num, ".png")

#pngfiles <- pdftools::pdf_convert(args$pdf_in, dpi = 500, filenames = temp_names)
#ocr_out <- ocr(pngfiles, engine = tesseract("eng"))
ocr_out <- pdf_ocr_text(args$pdf_in)

## remove garbage pngs
#unlink(pngfiles)

## convert to table, then save to disk
tibble(
  collection = get_collection_from_pdf_name(args$pdf_in),
  pdf_filename = fs::path_file(args$pdf_in),
  date = get_date_from_pdf_name(args$pdf_in),
  body = ocr_out
) %>%
  write_csv(args$csv_out)
