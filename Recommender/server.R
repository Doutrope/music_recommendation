library(shiny)
library(data.table)
library(bit64)
library(dplyr)
library(shinyWidgets)
library(shinydashboard)
library(shinyalert)
library(shinyLP)

#=================
# 1. Load datasets

metadata = fread("./data/metadata_vocab.csv",
                 colClasses = c("integer",rep("character",3))) %>% select(hybridId,artist, track, preview)

arousal = fread("./data/arousal_valence.csv")

metadata = arousal %>% inner_join(metadata, by = "hybridId")

artistsNames = unique(metadata$artist) %>% sort()

similarities = fread("./data/ordered_recos.csv",
                     colClasses = rep("integer",31), header = TRUE)

# 2. source useful functions
source("./utils.R", local = TRUE)

# server object
shinyServer(function(session, input, output) {

  #================================================
  #       SERVER CODE FOR THE FLOW TABITEM
  #================================================

  # object to store reactive Values, values that change with time
  reacValues = reactiveValues()

  ## We will use the same var names for associated inputs and outputs
  # No pb because they won't be referred the same way => input$ and output$

  output$artist_flow = renderUI({
    selectInput(inputId = "artist_flow", "artist", choices = artistsNames, selected = "20Syl")
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
      output$initMood = renderUI({
        sliderTextInput("initMood", label = "mood", choices = c('chill', 'groovy', 'punchy'))
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
      row = metadata %>% filter(artist == input$artist_flow) %>% filter(track == input$track_flow)
      prv0 = row %>% select(preview) %>% as.character()

      if(prv0 == "unknown") {

        youtubeSearch = gsub(" ", "+", paste(gsub(" ", "+", row$artist), gsub(" ", "+", row$track)))
        output$prvSource_flow = renderUI({

          ytUrl = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch,"'")
          div(
            h6("preview"),
            actionButton(inputId = "i", label = "", icon = icon("youtube-square",class = "fa-3x"),
                         onclick = paste0("window.open(",ytUrl,",'_blank')"), width = "80%")
          )
        })

      } else {
        output$prvSource_flow = renderUI({
          div(
            h6("preview"),
            h3(" "),
            tags$audio(src = prv0,
                       type = "audio/mp3",
                       controls = TRUE,
                       style="height:100%;width:100%;"))
      })
    }
      })

  # generate another mood selection corresponding to the user's current mood
  observeEvent(
    input$Go_flow,
    {
      output$currentMood = renderUI({
        sliderTextInput("currentMood", label = "mood", choices = c('chill', 'groovy', 'punchy'))
      })
    })


  observeEvent(
    input$Go_flow,
    {
      # initialize the value of lastLikedTrack
      currentTrackId = metadata %>% filter(artist == input$artist_flow) %>% filter(track == input$track_flow) %>%
        select(hybridId) %>% as.character()

      # update model parameters
      reacValues$lastLikedTrack = data.frame(hybridId = currentTrackId,
                                             artist = input$artist_flow,
                                             track = input$track_flow,
                                             energy = ' ',
                                             mood = ' ')

      reacValues$blacklist = unique(c(reacValues$blacklist, currentTrackId))

      currentTrackArousal = metadata$arousal[metadata$artist == input$artist_flow & metadata$track == input$track_flow]

      # get the reco and the boolean userMood == trackMood
      recoAndMeta = getClosestArousalReco(metadata,
                                          similarities,
                                          currentTrackId,
                                          input$initMood,
                                          reacValues$blacklist,
                                          reacValues$likedTracks)
      recoMeta = recoAndMeta

      # current reco
      reacValues$currentReco = data.frame(hybridId = recoMeta$hybridId,
                                          artist = recoMeta$artist,
                                          track = recoMeta$track,
                                          energy = recoMeta$arousal,
                                          mood = recoMeta$arousalScale)

      query = paste(recoMeta$artist,'-',recoMeta$track)
      url_track = scrapYoutubeFirstVideo(query)

      output$url = renderUI({
        tags$iframe(
          src = url_track,
          width = '700',
          height = '360'
          )
        })
    })

  # add icons like / dislike, button nextReco and reco infos
  observeEvent(
    input$Go_flow,
    {
      output$like = renderUI(radioButtons(inputId="Like", label = "", choices=c("Like","Dislike"), width = '400px'))

      output$nextSong = renderUI(
        div(h1(" "),
          actionBttn(inputId = "nextSong",label = "next song", style = "unite", size = "md", color = "success")))

      # outputs to print the lastLiked Track and the currentReco
      output$currentRecoInfo = renderTable(reacValues$currentReco)
      })

  # change song when nextSong is pressed.
  # Depending on the user interaction with the track, the reco won't be the same :
  observeEvent(
    input$nextSong,
    {

      # if the current track is disliked, we put the track and its top 2 recos in the blacklist,
      # which are tracks that will never appear anymore in the recommendation flow
      if(input$Like == "Dislike") {

        # we update the blacklist with the disliked track and its 5 top recos
        currentDislikes = similarities[similarities$V1 == reacValues$currentReco$hybridId,1:2] %>% unlist %>% as.character()
        reacValues$blacklist = unique(c(reacValues$blacklist, currentDislikes))

        # we make a new query to get recos from the most recent liked track
        recoAndMeta = getClosestArousalReco(metadata,
                                            similarities,
                                            reacValues$lastLikedTrack$hybridId,
                                            input$currentMood,
                                            reacValues$blacklist,
                                            reacValues$likedTracks)

        recoMeta = recoAndMeta

        # we update the value of currentReco
        reacValues$currentReco = data.frame(hybridId = recoMeta$hybridId,
                                            artist = recoMeta$artist,
                                            track = recoMeta$track,
                                            energy = recoMeta$arousal,
                                            mood = recoMeta$arousalScale)

        # outputs to print the lastLiked Track and the currentReco
        output$currentRecoInfo = renderTable(reacValues$currentReco)

        # we make a query to youtube from the last liked track
        query = paste(recoMeta$artist,'-',recoMeta$track)
        url_track = scrapYoutubeFirstVideo(query)

        output$url = renderUI({
          tags$iframe(
            src = url_track,
            width = '700',
            height = '360'
          )
        })

      } else {

        # list to keep track of the tracks liked by the user
        reacValues$likedTracks = unique(c(reacValues$likedTracks,reacValues$currentReco$hybridId))

        # update last liked track
        reacValues$lastLikedTrack = reacValues$currentReco

        # put the current track in blacklist
        # even if th user liked it, we do not want to recommend it anymore
        reacValues$blacklist = unique(c(reacValues$blacklist, as.character(reacValues$currentReco$hybridId)))

        # we make a new query to get the new recommendation
        recoAndMeta = getClosestArousalReco(metadata,
                                            similarities,
                                            reacValues$lastLikedTrack$hybridId,
                                            input$currentMood,
                                            reacValues$blacklist,
                                            reacValues$likedTracks)

        recoMeta = recoAndMeta

        # we update the value of currentReco
        reacValues$currentReco = data.frame(hybridId = recoMeta$hybridId,
                                            artist = recoMeta$artist,
                                            track = recoMeta$track,
                                            energy = recoMeta$arousal,
                                            mood = recoMeta$arousalScale)

        # outputs to print the lastLiked Track and the currentReco
        output$currentRecoInfo = renderTable(reacValues$currentReco)

        # we make a query to youtube
        query = paste(recoMeta$artist,'-',recoMeta$track)
        url_track = scrapYoutubeFirstVideo(query)

        output$url = renderUI({
          tags$iframe(
            src = url_track,
            width = '700',
            height = '360'
            )
          })
      }

    })




  #================================================
  #     SERVER CODE FOR THE TRACK RECO TABITEM
  #================================================

  # 1. artist selection
  output$artist = renderUI({
    selectInput(inputId = "artist", "artist", choices = artistsNames, selected = "20Syl")
  })

  # 2. update tracks of the chosen artist when artists widget changes
  observeEvent(
    input$artist,
    {
      output$track = renderUI({
        selectInput(inputId = "track", "track", choices = metadata$track[metadata$artist == input$artist])
      })
    })

  # 3. add go button when artists widget selected
  observeEvent(
    input$artist,
    {
      output$Go = renderUI(actionBttn("Go","Go!",style = "unite", size = "md", block = TRUE, color = "success"))
      })

  # 3. add preview when track changes
  observeEvent(
    input$track,
    {
      row = metadata %>% filter(artist == input$artist) %>% filter(track == input$track)
      prv0 = row %>% select(preview) %>% as.character

      if(prv0 == "unknown") {

        art = row$artist
        trk = row$track

        youtubeSearch = gsub(" ", "+", paste(gsub(" ", "+", art), gsub(" ", "+", trk)))
        output$prvSource = renderUI({

          ytUrl = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch,"'")

          actionButton(inputId = "i", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl,",'_blank')"), width = "80%")
          })

          } else {
            output$prvSource = renderUI({
              tags$audio(src = prv0,
                         type = "audio/mp3",
                         controls = TRUE,
                         style="height:100%;
                         width:100%;")})
            }
      })

  # 4. Add headers when Go widget clicked
  observeEvent(
    input$Go,
    {
      output$artHeader = renderUI(valueBox("Artist", subtitle = "", icon = icon("user"), width = 3, color = "orange"))
      output$trkHeader = renderUI(valueBox("Track", subtitle = "", icon = icon("music"), width = 3, color = "light-blue"))
      output$prvHeader = renderUI(valueBox("Preview", subtitle = "", icon = icon("headphones"), width = 3, color = "fuchsia"))
      output$formHeader = renderUI(valueBox("Form", subtitle = "", icon = icon("file"), width = 2, color = "lime"))
      })

  # 5. update recos when Go widget clicked
  observeEvent(
    input$Go,
    {
      trackId = metadata$hybridId[metadata$artist == input$artist & metadata$track == input$track]
      trksIds = as.character(similarities[similarities$V1 == trackId])

      # get recos
      recos = data.frame()

      # we take a bit more recos than what we are going to show to the user in order
      # to be sure to have the track in metadata df.
      # this should be replaced by homogeneous bases in the future (all ids in similarity should be in metadata)
      for (i in 2:20){
        recos = rbind(recos, metadata %>% filter(hybridId == trksIds[i]) %>% select(track,artist,preview))
      }

      output$out1trk = renderText(recos[1,]$track)
      output$out1art = renderText(recos[1,]$artist)

      prv1 = recos[1,]$preview
      if(prv1 == "unknown") {

        art1 = recos[1,]$artist
        trk1 = recos[1,]$track

        youtubeSearch1 = gsub(" ", "+", paste(gsub(" ", "+", art1), gsub(" ", "+", trk1)))
        output$out1prv = renderUI({

          ytUrl1 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch1,"'")

          actionButton(inputId = "i1", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl1,",'_blank')"), width = '18%')
        })

      } else {
        output$out1prv = renderUI({tags$audio(src = prv1,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out2trk = renderText(recos[2,]$track)
      output$out2art = renderText(recos[2,]$artist)

      prv2 = recos[2,]$preview
      if(prv2 == "unknown") {

        art2 = recos[2,]$artist
        trk2 = recos[2,]$track

        youtubeSearch2 = gsub(" ", "+", paste(gsub(" ", "+", art2), gsub(" ", "+", trk2)))
        output$out2prv = renderUI({

          ytUrl2 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch2,"'")

          actionButton(inputId = "i2", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl2,",'_blank')"), width = "18%")
        })

      } else {
        output$out2prv = renderUI({tags$audio(src = prv2,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out3trk = renderText(recos[3,]$track)
      output$out3art = renderText(recos[3,]$artist)

      prv3 = recos[3,]$preview
      if(prv3 == "unknown") {

        art3 = recos[3,]$artist
        trk3 = recos[3,]$track

        youtubeSearch3 = gsub(" ", "+", paste(gsub(" ", "+", art3), gsub(" ", "+", trk3)))
        output$out3prv = renderUI({

          ytUrl3 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch3,"'")

          actionButton(inputId = "i3", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl3,",'_blank')"), width = '18%')
        })

      } else {
        output$out3prv = renderUI({tags$audio(src = prv3,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out4trk = renderText(recos[4,]$track)
      output$out4art = renderText(recos[4,]$artist)

      prv4 = recos[4,]$preview
      if(prv4 == "unknown") {

        art4 = recos[4,]$artist
        trk4 = recos[4,]$track

        youtubeSearch4 = gsub(" ", "+", paste(gsub(" ", "+", art4), gsub(" ", "+", trk4)))
        output$out4prv = renderUI({

          ytUrl4 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch4,"'")

          actionButton(inputId = "i4", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl4,",'_blank')"), width = '18%')
        })

      } else {
        output$out4prv = renderUI({tags$audio(src = prv4,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out5trk = renderText(recos[5,]$track)
      output$out5art = renderText(recos[5,]$artist)

      prv5 = recos[5,]$preview
      if(prv5 == "unknown") {

        art5 = recos[5,]$artist
        trk5 = recos[5,]$track

        youtubeSearch5 = gsub(" ", "+", paste(gsub(" ", "+", art5), gsub(" ", "+", trk5)))
        output$out5prv = renderUI({

          ytUrl5 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch5,"'")

          actionButton(inputId = "i5", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl5,",'_blank')"),width = '18%')
        })

      } else {
        output$out5prv = renderUI({tags$audio(src = prv5,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out6trk = renderText(recos[6,]$track)
      output$out6art = renderText(recos[6,]$artist)

      prv6 = recos[6,]$preview
      if(prv6 == "unknown") {

        art6 = recos[6,]$artist
        trk6 = recos[6,]$track

        youtubeSearch6 = gsub(" ", "+", paste(gsub(" ", "+", art6), gsub(" ", "+", trk6)))
        output$out6prv = renderUI({

          ytUrl6 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch6,"'")

          actionButton(inputId = "i6", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl6,",'_blank')"), width = '18%')
        })

      } else {
        output$out6prv = renderUI({tags$audio(src = prv6,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out7trk = renderText(recos[7,]$track)
      output$out7art = renderText(recos[7,]$artist)

      prv7 = recos[7,]$preview
      if(prv7 == "unknown") {

        art7 = recos[7,]$artist
        trk7 = recos[7,]$track

        youtubeSearch7 = gsub(" ", "+", paste(gsub(" ", "+", art7), gsub(" ", "+", trk7)))
        output$out7prv = renderUI({

          ytUrl7 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch7,"'")

          actionButton(inputId = "i7", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl7,",'_blank')"), width = '18%')
        })

      } else {
        output$out7prv = renderUI({tags$audio(src = prv7,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out8trk = renderText(recos[8,]$track)
      output$out8art = renderText(recos[8,]$artist)

      prv8 = recos[8,]$preview
      if(prv8 == "unknown") {

        art8 = recos[8,]$artist
        trk8 = recos[8,]$track

        youtubeSearch8 = gsub(" ", "+", paste(gsub(" ", "+", art8), gsub(" ", "+", trk8)))
        output$out8prv = renderUI({

          ytUrl8 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch8,"'")

          actionButton(inputId = "i8", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl8,",'_blank')"), width = '18%')
        })

      } else {
        output$out8prv = renderUI({tags$audio(src = prv8,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out9trk = renderText(recos[9,]$track)
      output$out9art = renderText(recos[9,]$artist)

      prv9 = recos[9,]$preview
      if(prv9 == "unknown") {

        art9 = recos[9,]$artist
        trk9 = recos[9,]$track

        youtubeSearch9 = gsub(" ", "+", paste(gsub(" ", "+", art9), gsub(" ", "+", trk9)))
        output$out9prv = renderUI({

          ytUrl9 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch9,"'")

          actionButton(inputId = "i9", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl9,",'_blank')"), width = '18%')
        })

      } else {
        output$out9prv = renderUI({tags$audio(src = prv9,
                                              type = "audio/mp3", controls = TRUE)})
      }

      output$out10trk = renderText(recos[10,]$track)
      output$out10art = renderText(recos[10,]$artist)

      prv10 = recos[10,]$preview
      if(prv10 == "unknown") {

        art10 = recos[10,]$artist
        trk10 = recos[10,]$track

        youtubeSearch10 = gsub(" ", "+", paste(gsub(" ", "+", art10), gsub(" ", "+", trk10)))
        output$out10prv = renderUI({

          ytUrl10 = paste0("'https://www.youtube.com/results?search_query=",youtubeSearch10,"'")

          actionButton(inputId = "i10", label = "", icon = icon("youtube-square",class = "fa-3x"),
                       onclick = paste0("window.open(",ytUrl10,",'_blank')"), width = '18%')
        })

      } else {
        output$out10prv = renderUI({tags$audio(src = prv10,
                                               type = "audio/mp3", controls = TRUE)})
      }

      })

  # 6. update rating buttons when Go widget clicked
  observeEvent(
    input$Go,
    {
      output$up1 = renderUI(
        prettyCheckbox("up1", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",
                       bigger=TRUE, width = "900px"))
      output$bad1 = renderUI(
        prettyCheckbox("bad1", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up2 = renderUI(
        prettyCheckbox("up2", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad2 = renderUI(
        prettyCheckbox("bad2", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up3 = renderUI(
        prettyCheckbox("up3", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad3 = renderUI(
        prettyCheckbox("bad3", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up4 = renderUI(
        prettyCheckbox("up4", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad4 = renderUI(
        prettyCheckbox("bad4", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up5 = renderUI(
        prettyCheckbox("up5", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad5 = renderUI(
        prettyCheckbox("bad5", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up6 = renderUI(
        prettyCheckbox("up6", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad6 = renderUI(
        prettyCheckbox("bad6", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up7 = renderUI(
        prettyCheckbox("up7", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad7 = renderUI(
        prettyCheckbox("bad7", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up8 = renderUI(
        prettyCheckbox("up8", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad8 = renderUI(
        prettyCheckbox("bad8", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up9 = renderUI(
        prettyCheckbox("up9", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad9 = renderUI(
        prettyCheckbox("bad9", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))

      output$up10 = renderUI(
        prettyCheckbox("up10", icon=icon("heart"), shape = "curve", animation = "tada", label = "Good!",bigger=TRUE))
      output$bad10 = renderUI(
        prettyCheckbox("bad10", icon=icon("ban"), shape = "curve", animation = "tada", label = "Bad...",bigger=TRUE))
    }
  )

  # 7. generate Save Button when Go widget clicked
  observeEvent(
    input$Go,
    {
      output$Save = renderUI(
        actionBttn("Save","Save", style = "pill", size = "lg",block = TRUE,color = "success"))
    })

  # 8. save to csv when save widget clicked
  observeEvent(
    input$Save,
    {
      rates = data.frame()
      trkId = metadata %>% filter(artist == input$artist) %>% filter(track == input$track) %>%
        select(hybridId) %>% as.character()

      for(i in 1:10){

        up = input[[paste0("up",i)]]
        bad = input[[paste0("bad",i)]]

        if(up || bad){

          rate = 0
          if(up==TRUE){
            rate = 1
          }
          rates = rbind(rates, data.frame(trackId = trkId,
                                          recoPosition = i,
                                          rate = rate))
          }
      }

      write.csv(rates,
                file = "./rates.csv",
                append = T,
                row.names = FALSE)

      # Print thk you
      shinyalert("Saved!", "Thank you :)", type = "success")
      })
  })
