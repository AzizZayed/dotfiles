$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")

$env.config.buffer_editor = "nvim"

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

$env.config.show_banner = false
neofetch
