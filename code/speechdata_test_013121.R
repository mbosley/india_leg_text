# clean current workspace
rm(list=ls(all=T))
# set options
options(stringsAsFactors = F)         # no automatic data transformation
options("scipen" = 100, "digits" = 4) # supress math annotation

library(tm)
library(topicmodels)
library(reshape2)
library(ggplot2)
library(wordcloud)
library(pals)

#load data
textdata <- read.csv("clad_02_30-09-1921.csv",encoding = "UTF-8")

textdata <- textdata[2:nrow(textdata),] # Remove first page

textdata$firstpage <- ifelse (grepl("LEGISLATIVE ASSEMBLY",textdata$body)==TRUE,1,0) # Identify first page after content

for(i in 2:nrow(textdata)){
  textdata$firstpage[i] <- ifelse(textdata$firstpage[i-1]==1,1,textdata$firstpage[i])
} # Mark all pages after first page to keep

textdata <- textdata[textdata$firstpage==1,] # Remove all Table of Contents Page

text_raw <- data.frame(collection=textdata$collection[1],date=textdata$date[1],pg_ID = 1,text = unlist(strsplit(textdata$body[1],"\n")))

for(i in 2:nrow(textdata)){
  collection <- textdata$collection[1]
  date <- textdata$date[1]
  pg_ID <- i
  text <-  unlist(strsplit(textdata$body[i],"\n"))
  text_raw_new <- data.frame(collection,date,pg_ID,text)
  text_raw <- rbind(text_raw,text_raw_new)
}
