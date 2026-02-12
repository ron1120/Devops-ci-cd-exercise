#!/bin/bash
## Docker build command:
## docker build -t jenkins-devops:latest .

## Make sure you have the Jenkins image built before running this script. You can build the image using the provided Dockerfile in the project directory.\
## Can copy and paste the and run build command or just execute after jenkins-devops image is built.

docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins-devops:latest
