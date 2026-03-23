#!/bin/bash
set -euo pipefail

log() {
  echo ""
  echo ">>> $*"
  echo ""
}

check_ubuntu() {
  if ! command -v apt &>/dev/null; then
    echo "Error: This setup script is intended for Ubuntu only."
    exit 1
  fi
}

update_packages() {
  log "Updating package list"
  sudo apt update
}

install_dev_tools() {
  log "Installing core development tools"
  sudo apt install -y \
    build-essential make git curl wget vim \
    cmake gcc llvm \
    jq tree net-tools whois \
    tmux tree-sitter-cli \
    libblas-dev liblapack-dev libopenblas-dev libssl-dev \
    unzip
  snap list nvim &>/dev/null || sudo snap install nvim --classic
}

install_utilities() {
  log "Installing core utilities"
  sudo apt install -y \
    htop solaar ffmpeg speedtest-cli 7zip gnupg2
}

install_languages() {
  log "Installing programming languages"

  # Python
  sudo apt install -y \
    python3 python3-pip python3-venv python3-virtualenv

  # Java
  sudo apt install -y openjdk-25-jdk

  # JS
  sudo apt install -y yarn

  # Rust
  if ! command -v cargo &>/dev/null; then
    local rustup_url="https://sh.rustup.rs"
    curl --proto '=https' --tlsv1.2 -sSf "$rustup_url" | sh -s -- -y
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    # Ensure cargo env is sourced on every login (not in .bashrc/.zshrc)
    echo 'source $HOME/.cargo/env' >> "$HOME/.bashrc.local"
  fi
}

install_shell_tools() {
  log "Installing terminal and shell packages"

  local starship_url="https://starship.rs/install.sh"
  local kitty_url="https://sw.kovidgoyal.net/kitty/installer.sh"

  sudo apt install -y bash neofetch

  # Add fish to the list of valid shells and set it as default
  if ! command -v fish &>/dev/null; then
    sudo apt install -y fish
    if ! grep -q "$(command -v fish)" /etc/shells; then
      echo "$(command -v fish)" | sudo tee -a /etc/shells
    else
      log "Fish already in /etc/shells, skipping"
    fi
  fi

  # Nushell (no apt package)
  if ! command -v nu &>/dev/null; then
    sudo snap install nushell --classic
    # Add nushell to the list of valid shells and set it as default
    if ! grep -q "$(command -v nu)" /etc/shells; then
      echo "$(command -v nu)" | sudo tee -a /etc/shells
    else
      log "Nushell already in /etc/shells, skipping"
    fi
  fi

  # Starship (no apt package, official installer)
  if ! command -v starship &>/dev/null; then
    curl -sS "$starship_url" | sh # TODO: feed in 'y' to make it not interactive
  fi

  # Kitty (no apt package, official installer)
  if ! command -v kitty &>/dev/null; then
    curl -L "$kitty_url" | sh /dev/stdin
    # Create symbolic links to add kitty and kitten to PATH (assuming ~/.local/bin is in your system-wide PATH)
    ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
    # Place the kitty.desktop file somewhere it can be found by the OS
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
    # If you want to open text files and images in kitty via your file manager also add the kitty-open.desktop file
    cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
    # Update the paths to the kitty and its icon in the kitty desktop file(s)
    sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
    sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
    # Make xdg-terminal-exec (and hence desktop environments that support it use kitty)
    echo 'kitty.desktop' > ~/.config/xdg-terminals.list
  fi
}

install_nvidia() {
  if ! lspci | grep -i nvidia &>/dev/null; then
    log "No NVIDIA GPU detected, skipping NVIDIA driver and CUDA installation"
    return
  fi

  log "NVIDIA GPU detected — installing drivers and utilities"

  sudo apt install -y nvidia-settings nvtop

  # Build CUDA repo URL dynamically from OS version and architecture
  local ubuntu_version arch cuda_keyring_url
  ubuntu_version="$(. /etc/os-release && echo "$VERSION_ID" | tr -d '.')"
  arch="$(uname -m)"
  cuda_keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${ubuntu_version}/${arch}/cuda-keyring_1.1-1_all.deb"

  if ! dpkg -s cuda-keyring &>/dev/null; then
    wget -q "$cuda_keyring_url" -O /tmp/cuda-keyring.deb
    sudo dpkg -i /tmp/cuda-keyring.deb
    sudo apt update
  fi
  sudo apt install -y cuda-toolkit-12-8

  # Add CUDA to PATH (idempotent)
  grep -qxF 'export PATH=/usr/local/cuda/bin:$PATH' "$HOME/.bashrc.local" \
    || echo 'export PATH=/usr/local/cuda/bin:$PATH' >> "$HOME/.bashrc.local"
  grep -qxF 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' "$HOME/.bashrc.local" \
    || echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> "$HOME/.bashrc.local"

  # cuDNN
  sudo apt install -y libcudnn9-cuda-12 libcudnn9-dev-cuda-12

  # NVIDIA Container Toolkit
  local nct_gpg_url="https://nvidia.github.io/libnvidia-container/gpgkey"
  local nct_list_url="https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list"
  local nct_keyring="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
  local nct_sources_list="/etc/apt/sources.list.d/nvidia-container-toolkit.list"

  if [[ ! -f "$nct_sources_list" ]]; then
    curl -fsSL "$nct_gpg_url" \
      | sudo gpg --dearmor -o "$nct_keyring"
    curl -sL "$nct_list_url" \
      | sed "s#deb https://#deb [signed-by=$nct_keyring] https://#g" \
      | sudo tee "$nct_sources_list"
    sudo apt-get update
  fi

  local nct_version="1.19.0-1"
  sudo apt-get install -y \
    nvidia-container-toolkit="${nct_version}" \
    nvidia-container-toolkit-base="${nct_version}" \
    libnvidia-container-tools="${nct_version}" \
    libnvidia-container1="${nct_version}"
}

