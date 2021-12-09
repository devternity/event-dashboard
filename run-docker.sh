#!/usr/bin/env bash

IMAGE=devternity/event
NAME=dashboard
docker build -t ${IMAGE} .

(docker container ls -a | grep ${NAME}) && \
  (docker container rm -fv ${NAME} || echo "Could not remove ${NAME}")

mkdir -p .database
touch .database/twitter.db

docker run -dit \
  -p 3030:3030 \
  -e SINATRA_ACTIVESUPPORT_WARNING=false \
  -v "${PWD}":/app \
  -v "${PWD}/.database":/var/lib/sqlite \
  --name ${NAME} \
  ${IMAGE}
