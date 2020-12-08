NUM_THREADS = 10
CALD_PDFS := $(addprefix data/raw/cald/,$(notdir $(shell cat data/raw/links.txt | grep "cald")))
CALD_CSVS := $(subst .pdf,.csv,$(CALD_PDFS))
