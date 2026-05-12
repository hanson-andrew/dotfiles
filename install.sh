#!/usr/bin/env bash
set -euo pipefail

DOTFILES_BARE_DIR="${HOME}/.dotfiles"
DOTFILES_REMOTE_URL="${DOTFILES_REMOTE_URL:-https://github.com/hanson-andrew/dotfiles.git}"
STAMP="${HOME}/.dotfiles-bootstrap-done"

if [ ! -d "${DOTFILES_BARE_DIR}" ]; then
  git clone --bare "${DOTFILES_REMOTE_URL}" "${DOTFILES_BARE_DIR}"
fi

git --git-dir="${DOTFILES_BARE_DIR}" --work-tree="${HOME}" checkout -f
git --git-dir="${DOTFILES_BARE_DIR}" --work-tree="${HOME}" config --local status.showUntrackedFiles no

if [ -x "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh" ]; then
  "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh"
elif [ -f "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh" ]; then
  sh "$HOME/.bootstrap/linux/bootstrap-ubuntu.sh"
else
  echo "Expected $HOME/.bootstrap/linux/bootstrap-ubuntu.sh but it was not found" >&2
  exit 1
fi

if [ ! -d "${HOME}/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/powerlevel10k"
fi

touch "${STAMP}"

