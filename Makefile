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
.PHONY : download_data
download_data : $(PDFS)
data/raw/%.pdf : code/download_data.sh data/raw/links.txt
	sh $^ $* $@

## ocr_data : Use OCR to process the pdfs, saving as csv.
.PHONY : ocr_data
ocr_data : $(CSVS)
data/raw/%.csv : code/ocr_pdfs.R data/raw/%.pdf
	Rscript $^ $@
	rm -f $(basename $@_*).png

## clean : Remove all data files generated from makefile.
.PHONY : clean
clean :
	rm -f data/raw/links.txt

## help : Get help for makefile action in console.
help : Makefile
	@sed -n 's/^##//p' $<

## print : Print value of variable in console.
print-%  : ; @echo $* = $($*)
