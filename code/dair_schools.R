library(tidyverse)
library(daiR)
library(googleCloudStorageR)
library(tesseract)

path <- "../data/raw/schools/separated"

files <- list.files(path, full.names = TRUE)

test_file <- "~/Desktop/Schools_1910-1.pdf"
test_file2 <- "~/Desktop/Schools_1910-2.pdf"
test_file3 <- "~/Dropbox (University of Michigan)/Colonial Legislatures Project/British India Legislature - Winter 2022/Recognized Schools/Schools_1934.pdf"

project_id <- daiR::get_project_id()

out2 <- dai_sync(
  test_file3,
  loc = "us",
)

out_tab <- dai_sync_tab(
  ## files[1],
  test_file3,
  loc = "us",
)

dai_sync_tab()

text_out2 <- text_from_dai_response(out2)

text_out2 %>% cat()

tables_out <- tables_from_dai_response(out_tab)

tables_out %>% length()

eng <- tesseract(language = "eng", options = list(tessedit_pageseg_mode = 1))

tesseract_test <- ocr(test_file3, engine = eng)

tesseract_test[1]


## parsing
clean <- text_out2 %>%
  str_remove_all("AUTHORISED SCHOOLS.") %>%
  str_remove_all(".*RECOGNI(S|Z)ED.*") %>%
  str_remove_all("-Contd.*|-cont.*") %>%
  str_remove_all("\"") %>%
  str_remove_all("-") %>%
  str_remove_all(",") %>%
  str_remove_all(":\n") %>%
  str_remove_all(">\n") %>%
  str_remove_all("• ") %>%
  str_remove_all("\n.*teach.*") %>%
  str_remove_all(".*PART.*") %>%
  str_remove_all("[0-9]*") %>%
  str_remove_all(".*\\}") %>%
  str_remove_all("茶") %>%
  str_remove_all("\\*\\*\\*") %>%
  str_remove_all("\\)") %>%
  ## str_remove("^.*SITUATED.*$") %>%
  str_remove_all("OOLS") %>%
  str_remove_all("ALPHABETICAL LIST OF RECOGNI(S|Z)ED SCH.*") %>%
  str_remove_all("AND THE NAMES OF DISTRICTS IN WHICH") %>%
  str_remove_all("THEY ARE SITUATED") %>%
  str_remove_all("xo") %>%
  str_remove_all("\\*\n") %>%
  str_remove_all("\\.") %>%
  ## str_replace_all("\n{3,}", "\n\n") %>%
  str_replace_all("\n+", "\n")

clean %>%
  cat()

clean %>%
  str_extract_all(
    regex(
      "([A-Z]+\n){2}.*?(?=([A-Z]+\n){2})",
      dotall = TRUE,
      multiline = TRUE
    )
  )
