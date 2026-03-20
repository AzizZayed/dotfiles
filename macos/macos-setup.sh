#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# macOS check
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Error: This script is for macOS only." >&2
  exit 1
fi

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Re-run this script after the Xcode CLT installation completes."
  exit 0
fi

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for the rest of this script (Apple Silicon)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Packages & Apps
echo "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

# Cleanup
brew cleanup

echo ""
echo "Done! A few apps require manual installation:"
echo "  - Cisco Secure Client  (corporate VPN — download from IT)"
echo "  - XP-Pen tablet driver (xp-pen.com)"
echo "  - FileZilla            (filezilla-project.org)"
echo "  - TinkerTool           (bresink.com/osx/TinkerTool.html)"
echo "  - EjectBar             (check Mac App Store)"
echo "  - Disk Expert          (check Mac App Store)"
