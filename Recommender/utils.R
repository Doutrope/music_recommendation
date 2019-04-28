library(httr)

# This function returns a track in the same mood as the targetArousal
# among the top n recommendations of trkId. If not possible, returns the
# reco which has the closest arousal score from the current arousalMood.
# Also returns the fact that the track is or not of the chosen mood.
# metadataArVal : df tracks metadata with arousal
# similarities : df with ordered top n recos for each track
# trkId : current track id
# blacklist : tracks to filter because disliked
getClosestArousalReco <- function(metadataArVal,
                                  similarities,
                                  trkId,
                                  arousalMood,
                                  blacklist,
                                  likedTracks) {

  # get top n recos of trkId
  recosList = similarities %>% filter(V1 == trkId) %>% unlist() %>% as.character()
  recosList = recosList[2:31]

  # get recos in df format, filter blacklisted tracks
  recos = metadataArVal %>% filter(hybridId %in% recosList & !(hybridId %in% blacklist))

  # if no recos because of blacklist, we get the recos of the last liked
  # tracks, from the most recent to the oldest.
  i=length(likedTracks)

  if(nrow(recos==0)){
    while(nrow(recos) == 0){
      recosList = similarities %>% filter(V1 == likedTracks[i]) %>% unlist() %>% as.character()
      recosList = recosList[2:31]

      recos = metadataArVal %>% filter(hybridId %in% recosList & !(hybridId %in% blacklist))
      i=i-1
    }
  }
  # get recos in the user's mood
  recosCurrentMood = recos %>% filter(arousalScale == arousalMood)

  # Get the tracks corresponding to the current mood if possible
  if(nrow(recosCurrentMood) > 0) {

    # randomly select one in that group
    randIdx = sample(1:nrow(recosCurrentMood),1)
    finalReco = recosCurrentMood[randIdx,]

  # if not possible, get the reco which is the closest to the chosen mood
  } else {

    closestArousal = switch(arousalMood, chill = 52, groovy = 56, punchy = 64)
    finalReco = recos %>% mutate(arousalDiff = abs(arousal - closestArousal)) %>%
      filter(arousalDiff == min(arousalDiff))

  }

  # we return the 1st row of closestRecos in order to get rid of equal arousals problems
  return(finalReco[1,])
}


# Youtube query extractor,
# returns the ID of the 1st video proposed by youtube for a given search query

scrapYoutubeFirstVideo <- function(query, embed = TRUE) {

  # format query so that special characters be replaced by
  # their value in url style
  query = URLencode(query, reserved = TRUE)

  # Get html code
  page = GET(paste0("http://youtube.fr/results?search_query=",query))
  txt = content(page, type = 'text')

  # This aweful code extracts the id of the 1st youtube video
  # by getting the id after the first occurence of href=\"/watch in html code
  videoId = gsub("\\?v=","",strsplit(strsplit(txt, "href=\"/watch")[[1]][2], "\"")[[1]][1])

  if(embed){

    # youtube url
    return(paste0("https://www.youtube.com/embed/",videoId,"?rel=0"))
  } else {
    return(paste0("https://www.youtube.com/watch?v=",videoId))
  }
}

# this functions reorganises the df metadata which outputs from track2vec.
# it generates a unique row for each tuple (hybridId/deezerId)
splitMetadataOutputWord2vec <- function() {
  x = fread("./data/metadata_vocab.csv")
  y = fread("./data/arousal_valence.csv")
  colnames(y)[1] = 'deezerId'
  y$deezerId = as.character(y$deezerId)

  res = list()
  idx = 1
  for(i in 1:nrow(x)){
    hybridId = x$hybridId[i]
    deezerIdsStr = x$deezerIds[i]
    deezerIds = strsplit(deezerIdsStr,"'")[[1]]

    l=1
    finalDeezerIds = list()
    for(k in 1:length(deezerIds)){
      if(nchar(deezerIds[k])>3){
        finalDeezerIds[[l]] = deezerIds[k]
        l=l+1
      }
    }

    for(j in 1:length(finalDeezerIds)){
      res[[idx]] = c(hybridId,finalDeezerIds[[j]],x$artist[i],x$track[i],x$preview[i])
      idx=idx+1
    }
  }

  flattenedDf = do.call(rbind.data.frame,res)
  colnames(flattenedDf)=c('hybridId','deezerId','artist','track','preview')

  joinMetaArousal = flattenedDf %>% inner_join(y, by = 'deezerId')

  # if 2 or more rows have the same hybridId, take randomly 1.
  # this is done in order to have only one hybridId for arousal df
  finalArousal = joinMetaArousal[!duplicated(joinMetaArousal[,c('hybridId')]),] %>% select(hybridId,arousal, arousalScale)
  write.csv(finalArousal,'./data/arousal_valence.csv', row.names = FALSE)
}
