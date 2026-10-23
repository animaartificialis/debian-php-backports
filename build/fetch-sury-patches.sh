#!/usr/bin/env bash
# Download Sury's debian.tar.xz for a target and extract the selected patches
# into targets/<release>/<php>/patches/ (committed, reviewed build input).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <codename>" >&2
    exit 1
fi
TARGET="${1%/}"
TARGET_DIR="$REPO_ROOT/targets/$TARGET"
if [ ! -f "$TARGET_DIR/target.conf" ]; then
    echo "ERROR: unknown target '$TARGET' ($TARGET_DIR/target.conf not found)" >&2
    echo "Available targets: $(cd "$REPO_ROOT/targets" && find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | sort -V | tr '\n' ' ')" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$TARGET_DIR/target.conf"

PATCH_DIR="$TARGET_DIR/patches"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL="$TMP_DIR/debian.tar.xz"
echo "==> Downloading $SURY_DEBIAN_TAR_URL"
curl -fsSL --retry 3 -o "$TARBALL" "$SURY_DEBIAN_TAR_URL"

TARBALL_SHA256="$(sha256sum "$TARBALL" | cut -d' ' -f1)"
if [ -z "${SURY_DEBIAN_TAR_SHA256:-}" ]; then
    echo "WARNING: SURY_DEBIAN_TAR_SHA256 is empty; computed sha256: $TARBALL_SHA256" >&2
elif [ "$TARBALL_SHA256" != "$SURY_DEBIAN_TAR_SHA256" ]; then
    echo "ERROR: sha256 mismatch for debian.tar.xz" >&2
    echo "  expected: $SURY_DEBIAN_TAR_SHA256" >&2
    echo "  actual:   $TARBALL_SHA256" >&2
    exit 1
else
    echo "==> sha256 OK: $TARBALL_SHA256"
fi

echo "==> Extracting patches: $SURY_PATCHES"
members=(debian/changelog)
for patch in $SURY_PATCHES; do
    members+=("debian/patches/$patch")
done
mkdir -p "$TMP_DIR/extract"
tar -xJf "$TARBALL" -C "$TMP_DIR/extract" "${members[@]}"

mkdir -p "$PATCH_DIR"
# Remove patches that are no longer listed, so the directory mirrors SURY_PATCHES.
for existing in "$PATCH_DIR"/*.patch; do
    [ -e "$existing" ] || continue
    if ! printf '%s\n' $SURY_PATCHES | grep -qxF "$(basename "$existing")"; then
        echo "==> Removing stale patch $(basename "$existing")"
        rm -f "$existing"
    fi
done

: > "$PATCH_DIR/series"
for patch in $SURY_PATCHES; do
    cp "$TMP_DIR/extract/debian/patches/$patch" "$PATCH_DIR/$patch"
    echo "$patch" >> "$PATCH_DIR/series"
done

# Provenance file; the download date is only refreshed when the content changes,
# so repeated runs do not produce spurious git diffs.
body="$TMP_DIR/source-body.md"
{
    echo "# Patch provenance"
    echo
    echo "- Source URL: $SURY_DEBIAN_TAR_URL"
    echo "- Tarball sha256: \`$TARBALL_SHA256\`"
    echo
    echo "## Patches"
    echo
    for patch in $SURY_PATCHES; do
        echo "- \`$patch\` sha256: \`$(sha256sum "$PATCH_DIR/$patch" | cut -d' ' -f1)\`"
    done
} > "$body"

SOURCE_MD="$PATCH_DIR/SOURCE.md"
if [ -f "$SOURCE_MD" ] && grep -v '^- Downloaded: ' "$SOURCE_MD" | cmp -s - "$body"; then
    echo "==> $SOURCE_MD unchanged"
else
    {
        sed -n '1,3p' "$body"
        echo "- Downloaded: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        sed -n '4,$p' "$body"
    } > "$SOURCE_MD"
    echo "==> Wrote $SOURCE_MD"
fi

echo
echo "==> Patches in $PATCH_DIR:"
for patch in $SURY_PATCHES; do
    echo "  $(sha256sum "$PATCH_DIR/$patch" | cut -d' ' -f1)  $patch"
done

echo
echo "==> Sury debian/changelog (first 30 lines) for review:"
head -n 30 "$TMP_DIR/extract/debian/changelog"
