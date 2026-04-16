#!/bin/bash


PACKAGES=(
  neovim
  jq
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | sh
