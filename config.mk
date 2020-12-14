# specify which collections to download
COLLECTIONS = "clad|ilcd|cosd"

# specify number of threads to use locally for webscraping
NUM_THREADS = 10

# filename generation
PDFS := $(addprefix data/raw/,$(notdir $(shell cat data/raw/links.txt | grep -E $(COLLECTIONS) | head)))
CSVS := $(subst .pdf,.csv,$(PDFS))

# execution type; 'cluster' for cluster, 'local' for local
EXEC_TYPE = local

# slurm parameters
SLURM_ACCOUNT = shiraito1
SLURM_OUT = /home/%u/logs/%x-%j.log # x=job name, j=job id
SLURM_FLAGS = --ntasks 1 --cpus-per-task 1 --partition standard \
	--account $(SLURM_ACCOUNT) --output $(SLURM_OUT) \
	--mem 5g --time 06:00:00

GET_DATA_LOCAL =  sh $^ $* $@
GET_DATA_SLURM = sbatch $(SLURM_FLAGS) --wrap "$(GET_DATA_LOCAL)" --job-name dl-$@

OCR_LOCAL = Rscript $^ $@
OCR_SLURM = sbatch $(SLURM_FLAGS) --wrap "$(OCR_LOCAL)" --job-name ocr-$@

ifeq ($(EXEC_TYPE),cluster)
	GET_DATA = $(GET_DATA_SLURM)
	OCR = $(OCR_SLURM)
else
	GET_DATA = $(GET_DATA_LOCAL)
	OCR = $(OCR_LOCAL)
endif
