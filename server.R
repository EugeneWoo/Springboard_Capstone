library(shiny)

shinyServer(function(input, output) {
   
  output$barplot <- renderPlot({
    library(dplyr)
    library(ggplot2)
    library(scales)
    library(stringr)
    
    aznv_ch <- readRDS("aznv_ch.Rds")
    aznv_ch$name <- ifelse(aznv_ch$name == "Abacus Inn Chinese Restaurant", "Abacus Inn", 
                    ifelse(aznv_ch$name == "Abacus Inn Chinese Restaurant-Arrowhead", "Abacus Inn", aznv_ch$name))
    
    top_ch_rest <- aznv_ch[grep(input$dish, tolower(aznv_ch$text)),] %>% 
                  filter(state == input$state, stars.x >= 4) %>% 
                  select(name)
    top_ch_rest <- as.data.frame(sort(table(top_ch_rest), decreasing = TRUE))
    names(top_ch_rest) <- c("Name", "Freq") 
    
    top_ch_rest[1:5,] %>% 
      ggplot(aes(x = reorder(Name, -Freq), y = Freq, fill = Name)) + 
      geom_bar(stat = "identity", col = "blue") +
      scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
      scale_y_continuous(labels = comma) +
      ggtitle(paste("Top 5 Restaurants Serving your Dish")) +
      labs(x = NULL, y = "Count of Positive Reviews") +
      theme(legend.position = "none", plot.title = element_text(family = "Trebuchet MS", color="#666666", face="bold", size = 20), axis.text.x = element_text(size = 14, face = "bold"), axis.text.y = element_text(size = 16))
    })
  })
