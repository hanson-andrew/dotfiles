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

TPM_DIR="${HOME}/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR/.git" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  git -C "$TPM_DIR" pull --ff-only
fi

"$TPM_DIR/bin/install_plugins"

