
#========================
# This code generates a ui
# page for tracks reco
#========================

tabItem(
  tabName = "trackReco",
  
  # style and polices for icons and html objects
  tags$style(".fa-heart {color:#7CFC00}"),
  tags$style(".fa-ban {color:#E87722}"),
  tags$head(
    tags$style(HTML(".fa-user { font-size: 48px; }"))),
  tags$head(
    tags$style(HTML(".fa-music { font-size: 48px; }"))),
  tags$head(
    tags$style(HTML(".fa-headphones { font-size: 48px; }"))),
  tags$head(
    tags$style(HTML(".fa-file { font-size: 48px; }"))),

  tags$head(tags$style(paste0("#out",1,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",1,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",2,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",2,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",3,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",3,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",4,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",4,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",5,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",5,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",6,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",6,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",7,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",7,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",8,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",8,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",9,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",9,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  tags$head(tags$style(paste0("#out",10,"art{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  tags$head(tags$style(paste0("#out",10,"trk{font-size: 20px;
                              font-style: bold;
                              font-family: 'Georgia':}
                              "))),
  
  # use shinyalert for popup message
  useShinyalert(),
  
  # This is the ui
  fluidRow(
    
    # tutorial
    box(
      title = 'Instructions',
      status = 'warning',
      collapsible = TRUE,
      solidHeader = TRUE,
      fluidRow(
        column(12, h4("1. In the 'Source track' tab, choose an artist (the scrolling menu is a search bar and not all artists are listed so use your keyboard ;). Then choose a track, then click on Go! button. The IA recommends you the 10 most related tracks based on our data."))),
      fluidRow(
        column(12, h4("2. In the 'Recommendations' tab, you have access to the most related tracks, you can give your opinion on each recommended track. We will analyze the results to improve our models !")))
    ),
    
    # source track
    box(
      title = 'Source track',
      status = 'primary',
      collapsible = TRUE,
      solidHeader = TRUE,
    fluidRow(
      column(6,uiOutput("artist")),
      column(6,uiOutput("track"))),
    fluidRow(
      column(6,uiOutput("prvSource")),
      column(6,uiOutput("Go"))))
    ),
  
  box(
    width = 12,
    title = 'Recommendations',
    status = 'primary',
    collapsible = TRUE,
    solidHeader = TRUE,
    fluidRow(
      uiOutput("artHeader"),
      uiOutput("trkHeader"),
      uiOutput("prvHeader"),
      uiOutput("formHeader")),
    fluidRow(
      column(3, textOutput("out1art")),
      column(3, textOutput("out1trk")),
      column(3, uiOutput("out1prv")),
      column(1, uiOutput("up1")),
      column(1, uiOutput("bad1"))),
    fluidRow(h4("")),
    fluidRow(h4("")),
    fluidRow(
      column(3, textOutput("out2art")),
      column(3, textOutput("out2trk")),
      column(3, uiOutput("out2prv")),
      column(1, uiOutput("up2")),
      column(1, uiOutput("bad2"))),
    fluidRow(h4("")),
    fluidRow(h4("")),
    fluidRow(
      column(3, textOutput("out3art")),
      column(3, textOutput("out3trk")),
      column(3, uiOutput("out3prv")),
      column(1, uiOutput("up3")),
      column(1, uiOutput("bad3"))),
    fluidRow(h4("")),
    fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out4art")),
    column(3, textOutput("out4trk")),
    column(3, uiOutput("out4prv")),
    column(1, uiOutput("up4")),
    column(1, uiOutput("bad4"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out5art")),
    column(3, textOutput("out5trk")),
    column(3, uiOutput("out5prv")),
    column(1, uiOutput("up5")),
    column(1, uiOutput("bad5"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out6art")),
    column(3, textOutput("out6trk")),
    column(3, uiOutput("out6prv")),
    column(1, uiOutput("up6")),
    column(1, uiOutput("bad6"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out7art")),
    column(3, textOutput("out7trk")),
    column(3, uiOutput("out7prv")),
    column(1, uiOutput("up7")),
    column(1, uiOutput("bad7"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out8art")),
    column(3, textOutput("out8trk")),
    column(3, uiOutput("out8prv")),
    column(1, uiOutput("up8")),
    column(1, uiOutput("bad8"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out9art")),
    column(3, textOutput("out9trk")),
    column(3, uiOutput("out9prv")),
    column(1, uiOutput("up9")),
    column(1, uiOutput("bad9"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(3, textOutput("out10art")),
    column(3, textOutput("out10trk")),
    column(3, uiOutput("out10prv")),
    column(1, uiOutput("up10")),
    column(1, uiOutput("bad10"))),
  fluidRow(h4("")),
  fluidRow(h4("")),
  fluidRow(
    column(9, h2("")),
    column(2, uiOutput("Save"))
  )))