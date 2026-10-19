#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HOME"
IGNORE='\.bak$|\.backup$|\.orig$|\.sw[po]$|~$|\.tmp$'
SHARED=(bash alacritty fastfetch)
DESKTOP=("${SHARED[@]}" kde)

usage() {
    cat <<'USAGE'
Usage: deploy.sh check <shared|desktop>
       deploy.sh apply <shared|desktop>

check  Preview Stow operations and report conflicting files (no changes).
apply  Back up conflicting regular files, then deploy after confirmation.

The desktop profile includes pc-arch-specific KDE window rules. Do not
apply it to a VM or another machine without reviewing those rules.
USAGE
}

ignored() {
    [[ "$1" =~ (\.bak$|\.backup$|\.orig$|\.sw[po]$|~$|\.tmp$) ]]
}

main() {
    if (( $# != 2 )); then usage; return 2; fi
    local action="$1" profile="$2"
    local -a packages=() conflicts=() unsupported=()
    local package source relative destination resolved backup answer
    local stamp

    case "$action" in check|apply) ;; *) usage; return 2 ;; esac
    case "$profile" in
        shared) packages=("${SHARED[@]}") ;;
        desktop) packages=("${DESKTOP[@]}") ;;
        *) usage; return 2 ;;
    esac
    if [[ "$action" == apply && "$profile" == desktop ]]; then
        local host_name
        host_name="$(< /proc/sys/kernel/hostname)"
        if [[ "$host_name" != pc-arch ]]; then
            echo "Desktop profile is restricted to pc-arch (current: $host_name)." >&2
            echo 'Use the shared profile on this machine.' >&2
            return 1
        fi
    fi
    command -v stow >/dev/null || { echo 'GNU Stow is required.' >&2; return 1; }
    for package in "${packages[@]}"; do
        [[ -d "$REPO/$package" ]] || { echo "Missing package: $package" >&2; return 1; }
    done

    echo "Action: $action | Profile: $profile | Target: $TARGET"
    echo "Packages: ${packages[*]}"

    # Discover conflicts at leaf paths without following directory symlinks.
    # We only auto-backup ordinary files; unexpected links/directories abort.
    for package in "${packages[@]}"; do
        while IFS= read -r -d '' source; do
            relative="${source#"$REPO/$package/"}"
            ignored "$relative" && continue
            destination="$TARGET/$relative"
            if [[ -e "$destination" || -L "$destination" ]]; then
                resolved="$(readlink -f -- "$destination" 2>/dev/null || true)"
                if [[ "$resolved" == "$(readlink -f -- "$source")" ]]; then
                    continue
                elif [[ -f "$destination" && ! -L "$destination" ]]; then
                    conflicts+=("$destination")
                else
                    unsupported+=("$destination")
                fi
            fi
        done < <(find "$REPO/$package" \( -type f -o -type l \) -print0)
    done

    if ((${#conflicts[@]})); then
        printf '\nRegular files needing backup:\n'
        printf '  %s\n' "${conflicts[@]}"
    fi
    if ((${#unsupported[@]})); then
        printf '\nCannot safely auto-resolve these paths:\n' >&2
        printf '  %s\n' "${unsupported[@]}" >&2
        return 1
    fi

    if [[ "$action" == check ]]; then
        echo; echo 'Stow dry-run:'
        stow --dir="$REPO" --target="$TARGET" --ignore="$IGNORE" \
            --restow --simulate --verbose=2 "${packages[@]}"
        return
    fi

    if ((${#conflicts[@]})); then
        printf '\nThese %d files will be renamed to timestamped *.bak files.\n' "${#conflicts[@]}"
    else
        echo 'No regular-file conflicts detected.'
    fi
    read -r -p 'Apply Stow deployment? [y/N] ' answer || return 1
    [[ "$answer" == [yY] ]] || { echo 'Cancelled.'; return 0; }

    stamp="$(date +%Y%m%d-%H%M%S)"
    for destination in "${conflicts[@]}"; do
        backup="${destination}.pre-stow-${stamp}.bak"
        [[ ! -e "$backup" && ! -L "$backup" ]] || {
            echo "Backup already exists: $backup" >&2; return 1;
        }
    done
    for destination in "${conflicts[@]}"; do
        backup="${destination}.pre-stow-${stamp}.bak"
        mv -- "$destination" "$backup"
        echo "Backed up: $backup"
    done

    # Refuse to apply if Stow finds any conflicts our leaf check missed.
    if ! stow --dir="$REPO" --target="$TARGET" --ignore="$IGNORE" \
        --restow --simulate "${packages[@]}"; then
        echo 'Stow still reports conflicts. Deployment aborted; backups retained.' >&2
        echo 'Restore the backed-up files manually after resolving the conflict.' >&2
        return 1
    fi
    stow --dir="$REPO" --target="$TARGET" --ignore="$IGNORE" \
        --restow "${packages[@]}"
    echo 'Deployment complete.'
}

main "$@"
