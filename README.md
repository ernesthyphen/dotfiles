# Dotfiles

My personal dotfiles, managed using [GNU Stow](https://www.gnu.org/software/stow/) for easy symlink management across systems.

## Structure

Each directory (e.g. `bash`, `nvim`, `alacritty`) contains the config files for that tool, structured to match their expected paths from `$HOME`.

Example:
```bash
.
├── bash
│ └── .bashrc
├── nvim
│ └── .config
│ └── nvim
└── alacritty
└── .config
└── alacritty
```

### Install

Clone the repo into your home directory or somewhere convenient:

```bash
git clone git@github.com:yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```
Use stow to symlink configs into place:

```bash
stow bash
stow nvim
stow alacritty
```
To remove (unstow) a config:

```bash
stow -D nvim
```

