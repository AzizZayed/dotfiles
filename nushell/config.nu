$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")

$env.config.buffer_editor = "nvim"

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")