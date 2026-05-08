#/bin/bash

#!/bin/bash


PACKAGES=(
  jq
  unzip
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"


