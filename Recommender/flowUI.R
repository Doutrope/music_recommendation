tabItem(
  tabName = "flow",
  
  # This is the ui
  
  # tutorial
  fluidRow(
    box(
      title = 'Instructions',
      status = 'warning',
      collapsible = TRUE,
      solidHeader = TRUE,
      fluidRow(
        column(12, h4("1. In the 'Initialization' tab, type wih your keyboard an artist you like (the scrolling menu is a search bar and not all artists are listed so use your keyboard ;). Then choose a track and your current mood. Then click on Go! button. MWM flow recommends you the best track according to the source track and your current mood. After this step, you do not need the Initialization tab anymore."))),
      fluidRow(
        column(12, h4("2. In the 'Flow' tab, you have 2 ways to influence the next recommendations : the Like/Dislike button and your current mood. The algorithm takes these elements into account to update its parameters and recommend you the best :)")))
      ),

    # initialization of the flow
    box(
      title = 'Initialization',
      status = 'primary',
      solidHeader = TRUE,
      collapsible = TRUE,
      fluidRow(
        column(6,uiOutput("artist_flow")),
        column(6,uiOutput("track_flow"))),
      fluidRow(
        column(4,uiOutput("prvSource_flow")),
        column(4,uiOutput("initMood")),
        column(4,h2(" "),uiOutput("Go_flow")))
      )),
  
  # flow
  fluidRow(
    box(
      title = 'Flow',
      status = "primary",
      solidHeader = TRUE,
      collapsible = TRUE,
      width = 12,
      fluidRow(
        column(3,h1(" ")),
        column(4,uiOutput("url"))),
      fluidRow(
          column(4, h1(" ")),
          column(1,uiOutput('like')),
          column(2,uiOutput('currentMood')),
          column(4,fluidRow(
            uiOutput('nextSong')))),
      fluidRow(
        column(4, h1(" ")),
        column(4,tableOutput("currentRecoInfo"))))
    )
  )