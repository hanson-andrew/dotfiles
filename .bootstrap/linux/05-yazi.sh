#!/bin/bash

#!/usr/bin/env bash
set -euo pipefail

REPO="sxyazi/yazi"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TMP_DIR="$(mktemp -d)"
USE_MUSL="${USE_MUSL:-0}"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

need_cmd curl
need_cmd unzip
need_cmd uname
need_cmd grep
need_cmd sed
need_cmd find
need_cmd chmod
need_cmd mkdir

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64|amd64) TARGET_ARCH="x86_64" ;;
      aarch64|arm64) TARGET_ARCH="aarch64" ;;
      *)
        echo "error: unsupported Linux architecture: $ARCH" >&2
        exit 1
        ;;
    esac

    if [ "$USE_MUSL" = "1" ]; then
      TARGET="${TARGET_ARCH}-unknown-linux-musl"
    else
      TARGET="${TARGET_ARCH}-unknown-linux-gnu"
    fi
    ;;
  Darwin)
    case "$ARCH" in
      x86_64|amd64) TARGET="x86_64-apple-darwin" ;;
      arm64|aarch64) TARGET="aarch64-apple-darwin" ;;
      *)
        echo "error: unsupported macOS architecture: $ARCH" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "error: unsupported OS: $OS" >&2
    echo "This script supports Linux and macOS." >&2
    exit 1
    ;;
esac

echo "Installing Yazi for target: $TARGET"
echo "Install directory: $INSTALL_DIR"

API_URL="https://api.github.com/repos/${REPO}/releases/latest"

ASSET_URL="$(
  curl -fsSL "$API_URL" |
    grep "browser_download_url" |
    grep "$TARGET" |
    grep -E '\.zip"' |
    sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/' |
    head -n 1
)"

if [ -z "${ASSET_URL:-}" ]; then
  echo "error: could not find a release asset for target: $TARGET" >&2
  echo "Try USE_MUSL=1 $0 on Linux, or check https://github.com/${REPO}/releases" >&2
  exit 1
fi

ARCHIVE="$TMP_DIR/yazi.zip"

echo "Downloading: $ASSET_URL"
curl -fL "$ASSET_URL" -o "$ARCHIVE"

echo "Extracting..."
unzip -q "$ARCHIVE" -d "$TMP_DIR/extract"

YAZI_BIN="$(find "$TMP_DIR/extract" -type f -name yazi -perm -u+x | head -n 1)"
YA_BIN="$(find "$TMP_DIR/extract" -type f -name ya -perm -u+x | head -n 1)"

if [ -z "${YAZI_BIN:-}" ] || [ -z "${YA_BIN:-}" ]; then
  echo "error: could not find yazi and ya binaries in the release archive" >&2
  find "$TMP_DIR/extract" -type f >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"

install -m 0755 "$YAZI_BIN" "$INSTALL_DIR/yazi"
install -m 0755 "$YA_BIN" "$INSTALL_DIR/ya"

echo
echo "Installed:"
"$INSTALL_DIR/yazi" --version || true
"$INSTALL_DIR/ya" --version || true

echo
echo "Done."

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "Note: $INSTALL_DIR is not on your PATH."
    echo "Add this to your shell config:"
    echo
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

if ! command -v file >/dev/null 2>&1; then
  echo
  echo "Warning: 'file' is not installed or not on PATH."
  echo "Yazi requires it for file type detection."
fi

