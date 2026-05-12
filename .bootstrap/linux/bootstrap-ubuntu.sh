#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$BOOTSTRAP_DIR/01-base-packages.sh"
"$BOOTSTRAP_DIR/02-devcontainers-cli.sh"
"$BOOTSTRAP_DIR/03-neovim.sh"
"$BOOTSTRAP_DIR/04-tpm.sh"
"$BOOTSTRAP_DIR/05-yazi.sh"
"$BOOTSTRAP_DIR/06-starship.sh"
"$BOOTSTRAP_DIR/07-delta.sh"

