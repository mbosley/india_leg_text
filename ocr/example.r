library(stringr) # Clean text
library(tesseract) # Tesseract OCR
library(tm) # Corpus analysis

# Create PNG of each page in PDF. Output is corpus.

test <- ocr('./clad_02_28-09-1921.pdf', engine = tesseract("eng"))

# Delete PNG files

for(i in 1:length(test)){
  file.remove(paste0("clad_02_28-09-1921","_",i,".png"))
}

# Save each page of corpus as txt file
for(i in 1:length(test)){
  txt <- test[i]
  write_tsv(as.data.frame(txt),paste0("clad_02_28-09-1921","_",i,".txt"))
}
