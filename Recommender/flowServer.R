## We will use the same var names for associated inputs and outputs
# No pb because they won't be referred the same way => input$ and output$

output$artist_flow = renderUI({
  selectInput(inputId = "artist_flow", "artist", choices = artistsNames)
})

# 2. update tracks of the chosen artist when artists widget changes
observeEvent(
  input$artist_flow,
  {
    output$track_flow = renderUI({
      selectInput(inputId = "track_flow", "track", choices = metadata$track[metadata$artist == input$artist_flow])
    })
  })

# 2. update tracks of the chosen artist when artists widget changes
observeEvent(
  input$artist_flow,
  {
    output$arousal = renderUI({
      sliderInput("arousal", label = "arousal", min = 0, max = 100, value = 50)
    })
  })

# 3. add go button when artists widget selected
observeEvent(
  input$artist_flow,
  {
    output$Go_flow = renderUI(actionBttn("Go_flow","Go!",style = "unite", size = "md", block = TRUE, color = "success"))
  })

# 3. Update preview when track changes
# if preview is available, cool. If not, we go on youtube to get preview
observeEvent(
  input$track_flow,
  {
    prv0 = metadata$preview[metadata$artist == input$artist_flow & metadata$track == input$track_flow]
    
    if(prv0 == "unknown") {
      
      row = metadata[metadata$artist == input$artist_flow & metadata$track == input$track_flow]
      art = row$artist
      trk = row$track
      
      youtubeSearch = gsub(" ", "+", paste(gsub(" ", "+", art), gsub(" ", "+", trk)))
      output$prvSource_flow = renderUI({
        
        ytUrl = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch,"'")
        
        actionButton(inputId = "if", label = "", icon = icon("youtube-square",class = "fa-3x"),
                     onclick = paste0("window.open(",ytUrl,",'_blank')"), width = "140%")
      })
      
    } else {
      output$prvSource_flow = renderUI({
        tags$audio(src = prv0, 
                   type = "audio/mp3", 
                   controls = TRUE,
                   style="height:100%;
                         width:100%;")})
    }
  })