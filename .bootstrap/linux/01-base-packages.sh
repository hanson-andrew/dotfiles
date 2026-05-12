#!/bin/bash

PACKAGES=(
  tmux
  jq
  unzip
  file
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

