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

# == Dev Tools ==

install_build_tools() {
  log "Installing build tools"
  sudo apt install -y \
    build-essential make cmake gcc llvm
}

install_cli_tools() {
  log "Installing CLI tools"
  sudo apt install -y \
    git curl wget vim \
    jq tree net-tools whois \
    tmux unzip gnupg2 pciutils
}

install_math_libs() {
  log "Installing math and crypto libraries"
  sudo apt install -y \
    libblas-dev liblapack-dev libopenblas-dev libssl-dev
}

install_neovim() {
  log "Installing Neovim"
  sudo apt install -y tree-sitter-cli
  snap list nvim &>/dev/null || sudo snap install nvim --classic
}

install_claude_cli() {
  log "Installing Claude CLI"
  command -v claude &>/dev/null || curl -fsSL https://claude.ai/install.sh | bash
}

# == Utilities ==

install_system_utils() {
  log "Installing system utilities"
  sudo apt install -y \
    htop solaar speedtest-cli neofetch
}

install_media_tools() {
  log "Installing media tools"
  sudo apt install -y ffmpeg 7zip
}

# == Languages ==

install_python() {
  log "Installing Python"
  sudo apt install -y \
    python3 python3-pip python3-venv python3-virtualenv
}

install_java() {
  log "Installing Java"
  sudo apt install -y openjdk-25-jdk
}

install_node() {
  log "Installing Node.js"
  snap list node &>/dev/null || sudo snap install node --classic
  # sudo apt install -y yarn
}

install_rust() {
  log "Installing Rust"
  if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    # don't forget .zshrc.local if user is using zsh, and env.nu if using nushell
    grep -qxF 'source $HOME/.cargo/env' "$HOME/.bashrc.local" \
      || echo 'source $HOME/.cargo/env' >> "$HOME/.bashrc.local"
  fi
}

# == Shell & Terminal ==

install_fish() {
  log "Installing Fish shell"
  if ! command -v fish &>/dev/null; then
    sudo apt install -y fish
    if ! grep -qF "$(command -v fish)" /etc/shells; then
      echo "$(command -v fish)" | sudo tee -a /etc/shells
    fi
  fi
}

install_nushell() {
  log "Installing Nushell"
  if ! command -v nu &>/dev/null; then
    sudo snap install nushell --classic
    # snap may not update PATH in the current shell, fall back to known snap path
    local nu_path
    nu_path="$(command -v nu 2>/dev/null || echo /snap/bin/nu)"
    if [[ -x "$nu_path" ]] && ! grep -qF "$nu_path" /etc/shells; then
      echo "$nu_path" | sudo tee -a /etc/shells
    fi
  fi
}

install_starship() {
  log "Installing Starship prompt"
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi
}

install_kitty() {
  log "Installing Kitty terminal"
  if ! command -v kitty &>/dev/null; then
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    mkdir -p ~/.local/bin ~/.local/share/applications ~/.config
    ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
    cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
    sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
      ~/.local/share/applications/kitty*.desktop
    sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" \
      ~/.local/share/applications/kitty*.desktop
    echo 'kitty.desktop' > ~/.config/xdg-terminals.list
  fi
}

# == NVIDIA ==

install_nvidia() {
  if ! lspci | grep -i nvidia &>/dev/null; then
    log "No NVIDIA GPU detected, skipping NVIDIA driver and CUDA installation"
    return
  fi

  log "NVIDIA GPU detected — installing drivers and utilities"
  sudo apt install -y nvidia-settings nvtop

  # CUDA — build repo URL from OS version and architecture
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

  # don't forget .zshrc.local if user is using zsh, and env.nu if using nushell
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
    curl -fsSL "$nct_gpg_url" | sudo gpg --dearmor -o "$nct_keyring"
    curl -sL "$nct_list_url" \
      | sed "s#deb https://#deb [signed-by=$nct_keyring] https://#g" \
      | sudo tee "$nct_sources_list"
    sudo apt-get update
  fi

  sudo apt-get install -y \
    nvidia-container-toolkit \
    nvidia-container-toolkit-base \
    libnvidia-container-tools \
    libnvidia-container1
}

# == Docker ==

install_docker() {
  log "Installing Docker"

  local docker_gpg_url="https://download.docker.com/linux/ubuntu/gpg"
  local docker_keyring="/etc/apt/keyrings/docker.asc"

  sudo apt install -y ca-certificates

  if [[ ! -f "$docker_keyring" ]]; then
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
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  if ! sudo systemctl is-active --quiet docker; then
    sudo systemctl start docker
  fi

  getent group docker &>/dev/null || sudo groupadd docker
  sudo usermod -aG docker "$USER"

  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service
}

# == Fonts ==

install_fonts() {
  log "Installing Nerd Fonts (Hack)"

  local hack_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
  local fonts_dir="$HOME/.local/share/fonts/HackNerdFont"

  if ! ls "$fonts_dir/"*.ttf &>/dev/null; then
    sudo apt install -y fontconfig
    mkdir -p "$fonts_dir"
    wget -q --show-progress "$hack_url" -O /tmp/Hack.zip
    unzip -o /tmp/Hack.zip -d "$fonts_dir"
    fc-cache -fv
  fi
}

# == Dotfiles ==

install_dotfiles() {
  log "Installing dotfiles"

  local repo_url="https://github.com/AzizZayed/dotfiles.git"
  local repo_dir="$HOME/dotfiles"

  if [[ -d "$repo_dir" ]]; then
    log "Dotfiles repo already exists, pulling latest changes"
    git -C "$repo_dir" pull else git clone "$repo_url" "$repo_dir"
  fi

  (cd "$repo_dir" && python3 dotfiles.py install --force)
  git -C "$repo_dir" remote set-url origin "git@github.com:AzizZayed/dotfiles.git"
}

# == Cleanup ==

cleanup() {
  log "Cleaning up"
  sudo apt autoremove -y
  sudo apt clean
}

# == Validation ==

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
  echo "--- Build tools ---"
  check_cmd make
  check_cmd gcc
  check_cmd cmake

  echo ""
  echo "--- CLI tools ---"
  check_cmd git
  check_cmd jq
  check_cmd tree
  check_cmd tmux
  check_cmd unzip

  echo ""
  echo "--- Math/crypto libs ---"
  check_pkg libblas-dev
  check_pkg liblapack-dev
  check_pkg libopenblas-dev
  check_pkg libssl-dev

  echo ""
  echo "--- Neovim ---"
  check_cmd nvim

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
  check_cmd node
  check_cmd yarn
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

# == Main ==

main() {
  if [[ "${1:-}" == "--validate" ]]; then
    check_ubuntu
    validate
    return
  fi

  check_ubuntu
  update_packages

  install_build_tools
  install_cli_tools
  install_math_libs
  install_neovim
  install_claude_cli

  install_system_utils
  install_media_tools

  install_python
  install_java
  install_node
  install_rust

  install_fish
  install_nushell
  install_starship
  install_kitty

  install_nvidia
  install_docker
  install_fonts
  install_dotfiles

  # install devcontainer CLI
  sudo npm install -g @devcontainers/cli

  cleanup

  echo ""
  echo "Done! Reboot your system to apply all changes, especially if you installed NVIDIA drivers or CUDA."
}

main "$@"
