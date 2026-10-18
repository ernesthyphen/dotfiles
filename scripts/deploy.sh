#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HOME"

SHARED=(bash alacritty fastfetch)
DESKTOP=("${SHARED[@]}" kde)

usage() {
    echo "Usage: $0 <shared|desktop> [--apply]"
    echo
    echo "Without --apply, runs a dry-run only."
}

main() {
    local profile="${1:-}"
    local mode="${2:-}"
    local -a packages

    case "$profile" in
        shared)  packages=("${SHARED[@]}") ;;
        desktop) packages=("${DESKTOP[@]}") ;;
        *) usage; return 1 ;;
    esac

    if [[ -n "$mode" && "$mode" != "--apply" ]]; then
        usage
        return 1
    fi

    command -v stow >/dev/null || {
        echo "GNU Stow is not installed." >&2
        return 1
    }

    echo "Profile: $profile"
    echo "Target:  $TARGET"
    echo "Packages: ${packages[*]}"
    echo

    for package in "${packages[@]}"; do
        [[ -d "$REPO/$package" ]] || {
            echo "Missing Stow package: $package" >&2
            return 1
        }
    done

    if [[ "$mode" == "--apply" ]]; then
        echo "Applying configuration..."
        stow --dir="$REPO" --target="$TARGET" \
            --ignore='\.bak$|\.backup$|\.orig$|\.sw[po]$|~$|\.tmp$' \
            --restow "${packages[@]}"
    else
        echo "Dry-run:"
        stow --dir="$REPO" --target="$TARGET" \
            --ignore='\.bak$|\.backup$|\.orig$|\.sw[po]$|~$|\.tmp$' \
            --restow --simulate --verbose=2 "${packages[@]}"
    fi
}

main "$@"
