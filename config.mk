# specify which collections to download
COLLECTIONS = "clad|ilcd|cosd"

# specify number of threads to use locally for webscraping
NUM_THREADS = 10

# filename generation
PDFS := $(addprefix data/raw/,$(notdir $(shell cat data/raw/links.txt | grep -E $(COLLECTIONS) | head)))
CSVS := $(subst .pdf,.csv,$(PDFS))
