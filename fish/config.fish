function fish_greeting
end

# Homebrew — runs `brew shellenv` to set PATH, MANPATH, and Homebrew-specific
# variables (HOMEBREW_PREFIX, HOMEBREW_CELLAR, etc.). Equivalent to what
# .zprofile does with `eval $(/opt/homebrew/bin/brew shellenv)`.
# Guarded so this only runs on machines that have Homebrew at this path.
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# MacPorts
fish_add_path /opt/local/bin /opt/local/sbin
set -gx MANPATH /opt/local/share/man $MANPATH

# JetBrains Toolbox
fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# pipx
fish_add_path $HOME/.local/bin

# Environment
set --export VISUAL nvim
set --export EDITOR nvim
set --export MANPAGER 'nvim +Man!'

# Aliases
alias lazy-nvim 'NVIM_APPNAME=nvim-lazyvim nvim'

if test (uname) = Darwin
    function rm
        echo "fish: use trash instead of rm"
    end
end

# Starship prompt
if status is-interactive
    starship init fish | source
end
