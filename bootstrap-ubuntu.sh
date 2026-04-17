#!/bin/bash


PACKAGES=(
  jq
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | sh

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
sudo mkdir -p /opt/nvim
sudo mv nvim-linux-x86_64.appimage /opt/nvim/nvim
