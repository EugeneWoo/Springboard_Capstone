#### Section 1 - Load JSON Datasets and save as .Rds #######################################

## Load packages            
pkg <- c("dplyr", "tidyr", "ggplot2", "jsonlite", "stringr", "qdap", "scales", "tm")
install.packages(pkg, dependencies = FALSE)
sapply(pkg, require, character.only = TRUE)

## Set working directory with the path string in brackets
setwd(...)

## Load JSON datasets using jsonlite::stream_in function
#biz_json <- stream_in(file("yelp_academic_dataset_business.json"))
#review_json <- stream_in(file("yelp_academic_dataset_review.json"))
#user_json <- stream_in(file("yelp_academic_dataset_user.json"))

## Save as .Rds for faster loading going forward
#saveRDS(biz_json, "biz.Rds")
#saveRDS(review_rds, "review.Rds")
#saveRDS(review_rds, "user.Rds")

## Load .Rds files as data frames and inspect the structure
biz <- readRDS("biz.Rds")
biz_df <- as.data.frame(biz)
str(biz_df, max.level = 1)
summary(biz_df)

review <- readRDS("review.Rds")
review_df <- as.data.frame(review)
str(review_df, max.level = 1)
summary(review_df)


#### Section 2 - Explore Datasets ##################################################

## Do we have enough reviews to analyse?
# Arranging into two columns comprising date and cumulative review count
ts_reviews <- review_df %>% 
  select(date, review_id) %>% 
  group_by(date) %>% 
  summarise_all(funs("reviews" = n())) %>% 
  mutate(dates = as.Date(date), cumulative = cumsum(reviews)) %>% 
  arrange(dates)

# Plot time series chart of review count - we have large sample size N = 2,225,213
ggplot(ts_reviews, aes(x = dates, y = cumulative, col = "red")) + 
  geom_line(size = 1) +
  scale_y_continuous(labels = comma) +
  labs(x = "Year of Review", y = "Cumulative Review Count") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  theme(legend.position = "none", axis.text.x = element_text(size = 8, angle = 45), axis.text.y = element_text(size = 8))

## Scrub Inactive Users
# Summary statistics - some users posted only 1 review in 10 years!
ratings_stats <- review_df %>% 
  select(user_id, stars) %>%
  group_by(user_id) %>% 
  summarise_all(funs("count" = n(), "mean" = mean, "median" = median)) %>% 
  arrange(count) %>% 
  ungroup()

head(ratings_stats)

# Plot to determine proportion of users at each review frequency
inactive_ratio <- function(criteria){
  ratio <- rep(0, as.numeric(criteria))
  for (i in 1:as.numeric(criteria)){
    ratio[i] <- nrow(filter(ratings_stats, count <= i)) / nrow(ratings_stats)
  }
  plot(ratio, type = "b", xlim = c(1,i), xlab = "Frequency of Reviews", ylab = "Ratio (vs. Total Reviews)", col = "blue")
}

inactive_ratio(10)

## Users posting 1 to 2 reviews make up 70% of total - we can only remove users with single reviews
few_lazy_raters <- ratings_stats %>% 
  filter(count == 1)

# Remove inactive users from the Review data
review_clean_df <- review_df[!(review_df$user_id %in% few_lazy_raters$user_id),]
intersect(review_clean_df$user_id, few_lazy_raters$user_id) # No overlap
round(nrow(review_clean_df) / nrow(review_df), 2) # We removed 13% of observations

## Merge the Reviews and Businesses datasets and remove extraneous columns
review_biz <- merge(review_clean_df, biz_df, by = "business_id")
rev_biz_tidy <- review_biz %>% 
                  select(-starts_with("hour"), -starts_with("attribute"), -contains("votes"),-contains("type"))
# Save as .Rds for faster loading
saveRDS(rev_biz_tidy, "rev_biz_tidy.Rds")

