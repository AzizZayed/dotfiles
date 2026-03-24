# dotfiles

These are my dotfiles.
I use my own script `dotfiles.py` to manage them.

## Usage

```bash
# Clone the repository
git clone https://github.com/AzizZayed/dotfiles.git

python3 dotfiles.py status # Check the status of the dotfiles
python3 dotfiles.py install # Install the dotfiles as symlinks in destination location
python3 dotfiles.py remove # Remove the symlinks of the dotfiles from the destination location, if correctly installed
python3 dotfiles.py backup # Backup the dotfiles in the desination location instead of deleting them to install the symlink
python3 dotfiles.py delete # Delete the dotfiles in the destination location
```

## TODO

<!-- TODO: -->

- Add ripgrep to ubuntu installed packages (macos too maybe)
- Add yazi to ubuntu installed packages (macos too)
- Add tailscale client to ubuntu installed packages (macos too)
- Add all path additions and env stuff for used tools so it works without needed to manually do it every install
- libfontconfig1-dev
- graphviz
