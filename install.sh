#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

SOURCE_USER_DIR="$SCRIPT_DIR/home/user"
SOURCE_CONFIG_DIR="$SOURCE_USER_DIR/.config"
DEST_HOME="/home/$USER"
DEST_CONFIG_DIR="$DEST_HOME/.config"

echo "Copying .xinitrc and .zshrc to $DEST_HOME..."
cp "$SOURCE_USER_DIR/.xinitrc" "$DEST_HOME/"
cp "$SOURCE_USER_DIR/.zshrc" "$DEST_HOME/"
echo "Files copied."

echo "Copying configuration folders from $SOURCE_CONFIG_DIR to $DEST_CONFIG_DIR..."
mkdir -p "$DEST_CONFIG_DIR"
cp -r "$SOURCE_CONFIG_DIR"/* "$DEST_CONFIG_DIR/"
echo "Configuration folders copied."

echo "Setup script finished."
