
#!/bin/bash


PACKAGES=(
  tmux
  jq
  unzip
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

