#!/bin/bash


PACKAGES=(
  neovim
)

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

