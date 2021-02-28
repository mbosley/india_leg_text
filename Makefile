include config.mk

## build_dir : Build out directory structure.
.PHONY : build_dir
build_dir :
	mkdir -p data/{raw,clean}

## get_links : Get the complete set of pdf links from website.
.PHONY : get_links
get_links : data/raw/links.txt
data/raw/links.txt : code/scrape_links.jl
	julia -t $(NUM_THREADS) $^

## download_data : Using the links, download the pdfs
.PHONY : download_pdfs
download_pdfs : $(PDFS)
data/raw/%.pdf : code/download_data.sh data/raw/links.txt
	$(GET_DATA)

## ocr_data : Use OCR to process the pdfs, saving as csv.
.PHONY : ocr_data
ocr_data : $(CSVS)
data/raw/%.csv : code/ocr_pdfs.R data/raw/%.pdf
	$(OCR)

## combine_data : Combines all CSVs into a single CSV.
## This file gets uploaded to the google drive.
.PHONY : combine_data
combine_data : data/clean/speeches_all.csv
data/clean/speeches_all.csv : $(CSVS)
	awk 'NR==1; FNR==1{next} 1' $^ > $@

## download_google : Downloads data from google drive
.PHONY : download_google
download_google : data/raw/speeches_google.csv
data/raw/speeches_google.csv :
	gdown --id 1K-zod1ZnNf0eXi68x8vaaoVL34SAQ1KZ --output $@

## clean_data : Parses the data into individual speeches, topics, etc.
.PHONY : clean_data
clean_data : data/clean/merged_speech_data.csv
data/clean/clean_speech_data.csv : code/parse_speech_data.R data/raw/speeches_google.csv
	Rscript $<
data/clean/merged_speech_data.csv : code/merge_member_data.R data/clean/clean_speech_data.csv
	Rscript $<

## run_stm : Runs structural topic model
.PHONY : run_stm
run_stm : code/run_stm.R data/clean/merged_speech_data.csv
	Rscript $<

## clean : Remove all data files generated from makefile.
.PHONY : clean
clean :
	rm -f data/raw/links.txt

## help : Get help for makefile action in console.
help : Makefile
	@sed -n 's/^##//p' $<

## print : Print value of variable in console.
print-%  : ; @echo $* = $($*)