## Chinese reviews were 15% of top 5 restaurant categories - sufficient sample size!
cat_count <- rev_biz_tidy %>% 
            group_by(as.character(categories)) %>% 
            summarise(Count = n()) %>% 
            arrange(desc(Count))

head(cat_count[, 1:2])

## Sanity check - 'restaurant' should not be grouped with 'bar' and 'nightlife'
genre_count <- rev_biz_tidy %>% 
          select(state, categories) %>% 
          filter(str_detect(categories, "Restaurant")) %>% 
          unnest(categories) %>% 
          group_by(state) %>% 
          count(categories) %>% 
          arrange(desc(n))

genre_count[1:10,]

## Remove non-essential categories AND filtering only 90th percentile
state_rest_count <- genre_count %>% 
  group_by(state) %>% 
  filter(categories != "Restaurants" || categories != "Nightlife" || categories != "Bars") %>% 
  filter(n > quantile(n, 0.9)) 

## Plot Share of Reviews by State (90th percentile)
state_table <- state_rest_count %>% 
  select(state, n) %>% 
  group_by(state) %>% 
  summarise_all(funs("count" = sum(n))) %>% 
  arrange(desc(count)) %>% 
  mutate(proportion = round(count / sum(count), 2))

plot_state_table <- state_table %>% 
  ggplot(aes(x = reorder(state, -proportion), y = proportion, fill = state)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = comma) + # Requires 'scales' package
  ggtitle("Share of Reviews by State (Top 10% only)") +
  labs(x = "State", y = "Share of Reviews") +
  theme(legend.position = "none", axis.text.x = element_text(face = "bold", size = 8, angle = 45), axis.text.y = element_text(face = "bold", size = 8))

plot_state_table # Nevada and Arizona together contribute 83% of total reviews 


## Visualise cuisine review counts in Arizona and Nevada
plot_aznv_cuisine <- state_rest_count %>% 
  filter(state == "AZ" | state == "NV") %>%   
  ggplot(aes(x = reorder(categories, -n), y = n, fill = categories)) + 
  geom_bar(stat = "identity") +
  facet_grid(state~.) +
  # Require 'scales' package to add comma separators to Y-axis labels
  scale_y_continuous(labels = comma) + 
  ggtitle("Cuisine Review Count (Top 10% only)") +
  labs(x = "Cuisine", y = "Total Reviews (n)") +
  theme(legend.position = "none", axis.text.x = element_text(face = "bold", size = 7, angle = 90), 
        axis.text.y = element_text(face = "bold", size = 8))

plot_aznv_cuisine # Up to 30K Chinese reviews each in Nevada and Arizona


#### Section 3 - Create Corpus of Reviews ############################################

## Filtering Chinese reviews from Nevada and Arizona
aznv_ch <- rev_biz_tidy %>% 
  filter(state == "AZ" | state == "NV") %>% 
  filter(str_detect(categories, "Chinese"))
# Save as .Rds for quick loading by Shiny App
saveRDS(aznv_ch, "aznv_ch.Rds")

## Filtering only positive reviews and converting to matrix
aznv_ch_text <- aznv_ch[aznv_ch$stars.x >= 4,]$text
aznv_ch_matrix <- as.matrix(aznv_ch_text)
# Randomised sampling
random.rows <- sample(1:nrow(aznv_ch_matrix), 0.3 * nrow(aznv_ch_matrix), replace = FALSE)
aznv_ch_sample <- aznv_ch_matrix[random.rows,]

## Creating the corpus
aznv_ch_corpus <- VCorpus(VectorSource(aznv_ch_sample))
aznv_ch_corpus


#### Section 4 - Extract Popular Dishes from Review Texts ##############################################

## PREPROCESSING CORPUS
# Remove stopwords, capitalisation, punctuation, abbreviation and numbers
clean_corpus <- function(corpus){
  corpus <- tm_map(corpus,  content_transformer(function(x) iconv(x, to='UTF-8-MAC', sub='byte')),  mc.cores=1)
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, content_transformer(replace_abbreviation))
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, removeWords, c(stopwords("en"), "food"))
  corpus <- tm_map(corpus, stripWhitespace)
  return(corpus)
}