install_docker() {
  log "Installing Docker"

  local docker_gpg_url="https://download.docker.com/linux/ubuntu/gpg"
  local docker_keyring="/etc/apt/keyrings/docker.asc"
  local docker_desktop_url="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
  local docker_desktop_deb="$HOME/Downloads/docker-desktop-amd64.deb"

  sudo apt install -y gnome-terminal ca-certificates curl

  if [[ ! -f "$docker_keyring" ]]; then
    # Remove old conflicting packages (errors ignored safely)
    sudo apt remove --yes \
      docker.io docker-compose docker-compose-v2 docker-doc \
      podman-docker containerd runc 2>/dev/null || true

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "$docker_gpg_url" -o "$docker_keyring"
    sudo chmod a+r "$docker_keyring"

    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: $docker_keyring
EOF

    sudo apt update
  fi

  if ! dpkg -s docker-desktop &>/dev/null; then
    mkdir -p "$HOME/Downloads"
    wget "$docker_desktop_url" -O "$docker_desktop_deb"
    sudo apt install -y "$docker_desktop_deb"
  fi
}

install_fonts() {
  log "Installing Nerd Fonts (Hack)"

  local hack_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
  local fonts_dir="$HOME/.local/share/fonts/HackNerdFont"

  if ! ls "$fonts_dir/"*.ttf &>/dev/null; then
    mkdir -p "$HOME/.local/share/fonts"
    wget -q --show-progress "$hack_url" -O /tmp/Hack.zip
    unzip -o /tmp/Hack.zip -d "$fonts_dir"
    fc-cache -fv
  fi
}

cleanup() {
  log "Cleaning up"
  sudo apt autoremove -y
  sudo apt clean
}

validate() {
  local pass=0 fail=0

  check() {
    local desc="$1"; shift
    if "$@" &>/dev/null 2>&1; then
      printf "  \033[32m✓\033[0m %s\n" "$desc"
      pass=$(( pass + 1 ))
    else
      printf "  \033[31m✗\033[0m %s\n" "$desc"
      fail=$(( fail + 1 ))
    fi
  }

  check_cmd() { check "$1" command -v "$1"; }
  check_pkg() { check "pkg: $1" dpkg -s "$1"; }

  echo "=== Validating installation ==="

  echo ""
  echo "--- Dev tools ---"
  check_cmd git
  check_cmd make
  check_cmd gcc
  check_cmd cmake
  check_cmd jq
  check_cmd tree
  check_cmd tmux
  check_cmd nvim
  check_cmd unzip
  check_pkg libblas-dev
  check_pkg liblapack-dev
  check_pkg libopenblas-dev
  check_pkg libssl-dev

  echo ""
  echo "--- Utilities ---"
  check_cmd htop
  check_cmd ffmpeg
  check_cmd 7zz

  echo ""
  echo "--- Languages ---"
  check_cmd python3
  check_cmd pip3
  check "python3 venv" python3 -m venv --help
  check_cmd java
  check_cmd cargo
  check_cmd rustc

  echo ""
  echo "--- Shell tools ---"
  check_cmd fish
  check_cmd nu
  check_cmd starship
  check_cmd kitty
  check_cmd neofetch

  echo ""
  echo "--- Docker ---"
  check_cmd docker
  check "docker compose" docker compose version

  echo ""
  echo "--- Fonts ---"
  check "HackNerdFont files" bash -c 'ls "$HOME/.local/share/fonts/HackNerdFont/"*.ttf 2>/dev/null | grep -q .'

  if lspci | grep -i nvidia &>/dev/null; then
    echo ""
    echo "--- NVIDIA ---"
    check_cmd nvcc
    check_cmd nvidia-smi
    check_cmd nvtop
    check_pkg nvidia-container-toolkit
    check_pkg libcudnn9-cuda-12
  fi

  echo ""
  echo "================================"
  printf "%d passed, %d failed\n" "$pass" "$fail"
  echo "================================"

  [[ $fail -eq 0 ]]
}

main() {
  if [[ "${1:-}" == "--validate" ]]; then
    check_ubuntu
    validate
    return
  fi

  check_ubuntu
  update_packages
  install_dev_tools
  install_utilities
  install_languages
  install_shell_tools
  install_nvidia
  install_docker
  install_fonts
  cleanup

  echo ""
  echo "Done! Reboot your system to apply all changes, especially if you installed NVIDIA drivers or CUDA."
}

main "$@"
