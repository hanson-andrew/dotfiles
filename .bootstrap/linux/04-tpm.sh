#/bin/bash

mkdir -p ~/.config/tmux/themes
curl -fsSL \
  https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/tmux/tokyonight_moon.tmux \
  -o ~/.config/tmux/themes/tokyonight_moon.tmux

TPM_DIR="${HOME}/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR/.git" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  git -C "$TPM_DIR" pull --ff-only
fi

"$TPM_DIR/bin/install_plugins"


