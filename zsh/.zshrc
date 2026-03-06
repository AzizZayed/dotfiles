# User configuration

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'

export XDG_CONFIG_HOME="$HOME/.config"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

if [[ $(uname) == "Darwin" ]]; then
    rm () {
        echo "zsh: use trash instead of rm"
    }
fi

# C/C++
export SDKROOT=$(xcrun -show-sdk-path)
export CFLAGS="-isysroot $(xcrun -show-sdk-path) ${CFLAGS}"
export CXXFLAGS="-isysroot $(xcrun -show-sdk-path) ${CXXFLAGS}"
export LDFLAGS="-L$(xcrun -show-sdk-path)/usr/lib ${LDFLAGS}"

# SDKMAN!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Add tester scripts to path
export PATH="$PATH:/Users/aziz/dev/automation/scripts"

# Kitty terminal binaries (kitten, etc.)
export PATH="$PATH:/Applications/kitty.app/Contents/MacOS"

# Java Verisons
alias javas="/usr/libexec/java_home --verbose"
jset() {
  export JAVA_HOME="$(/usr/libexec/java_home -v "$1")" || return 1
  echo "JAVA_HOME=$JAVA_HOME"
  java -version
}

alias java25='jset 25'
alias java21='jset 21'
alias java17='jset 17'
alias java11='jset 11'

# Add LLVM tools
PATH="$PATH:/opt/homebrew/opt/llvm/bin"

# ccache
PATH="$PATH:/opt/homebrew/opt/ccache/libexec"

# Created by `pipx` on 2024-09-05 00:33:25
export PATH="$PATH:/Users/aziz/.local/bin"

[ -f "/Users/aziz/.ghcup/env" ] && . "/Users/aziz/.ghcup/env" # ghcup-env

alias lazy-nvim='NVIM_APPNAME=nvim-lazyvim nvim' # LazyVim

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(starship init zsh)"
neofetch
