FROM rocker/shiny:3.4.1

# install R package dependencies
RUN sudo apt-get update && sudo apt-get install -y libssl-dev \
    ## clean up
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/ \ 
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
    
## Install packages from CRAN
RUN install2.r --error \ 
    -r 'http://cran.rstudio.com' \
    dplyr \
    shinyWidgets \
    data.table \
    bit64 \
    shinyalert \
    shinythemes \
    shiny \
    httr \
    shinyLP \
    shinydashboard && \
    
    ## clean up
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

## assume shiny app is in build folder /shiny
COPY ./Recommender/ /srv/shiny-server/Recommender/
