NUM_THREADS = 10

## build_dir
.PHONY : build_dir
build_dir :
	mkdir -p data/{raw,clean}

## get_links
.PHONY : get_links
get_links : data/raw/links.txt
data/raw/links.txt : code/scrape_links.jl
	julia -t $NUM-THREADS $^

## download_data
.PHONY : download_data
download_data : data/raw/debates
	curl -l "https://eparlib.nic.in/bitstream/123456789/760354/1/clad_03_23-07-1923.pdf"

## clean
.PHONY : clean
clean :
	rm -f data/raw/links.txt
