#!/bin/bash

# Exit with error if not on Ubuntu
if ! command -v apt &> /dev/null; then
  echo "Error: This setup script is intended for Ubuntu only."
  exit 1
fi

# Update package list
echo "Updating package list..."
sudo apt update

# Code editor and environment
echo "Installing code editor and environment..."
sudo apt install -y neovim tmux tree-sitter-cli

# Terminal and shell
echo "Installing terminal and shell packages..."
sudo apt install -y bash fish neofetch

# Nushell (not in apt on older Ubuntu, install via cargo)
if ! command -v nu &> /dev/null; then
  sudo snap install nushell
fi

# Starship (no apt package, official installer)
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh
fi

# Kitty (no apt package, official installer)
if ! command -v kitty &> /dev/null; then
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
fi

# Development tools
echo "Installing development tools..."
sudo apt install -y git make cmake

# Other utilities
echo "Installing other utilities..."
sudo apt install -y wget

# Nerd Fonts (no package manager, manual install)
mkdir -p ~/.local/share/fonts
wget -q --show-progress \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip \
  -O /tmp/Hack.zip
unzip -o /tmp/Hack.zip -d ~/.local/share/fonts/HackNerdFont
fc-cache -fv

# Cleanup
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt clean

echo "Done!"
