#!/usr/bin/env bash
# Seed cache/<release>/<php>/ with the sources of the newest GitHub release that has
# <release>_<php>_source.tar.gz. deb.sury.org keeps only the newest revision of each
# source, so a pinned one may only be left in our own archive. The files are not checked
# here: the build verifies every file against its pin and downloads it from the pool when
# a cached one does not match. Never fails: without a release, asset or network it just
# says so and exits 0.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${SOURCES_REPO:-animaartificialis/debian-php-backports}"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <release>/<php> [cache dir]" >&2
    exit 1
fi
TARGET="${1%/}"
ASSET="${TARGET//\//_}_source.tar.gz"
CACHE_DIR="${2:-$REPO_ROOT/cache/$TARGET}"

note() {
    echo "==> No archived sources used for $TARGET: $*"
    exit 0
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# The newest release (the API lists them newest first) that has the asset.
filter="[.[] | select(.draft | not) | select(any(.assets[]; .name == \"$ASSET\"))][0].tag_name // empty"
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    tag="$(gh api "repos/$REPO/releases?per_page=100" --jq "$filter" 2>/dev/null)" || note "cannot list the releases of $REPO"
    [ -n "$tag" ] || note "no release of $REPO has $ASSET"
    echo "==> Downloading $ASSET from release $tag"
    gh release download "$tag" -R "$REPO" -p "$ASSET" -D "$TMP_DIR" || note "download failed"
else
    command -v jq >/dev/null || note "neither an authenticated gh nor jq is available"
    tag="$(curl -fsSL --retry 3 "https://api.github.com/repos/$REPO/releases?per_page=100" | jq -r "$filter")" \
        || note "cannot list the releases of $REPO"
    [ -n "$tag" ] || note "no release of $REPO has $ASSET"
    echo "==> Downloading $ASSET from release $tag"
    curl -fsSL --retry 3 -o "$TMP_DIR/$ASSET" "https://github.com/$REPO/releases/download/$tag/$ASSET" \
        || note "download failed"
fi

mkdir -p "$TMP_DIR/x"
tar -xzf "$TMP_DIR/$ASSET" -C "$TMP_DIR/x" --no-same-owner || note "cannot unpack $ASSET"

# Flat into the cache, as the build expects them; files already there are kept.
mkdir -p "$CACHE_DIR"
count=0
for f in "$TMP_DIR/x/$TARGET"/{upstream,php-defaults,sury}/*; do
    [ -f "$f" ] || continue
    [ -e "$CACHE_DIR/$(basename "$f")" ] && continue
    cp "$f" "$CACHE_DIR/"
    echo "    archived: $(basename "$f")"
    count=$((count + 1))
done
echo "==> $count file(s) from $tag added to $CACHE_DIR"
