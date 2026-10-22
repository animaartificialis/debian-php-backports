#!/usr/bin/env bash
# Install test for built packages of one target.
# Usage: tests/install/run.sh <codename>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <codename>" >&2
    exit 1
fi
TARGET="${1%/}"
TARGET_CONF="$REPO_ROOT/targets/$TARGET/target.conf"
ARCH="${ARCH:-$(podman info --format '{{.Host.Arch}}')}"
DIST_ROOT=dist; [ "$ARCH" = amd64 ] || DIST_ROOT="dist-$ARCH"
DIST_DIR="$REPO_ROOT/$DIST_ROOT/$TARGET"

if [ ! -f "$TARGET_CONF" ]; then
    echo "ERROR: unknown target '$TARGET' ($TARGET_CONF not found)" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$REPO_ROOT/build/build.conf"
# shellcheck source=/dev/null
source "$TARGET_CONF"

if ! compgen -G "$DIST_DIR/*.deb" > /dev/null; then
    echo "ERROR: no .deb files in $DIST_DIR; run 'make build-$TARGET' first" >&2
    exit 1
fi

podman run --rm \
    -e DEBIAN_CODENAME="$DEBIAN_CODENAME" \
    -e APT_MIRROR="$APT_MIRROR" \
    -e APT_SECURITY_MIRROR="$APT_SECURITY_MIRROR" \
    -e APT_SECURITY_SUITE="$APT_SECURITY_SUITE" \
    -e APT_SOURCE_OPTIONS="${APT_SOURCE_OPTIONS:-}" \
    -e APT_COMPONENTS="${APT_COMPONENTS:-main}" \
    -e APT_EXTRA_CONF="${APT_EXTRA_CONF:-}" \
    -e TEST_PACKAGES="$TEST_PACKAGES" \
    -e TEST_PHP_BINARY="$TEST_PHP_BINARY" \
    -e SOURCE_VERSION="$SOURCE_VERSION" \
    -e VERSION_SUFFIX="$VERSION_SUFFIX" \
    -e NEW_VERSION="${NEW_VERSION:-}" \
    -v "$DIST_DIR:/dist:ro" \
    -v "$SCRIPT_DIR/in-container.sh:/test.sh:ro" \
    "$BASE_IMAGE" \
    bash /test.sh
