#!/bin/bash

# Exit with error if not on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Error: This setup script is intended for macOS only."
  exit 1
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

# Code editor and environment
echo "Installing code editor and environment..."
brew install neovim tmux tree-sitter tree-sitter-cli

# Terminal and shell
echo "Installing terminal and shell packages..."
brew install bash fish nushell kitty starship neofetch

# Development tools
echo "Installing development tools..."
brew install git make cmake

# Other utilities
echo "Installing other utilities..."
brew install wget tree
brew install --cask font-hack-nerd-font

# Cleanup
echo "Cleaning up Homebrew..."
brew cleanup

echo "Done!"
