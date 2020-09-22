#!/bin/sh
alias gcloud="(docker images google/cloud-sdk || docker pull google/cloud-sdk) > /dev/null;docker run -ti --rm --net=host -v $HOME/.config:/root/.config -v /var/run/docker.sock:/var/run/docker.sock google/cloud-sdk gcloud"
alias gsutil="(docker images google/cloud-sdk || docker pull google/cloud-sdk) > /dev/null;docker run -ti --rm --net=host -v $HOME/.config:/root/.config google/cloud-sdk gsutil"
alias python="(docker images python:2-slim || docker pull python:2-slim) > /dev/null;docker run -ti --rm --net=host -v $HOME/.config:/root/.config -v "$PWD":/usr/src/pyapp -w /usr/src/pyapp python:2-slim python"
alias python3="(docker images python:3-slim || docker pull python:3-slim) > /dev/null;docker run -ti --rm --net=host -v $HOME/.config:/root/.config -v "$PWD":/usr/src/pyapp -w /usr/src/pyapp python:3-slim python"
