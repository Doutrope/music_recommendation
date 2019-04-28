#!/bin/bash

#### dl and install docker (from https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1)

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Get the stable repositery
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update apt-get
sudo apt-get update

# Install
sudo apt-get --yes install docker-ce=17.12.1~ce-0~ubuntu

#### build docker image (must be done in dir where Dockerfile is located)
sudo docker build . -t shinyreco

# see if the image was correctly built, ours should appear
sudo docker images

# create docker container by running image
sudo docker run --rm -p 3838:3838 shinyreco