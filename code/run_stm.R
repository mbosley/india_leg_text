###############################################################################
## TITLE : Run Structural Topic Model
## PROJECT : India Legislative Text
## NAME : Mitchell Bosley
## DATE : 2021-02-23
###############################################################################

#### FUNCTIONS ####

#' @title Get Document Feature Matrix
#' @description Builds document feature matrix using quanteda package.
#'
#' @param docs Table of documents.
#' @param docName Character string indicating the variable in 'docs'
#' that denotes the text.
#' @param indexName Character string indicating the variable in 'docs'
#' that denotes the index value.
#' @param stem Boolean value indicating whether or not to stem terms.
#' @param ngrams Integer value indicating the size of the ngram
#' to use to build the dfm.
#' @param min_termfreq Numeric values indicating the threshold of
#' percentage of document membership at which to remove terms
#' from the data-term matrix.
#' @param max_docfreq
#' @param tfidf  Boolean value indicating whether to weight the
#' document term matrix by the frequency of word counts.
#' @param min_nchar Minimum number of characters allowed in term.
#'
#' @return Document term matrix.
get_dfm <- function(docs, docName, indexName, stem=T, ngrams=1,
                    min_termfreq=0.0001, max_termfreq=1,
                    tfidf=F, removeStopWords=T, min_nchar=4) {

    dfm <- docs %>%
        quanteda::corpus(docid_field=indexName, text_field=docName) %>%
        quanteda::dfm(
                    tolower=T, remove_numbers=T, remove_url=T,
                    remove_punct=T, remove_hyphens=T,
                    stem=stem, ngrams=ngrams) %>%
        {if (removeStopWords)
           quanteda::dfm_remove(
                       ., quanteda::stopwords(source="stopwords-iso")
                     ) else .} %>%
        quanteda::dfm_select(min_nchar=min_nchar) %>%
        quanteda::dfm_trim(min_termfreq=min_termfreq, max_termfreq=max_termfreq,
                           termfreq_type="prop") %>%
        {if (tfidf) quanteda::dfm_tfidf(.) else .}

    return(dfm)
}

# perform structural topic model on selected data
stm_analysis <- function(form, K=5, data, verbose=F, dfm=NULL) {
    # using only the stm environment
    require(stm)

    if (is.null(dfm)) {
        processed_data <- textProcessor(documents=data$text, metadata=data, verbose=verbose)
        prepared_data <- prepDocuments(documents=processed_data$documents,
                                       vocab=processed_data$vocab,
                                       meta=processed_data$meta, verbose=verbose)
        stm_out <- stm(documents=prepared_data$documents, vocab=prepared_data$vocab, K=K,
                       data=prepared_data$meta, verbose=verbose)
        est_out <- estimateEffect(formula=formula(form), stmobj=stm_out,
                                  metadata=prepared_data$meta)
        out <- list(stm_out=stm_out, est_out=est_out)
    } else {
        require(quanteda)
        stm_dfm <- quanteda::convert(dfm, to="stm")
        stm_out <- stm(documents=stm_dfm$documents, vocab=stm_dfm$vocab, K=K,
                       data=stm_dfm$meta, verbose=verbose)
        est_out <- estimateEffect(formula=formula(form), stmobj=stm_out,
                                  metadata=stm_dfm$meta)
        out <- list(stm_out=stm_out, est_out=est_out, prepared_data=prepared_data)
    }

    return(out)
}
