#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO"

if [[ "${HOSTNAME%%.*}" != "pc-arch" ]]; then
    echo "Refusing to update manifests: not on pc-arch." >&2
    exit 1
fi

echo "=== REFRESHING PACKAGE MANIFESTS ==="

pacman -Qqen | sort > packages/official.txt
pacman -Qqem | sort > packages/aur.txt

if command -v flatpak >/dev/null; then
    flatpak list --app --columns=application \
        | sort > packages/flatpak.txt
else
    echo "Flatpak unavailable; leaving its manifest unchanged."
fi

wc -l packages/*.txt

echo
echo "=== CONFIGURATION CHANGES ==="
git status --short

echo
echo "=== WHITESPACE CHECK ==="
git diff --check

echo
echo "=== GITHUB SYNCHRONIZATION ==="

if git fetch --quiet origin; then
    read -r behind ahead < <(
        git rev-list --left-right --count \
            HEAD...origin/main
    )

    echo "Commits ahead of GitHub: $ahead"
    echo "Commits behind GitHub: $behind"
else
    echo "Unable to contact GitHub."
fi

echo
echo "=== MAINTENANCE CHECK COMPLETE ==="
echo "Review changes before committing or pushing."
