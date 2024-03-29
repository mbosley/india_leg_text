include config.mk

## build_dir : Build out directory structure.
.PHONY : build_dir
build_dir :
	mkdir -p data/{raw,clean}
	mkdir figs

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
download_google : data/raw/speeches_google.csv data/clean/tbip_results.csv
data/raw/speeches_google.csv :
	gdown --id 1K-zod1ZnNf0eXi68x8vaaoVL34SAQ1KZ --output $@
data/clean/tbip_results.csv :
	gdown --id 14USSbJ1rlU5XhEQJuDCa1ezB8gawwpdk --output $@

## clean_data : Parses the data into individual speeches, topics, etc.
.PHONY : clean_data
clean_data : data/clean/merged_speech_data.csv
data/clean/clean_speech_data.csv : code/parse_speech_data.R data/raw/speeches_google.csv
	Rscript $<
data/clean/merged_speech_data.csv : code/merge_member_data.R data/clean/clean_speech_data.csv
	Rscript $<

## get_dfm :
.PHONY : get_dfm
get_dfm : data/clean/dfm_speeches.rds data/clean/dfm_days.rds
data/clean/dfm.rds : code/get_dfm.R
	Rscript $^

## run_stm : Runs structural topic model
.PHONY : run_stm
run_stm : $(STM_OUT_DAYS) $(STM_OUT_SPEECHES)
data/clean/stm_out_days_%.rds : code/run_stm_days.R data/clean/dfm_.rds
	Rscript $^ --K $*
data/clean/stm_out_speeches_%.rds : code/run_stm_speeches.R data/clean/dfm.rds
	Rscript $^ --K $*

## get_figs : Gets figures
.PHONY :  get_figs
get_figs :
	Rscript descriptive_figs.R
	Rscript tbip_figs.R

## clean : Remove all data files generated from makefile.
.PHONY : clean
clean :
	rm -f data/raw/links.txt

## help : Get help for makefile action in console.
help : Makefile
	@sed -n 's/^##//p' $<

## print : Print value of variable in console.
print-%  : ; @echo $* = $($*)
