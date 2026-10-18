#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES="$REPO/packages"

usage() {
    cat <<USAGE
Usage: $(basename "$0") [command]

Commands:
  check       Show missing packages (default)
  install     Install missing packages after confirmation
USAGE
}

missing_packages() {
    local manifest="$1"
    local package

    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" || "$package" == \#* ]] && continue

        if ! pacman -Qq "$package" &>/dev/null; then
            printf '%s\n' "$package"
        fi
    done < "$manifest"
}

confirm() {
    local answer

    read -r -p "Proceed? [y/N] " answer
    [[ "$answer" == [yY] ]]
}

main() {
    local command="${1:-check}"
    local -a official=() foreign=() flatpaks=()

    case "$command" in
        check|install) ;;
        -h|--help|help) usage; return 0 ;;
        *) usage; return 1 ;;
    esac

    for manifest in official aur flatpak; do
        if [[ ! -f "$PACKAGES/$manifest.txt" ]]; then
            echo "Missing manifest: $manifest.txt" >&2
            return 1
        fi
    done

    command -v pacman >/dev/null ||
        { echo "This script requires Arch Linux."; return 1; }

    mapfile -t official < <(missing_packages "$PACKAGES/official.txt")
    mapfile -t foreign < <(missing_packages "$PACKAGES/aur.txt")

    if command -v flatpak >/dev/null; then
        while IFS= read -r app; do
            [[ -z "$app" || "$app" == \#* ]] && continue

            if ! flatpak info "$app" &>/dev/null; then
                flatpaks+=("$app")
            fi
        done < "$PACKAGES/flatpak.txt"
    else
        mapfile -t flatpaks < "$PACKAGES/flatpak.txt"
    fi

    echo "=== MISSING PACKAGES ==="
    echo "Official: ${#official[@]}"
    echo "Foreign:  ${#foreign[@]}"
    echo "Flatpak:  ${#flatpaks[@]}"

    printf '\nOfficial:\n'
    printf '  %s\n' "${official[@]:-none}"

    printf '\nForeign/AUR:\n'
    printf '  %s\n' "${foreign[@]:-none}"

    printf '\nFlatpak:\n'
    printf '  %s\n' "${flatpaks[@]:-none}"

    [[ "$command" == install ]] || return 0

    echo
    confirm || { echo "Cancelled."; return 0; }

    if ((${#official[@]})); then
        sudo pacman -S --needed -- "${official[@]}"
    fi

    if ((${#foreign[@]})); then
        if ! command -v paru >/dev/null; then
            echo "paru is required to restore foreign/AUR packages." >&2
            return 1
        fi

        paru -S --needed -- "${foreign[@]}"
    fi

    if ((${#flatpaks[@]})); then
        if ! command -v flatpak >/dev/null; then
            echo "Flatpak is not installed." >&2
            return 1
        fi

        flatpak install -- "${flatpaks[@]}"
    fi
}

main "$@"
