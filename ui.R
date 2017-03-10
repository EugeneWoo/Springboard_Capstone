library(shiny)

# Define UI for application that draws a barplot
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Mysteries of the Yelp Orient"),
  
  # Sidebar with a dropdown input
  sidebarLayout(
    sidebarPanel(
      selectInput("state", label = h5("Select Your State"), 
                  choices = list("Arizona" = "AZ", 
                                 "Nevada" = "NV")),
      selectInput("dish", label = h5("Select Your Dish"), 
                  choices = list("Fried Rice" = ".*fried rice", # catch-all for chicken/jerk/pork fried rice
                                 "Egg Drop Soup" = "egg drop soup",
                                 "Hot & Sour Soup" = "hot.*sour soup", # "hot.*sour soup" includes "hot & sour", "hot and sour"
                                 "Sweet & Sour Dishes" = "sweet.*sour", # "sweet sour" dishes incl. sweet & sour pork
                                 "Kung Pao Chicken" = "kung pao.+", # "kung pao chicken" / "kung pao xxx"
                                 "Chicken Mongolian" = ".+mongolian", # "chicken mongolian" / "mongolian xxx"
                                 "Beef Noodle Soup" = "beef.*noodle soup"))
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("barplot")
    )
  )
))
