#!/bin/bash


PACKAGES=(
  tmux
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

curl -fsSL https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh | sh

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /opt/nvim/nvim

