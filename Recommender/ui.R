library(shiny)
library(shinyWidgets)
library(shinyalert)
library(shinydashboard)

# 1. Header
header <- dashboardHeader(
  title = "MWM recommendation",
  titleWidth = 300)

# 2. Sidebar
sidebar = dashboardSidebar(
  
  # logo 
  h5(" "),
  fluidRow(
    column(1,h1("")),
    img(src="logo.png",height=50,width=200)),
  
  # menu
  sidebarMenu(
    menuItem("Track reco", tabName = "trackReco", icon = icon("play")),
    menuItem("Flow", tabName = "flow", icon = icon("cloud"))
  ))
  
# 3. body
# This part concerns the center of the web page and the 
# recommendations displaying 
body = dashboardBody(
  tabItems(
    
    # tabItem for track reco
    source("./trackRecoUI.R", local = TRUE)$value,
    
    # tabItem for flow
    source("./flowUI.R", local = TRUE)$value
  ))

# generate dashboard
dashboardPage(
  header,
  sidebar,
  body)