## Count single words or unigrams - too many garbage words to make sense of reviews
unigram_count <- function(cleaned_corpus) { 
                tdm <- TermDocumentMatrix(cleaned_corpus)
                tdm_matrix <- as.matrix(tdm)
                term_freq <- rowSums(tdm_matrix)
                term_freq <- sort(term_freq, decreasing = TRUE)
                barplot(term_freq[1:20], col = "turquoise", las = 2, main = "Plot of Top 20 Unigrams")
}

clean_aznv_ch <- clean_corpus(aznv_ch_corpus)
unigram_count(clean_aznv_ch)

## Expand stopword list in corpus cleaner
clean_corpus2 <- function(corpus){
  corpus <- tm_map(corpus, content_transformer(function(x) iconv(x, to = "UTF-8-MAC", sub = "byte")), mc.cores=1)
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, content_transformer(replace_abbreviation))
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, removeWords, c(stopwords("en"), "food", "good", "place", "great", "service", "time", "really", "restaurant", "always", "just", "get", "one", "will", "also", "ordered", "can", "try", "ive", "well", "eat", "little", "definitely", "vegas", "back", "amazing", "got", "dont"))
  corpus <- tm_map(corpus, stripWhitespace)
  return(corpus)
}

clean_aznv_ch2 <- clean_corpus2(aznv_ch_corpus)

## Create term document matrix for two-word (bigram) and three-word (trigram) phrases
install.packages("SnowballC")
library(SnowballC) #required by latest version of 'tm' package
library(tm)
update.packages("tm",  checkBuilt = TRUE) #updating 'tm' package

# Create bigram and trigram tokenizer functions
BigramTokenizer <- function(x) unlist(lapply(ngrams(words(x), 2), paste, "", collapse = " "), use.names = FALSE)
TrigramTokenizer <- function(x) unlist(lapply(ngrams(words(x), 3), paste, "", collapse = " "), use.names = FALSE)

## Create term document matrix (tdm) of bigrams and trigrams
bigram_ch_tdm <- TermDocumentMatrix(clean_aznv_ch2, control = list(tokenize = BigramTokenizer))
trigram_ch_tdm <- TermDocumentMatrix(clean_aznv_ch2, control = list(tokenize = TrigramTokenizer))

## Convert tdm into data frames of bigram and trigram counts
ngram_freq <- function(tdm){
  freq <- sort(rowSums(as.matrix(tdm)), decreasing=TRUE)
  freq_df <- data.frame(word=names(freq), freq=freq)
  return(freq_df)
}

bigram_ch_freq <- ngram_freq(bigram_ch_tdm)
trigram_ch_freq <- ngram_freq(trigram_ch_tdm)


# Plot frequencies of bigrams and trigrams - trigrams capture dish names the most accurately!
plot_bigram_ch <- bigram_ch_freq[1:20,] %>% 
                ggplot(aes(x = reorder(word, -freq), y = freq)) + 
                geom_bar(stat = "identity", fill = "green", col = "red") +
                scale_y_continuous(labels = comma) +
                ggtitle("Histogram of 20 Most Frequent Bigrams") +
                labs(x = "Words / Phrases", y = "Frequency") +
                theme(legend.position = "none", axis.text.x = element_text(face = "bold", size = 9, angle = 45), axis.text.y = element_text(size = 9))

plot_trigram_ch <- trigram_ch_freq[1:20,] %>% 
                    ggplot(aes(x = reorder(word, -freq), y = freq)) + 
                    geom_bar(stat = "identity", fill = "green", col = "red") +
                    scale_y_continuous(labels = comma) +
                    ggtitle("Histogram of 20 Most Frequent Trigrams") +
                    labs(x = "Words / Phrases", y = "Frequency") +
                    theme(legend.position = "none", axis.text.x = element_text(face = "bold", size = 8, angle = 45), axis.text.y = element_text(size = 9))s