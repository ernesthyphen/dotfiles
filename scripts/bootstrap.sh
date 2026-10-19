#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES="$REPO/packages"

usage() {
    cat <<USAGE
Usage: $(basename "$0") [command]

Commands:
  check             Show missing packages from full inventory (default)
  check-essential   Show missing essential packages
  essential         Install missing essential packages after confirmation
  install           Install missing packages from full inventory after confirmation
  help              Show this help
USAGE
}

confirm() {
    local answer
    read -r -p "$1 [y/N] " answer || return 1
    [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

require_manifest() {
    [[ -f "$PACKAGES/$1" ]] || {
        printf 'Missing manifest: %s\n' "$PACKAGES/$1" >&2
        return 1
    }
}

missing_pacman_packages() {
    local package
    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" == \#* ]] && continue
        if ! pacman -Qq -- "$package" &>/dev/null; then
            printf '%s\n' "$package"
        fi
    done < "$1"
}

missing_flatpaks() {
    local app
    while IFS= read -r app || [[ -n "$app" ]]; do
        [[ -z "$app" || "$app" == \#* ]] && continue
        if ! command -v flatpak >/dev/null 2>&1 || ! flatpak info "$app" &>/dev/null; then
            printf '%s\n' "$app"
        fi
    done < "$1"
}

show_packages() {
    local heading="$1"
    shift
    printf '\n%s:\n' "$heading"
    if (($#)); then
        printf '  %s\n' "$@"
    else
        echo '  none'
    fi
}

bootstrap_paru() {
    local build_dir
    command -v git >/dev/null 2>&1 || { echo 'git is required.' >&2; return 1; }
    command -v makepkg >/dev/null 2>&1 || { echo 'makepkg is required.' >&2; return 1; }
    command -v less >/dev/null 2>&1 || { echo 'less is required to review PKGBUILD.' >&2; return 1; }

    build_dir="$(mktemp -d)"
    (
        trap 'rm -rf -- "$build_dir"' EXIT
        git clone -- https://aur.archlinux.org/paru.git "$build_dir/paru"
        cd "$build_dir/paru"
        echo 'Review the paru PKGBUILD before installing.'
        less PKGBUILD
        confirm 'Build and install paru?' || { echo 'Cancelled.'; return 1; }
        makepkg -si
    )
    command -v paru >/dev/null 2>&1 || {
        echo 'paru installation did not complete.' >&2
        return 1
    }
}

main() {
    local action="${1:-check}"
    local mode='full'
    local do_install=false
    local official_file
    local -a official=() foreign=() flatpaks=()

    (($# <= 1)) || { usage >&2; return 2; }

    case "$action" in
        check)           ;;
        check-essential) mode='essential' ;;
        essential)       mode='essential'; do_install=true ;;
        install)         do_install=true ;;
        help|-h|--help)  usage; return 0 ;;
        *)               usage >&2; return 2 ;;
    esac

    command -v pacman >/dev/null 2>&1 || {
        echo 'This script requires Arch Linux with pacman.' >&2
        return 1
    }

    if [[ "$mode" == essential ]]; then
        official_file='essential.txt'
    else
        official_file='official.txt'
        require_manifest 'aur.txt'
        require_manifest 'flatpak.txt'
    fi
    require_manifest "$official_file"

    mapfile -t official < <(missing_pacman_packages "$PACKAGES/$official_file")

    if [[ "$mode" == full ]]; then
        mapfile -t foreign < <(missing_pacman_packages "$PACKAGES/aur.txt")
        mapfile -t flatpaks < <(missing_flatpaks "$PACKAGES/flatpak.txt")
    fi

    printf '=== MISSING PACKAGES (%s) ===\n' "$mode"
    printf 'Official: %d\nForeign:  %d\nFlatpak:  %d\n' \
        "${#official[@]}" "${#foreign[@]}" "${#flatpaks[@]}"
    show_packages 'Official' "${official[@]}"
    show_packages 'Foreign/AUR' "${foreign[@]}"
    show_packages 'Flatpak' "${flatpaks[@]}"

    [[ "$do_install" == true ]] || return 0
    if (( ${#official[@]} + ${#foreign[@]} + ${#flatpaks[@]} == 0 )); then
        echo 'Nothing to install.'
        return 0
    fi

    echo
    confirm 'Install the listed packages?' || { echo 'Cancelled.'; return 0; }

    if ((${#official[@]})); then
        sudo pacman -S --needed -- "${official[@]}"
    fi

    if ((${#foreign[@]})); then
        if ! command -v paru >/dev/null 2>&1; then
            echo 'paru is not installed; bootstrapping from AUR.'
            bootstrap_paru
        fi
        paru -S --needed -- "${foreign[@]}"
    fi

    if ((${#flatpaks[@]})); then
        command -v flatpak >/dev/null 2>&1 || {
            echo 'Flatpak is missing. Install it before restoring Flatpak apps.' >&2
            return 1
        }
        if ! flatpak remotes --columns=name | grep -qx 'flathub'; then
            echo 'Flathub remote is not configured.' >&2
            echo 'Configure it first: sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo' >&2
            return 1
        fi
        flatpak install flathub -- "${flatpaks[@]}"
    fi

    echo 'Package recovery completed.'
}

main "$@"
