#/bin/bash

TPM_DIR="${HOME}/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR/.git" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  git -C "$TPM_DIR" pull --ff-only
fi

"$TPM_DIR/bin/install_plugins"


