# Dotfiles

Personal Arch Linux configuration and desktop recovery toolkit, managed with [GNU Stow](https://www.gnu.org/software/stow/).

The goal is to get a familiar, working environment back quickly after a reinstall—not to clone every detail of an old installation. **`pc-arch` is the source of truth** for tracked configuration and package inventories.

## What's in the repository?

```text
.
├── bash/                   # Shell configuration
├── alacritty/              # Terminal configuration
├── fastfetch/              # System information display
├── kde/                    # pc-arch-specific KDE configuration
├── packages/
│   ├── essential.txt       # Minimal working desktop package selection
│   ├── official.txt        # Full explicitly installed official package inventory
│   ├── aur.txt             # Full foreign/AUR package inventory
│   └── flatpak.txt         # Full Flatpak application inventory
└── scripts/
    ├── bootstrap.sh        # Check or install packages
    ├── deploy.sh           # Preview and apply Stow profiles
    └── maintain.sh         # Refresh inventories and check repository status
```

The directories above are Stow packages: their contents mirror the paths they should occupy beneath `$HOME`.

## Fresh Arch installation: quick recovery

Start with a working Arch installation, an internet connection and a user account with `sudo` access. Install Git first if it isn't already present:

```bash
sudo pacman -S --needed git
```

Clone over HTTPS so recovery **doesn't depend on having an SSH key ready**:

```bash
git clone https://github.com/ernesthyphen/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 1. Install the essentials

```bash
bash scripts/bootstrap.sh check-essential
bash scripts/bootstrap.sh essential
```

The essential selection covers a KDE Plasma desktop, networking, audio, core applications, terminal tools and fonts. The installation command shows what's missing and **asks before installing**.

For a new graphical installation, finish configuring and enabling the relevant system services (such as NetworkManager and SDDM) as required. Package installation alone does not complete an Arch install.

### 2. Deploy configuration

For another computer, a test VM or a fresh machine that isn't yet configured as `pc-arch`:

```bash
bash scripts/deploy.sh check shared
bash scripts/deploy.sh apply shared
```

The **shared** profile installs the `bash`, `alacritty` and `fastfetch` configurations.

For the actual `pc-arch` desktop, once its KDE environment is ready:

```bash
bash scripts/deploy.sh check desktop
bash scripts/deploy.sh apply desktop
```

The **desktop** profile adds KDE settings, shortcuts and window rules. Applying it is intentionally restricted to a host named `pc-arch`; don't deploy those machine-specific rules on a laptop or VM without reviewing them separately.

`check` is a dry run. `apply` asks for confirmation and renames conflicting regular files to timestamped `.pre-stow-*.bak` copies before Stow operates. Unexpected conflicts are not silently overwritten. Review the preview and any resulting backups.

### 3. Restore optional applications

When the basic desktop is working, inspect what's absent from the historical full package inventory:

```bash
bash scripts/bootstrap.sh check
```

Optionally install missing packages from the full official, AUR and Flatpak inventories:

```bash
bash scripts/bootstrap.sh install
```

**Don't treat the full inventories as a mandatory reinstall list.** They record what was installed on `pc-arch`, not what every replacement system needs. The full-install path may need `paru`/AUR setup and a configured Flathub remote; review packages and prompts carefully. The essential-install and shared-deployment paths have been tested in a clean Arch VM, while full restoration remains a more manual, selective step.

Brave is installed separately as an optional AUR application; browser settings are recovered through Brave Sync. Firefox is included among the essentials as a fallback.

## Normal maintenance (`pc-arch` only)

After meaningful configuration or package changes:

```bash
cd ~/dotfiles
bash scripts/maintain.sh
```

This refreshes the official, AUR and Flatpak inventories from `pc-arch`, runs Git status and whitespace checks, and reports whether the local branch is ahead of or behind GitHub. 

Review what changed, then commit and push deliberately:

```bash
git diff
git add <reviewed-paths>
git commit -m "Describe the change"
git push
```

KDE may rewrite configuration files while running. Inspect those diffs before committing, especially shortcut and window-rule changes.

## Scope and limitations

This is a **configuration and package recovery project**, not a disk image or full-system backup. Hardware-specific setup (drivers, monitor layout, mounts and local services), user data and account authentication may still require separate recovery work.

The shared profile is intended to be portable. The KDE desktop profile is deliberately tailored to `pc-arch`.
