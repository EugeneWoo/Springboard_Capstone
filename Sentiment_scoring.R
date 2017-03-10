## Load table containing reviews
aznv_ch <- readRDS("aznv_ch.Rds")
chreviews <- aznv_ch$text

## Sentiment lexicon from Bing Liu (cs.uic.edu/~liub/FBS/sentiment-analysis.html)
pos_words <- scan("positive-words.txt", what='character', comment.char=';')
neg_words <- scan("negative-words.txt", what='character', comment.char=';')

## Sentiment analysis function
score.sentiment <- function(text_vector, pos.words, neg.words, .progress='none')
{    
  require(plyr)
  require(stringr)
  
  scores <- ldply(text_vector, function(text_vector, pos.words, neg.words) {
    
    # clean up text with regex
    text_vector <- gsub('[[:punct:]]', '', text_vector)
    text_vector <- gsub('[[:cntrl:]]', '', text_vector)
    text_vector <- gsub('\\d+', '', text_vector)
    text_vector <- tolower(text_vector)
    
    # split into words using 'stringr' package
    word.list <- str_split(text_vector, '\\s+')
    words <- unlist(word.list)
    
    # compare our words to the dictionaries of positive & negative terms
    pos.matches <- match(words, pos.words)
    neg.matches <- match(words, neg.words)
    
    # match() returns the position of the matched term or NA
    # we just want a TRUE/FALSE:
    pos_matches <- !is.na(pos.matches)
    neg_matches <- !is.na(neg.matches)
    score <- sum(pos_matches) - sum(neg_matches)
    
  }, pos.words, neg.words, .progress=.progress)
  
  scores_final <- data.frame(sentiment_score = scores, text = text_vector)
  return(scores_final)
}

## Score sentiment for all Chinese restaurants reviews from Nevada and Arizona
ch_sentiment <- score.sentiment(chreviews, pos_words, neg_words)
ch_starsentiment <- cbind(aznv_ch[, c(4,6)], ch_sentiment[,1])
colnames(ch_starsentiment) <- c("stars", "text", "sentiment_score")

## Compare distribution of ratings and review sentiment; ratings are dominated by 4 and 5 stars whereas sentiment is normally distributed.
hist(scale(ch_starsentiment$sentiment_score), breaks = 100, main = "Sentiment Distribution All Chinese Reviews", xlab = "Scaled Sentiment Score (0 = Neutral)")
hist(aznv_ch$stars.x, main = "Ratings Distribution for All Chinese Reviews", xlab = "Restaurant Ratings")
  
## Normality persists for 1 and 5 star ratings - sentiment are not predictive of ratings
extreme_stars <- filter(ch_starsentiment, stars == 1 | stars == 5)
hist(scale(extreme_stars$sentiment_score), breaks = 100, main = "Sentiment Distribution (1 or 5 stars)", xlab = "Scaled Sentiment Score (0 = Neutral)")
```
