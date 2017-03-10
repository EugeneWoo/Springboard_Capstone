Proposal for Dish-Driven Restaurant Recommendations
---------------------

To improve the ability of Yelp's search engine to suggest relevant restaurants based on a user's favourite dish. Currently, the results for a dish query favour highly-rated Chinese restaurants whose reviews might contain the individual keyword (e.g. 'noodles') but do not match the dish (e.g. 'ee-fu noodles'). Yelp publishes an updated academic dataset of business listings, anonymous user information, images and review texts for the *Yelp Dataset Challenge* - this is the data source for my project.

Please see the full report published on Rpubs: http://rpubs.com/eugenewoo/yelp_sbcapstone

Installation
--------------------

#### Download Data

* Download the JSON files from Yelp into your working directory
    * You can find the data [here](https://www.yelp.com/dataset_challenge). 
    * You will have to register with Yelp before downloading.
    * For this project, you will only need to analyse the Business and Review files.
* Read the downloaded JSON files into R
    * Run `stream_in` from the 'jsonlite' package
    * Highly recommend to re-save in .Rds format using `saveRDS`; reading .Rds format using `readRDS` is significantly faster than reading JSON format and will make future sessions more efficient.

#### Package Requirements
 
* Install the following packages
    * dplyr
    * tidyr
    * ggplot2
    * jsonlite
    * stringr 
    * qdap 
    * scales
    * tm
    * SnowballC, followed by the statement `update.packages("tm",  checkBuilt = TRUE)`
  

File Descriptions
---------------------
* README.MD

* CODE
    * **Yelp.R** - Main R code for exploration, cleaning and text mining
    * **Sentiment_scoring.R** - Supplementary R code for sentiment analysis of restaurant reviews (\*future work\*)
    * **server.R** - R code for Shiny app backend to lookup restaurant names with the user inputs from **ui.R**
    * **ui.R** - R code for the Shiny app user interface that defines user inputs and page layout

* REPORTS
    * **Mysteries of the Yelp Orient - Project Report.pdf** - Full narrative containing analysis, findings and code snippets 
    * **Mysteries of the Yelp Orient - Presentation.pdf** - Keynote deck summarising project 
