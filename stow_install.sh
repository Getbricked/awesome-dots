#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

STOW_DIR="$SCRIPT_DIR/home"
PACKAGE="user"

command -v stow >/dev/null 2>&1 || {
  echo "stow is not installed."
  exit 1
}

stow -d "$STOW_DIR" -t "$HOME" --verbose 2 "$PACKAGE"
echo "Stow finished."
