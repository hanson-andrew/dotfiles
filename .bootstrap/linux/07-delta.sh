#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
REPO="dandavison/delta"

arch="$(uname -m)"

case "$arch" in
  x86_64|amd64)
    target="x86_64-unknown-linux-gnu"
    ;;
  aarch64|arm64)
    target="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="$(
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" |
    grep -Eo '"browser_download_url": "[^"]+"' |
    cut -d'"' -f4 |
    grep -E "delta-.*-${target}\.tar\.gz$" |
    head -n 1
)"

if [[ -z "$url" ]]; then
  echo "Could not find delta Linux tarball for $target" >&2
  exit 1
fi

echo "Downloading $url"
curl -fL "$url" -o "$tmp/delta.tar.gz"

tar -xzf "$tmp/delta.tar.gz" -C "$tmp"

bin="$(
  find "$tmp" -type f -name delta |
    head -n 1
)"

if [[ -z "$bin" ]]; then
  echo "Could not find delta binary in archive" >&2
  exit 1
fi

echo "Installing delta to $INSTALL_DIR"
if [[ -w "$INSTALL_DIR" ]]; then
  install -m 0755 "$bin" "$INSTALL_DIR/delta"
else
  sudo install -m 0755 "$bin" "$INSTALL_DIR/delta"
fi

echo "Installed:"
delta --version

git config --global include.path ~/.delta.gitconfig


