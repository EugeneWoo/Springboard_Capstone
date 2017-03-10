Proposal for Dish-Driven Restaurant Recommendations
---------------------

To improve the ability of Yelp search engine to surface restaurant suggestions based on the user's favourite dish. Currently the results for a dish query favour highly-rated Chinese restaurants whose reviews contain the individual keyword (e.g. 'noodles') but do not match the dish (e.g. 'ee-fu noodles'). The data source was Yelp's website which shares the company's academic dataset of business listings, anonymous user information, images and review texts for the *Yelp Dataset Challenge*.

Please see the full report published on Rpubs: http://rpubs.com/eugenewoo/yelp_sbcapstone

Installation
--------------------

#### Download Data

* Download the JSON files from Yelp into your working directory.  
    * You can find the data [here](https://www.yelp.com/dataset_challenge)
    * You will have to register with Yelp before downloading
    * For this project, you will only use the Business and Review datasets
* Read the JSON files you downloaded.
    * In R, please run `stream_in` from the 'jsonlite' package
    * Highly recommended to save in .Rds format using `saveRDS`; subsequent reading of .Rds format using `readRDS` is faster than reading JSON format

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
    * SnowballC (followed by `update.packages("tm",  checkBuilt = TRUE)`)
  

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
