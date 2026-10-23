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
# Container engine: prefer podman if available, otherwise docker.
CONTAINER_CLI="${CONTAINER_CLI:-$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || true)}"
if [ -z "$CONTAINER_CLI" ]; then
    echo "ERROR: neither podman nor docker was found in PATH" >&2
    exit 1
fi
CONTAINER_TYPE="$(basename "$CONTAINER_CLI")"

detect_arch() {
    if [ "$CONTAINER_TYPE" = "podman" ]; then
        "$CONTAINER_CLI" info --format '{{.Host.Arch}}' 2>/dev/null || uname -m
    else
        local arch
        arch="$("$CONTAINER_CLI" info --format '{{.Architecture}}' 2>/dev/null || uname -m)"
        case "$arch" in
            x86_64) echo "amd64" ;;
            aarch64) echo "arm64" ;;
            *) echo "$arch" ;;
        esac
    fi
}

ARCH="${ARCH:-$(detect_arch)}"
DIST_ROOT=dist; [ "$ARCH" = amd64 ] || DIST_ROOT="dist-$ARCH"
DIST_DIR="$REPO_ROOT/$DIST_ROOT/$TARGET"

PLATFORM_ARG=()
if [ "$ARCH" = "amd64" ]; then
    PLATFORM_ARG=(--platform linux/amd64)
elif [ "$ARCH" = "arm64" ]; then
    PLATFORM_ARG=(--platform linux/arm64)
fi

if [ ! -f "$TARGET_CONF" ]; then
    echo "ERROR: unknown target '$TARGET' ($TARGET_CONF not found)" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$REPO_ROOT/build/build.conf"
# shellcheck source=/dev/null
source "$TARGET_CONF"
# Per-architecture mirror overrides from target.conf, e.g. APT_MIRROR_arm64 (Ubuntu keeps
# everything but amd64/i386 on ports.ubuntu.com).
v="APT_MIRROR_$ARCH"; APT_MIRROR="${!v:-$APT_MIRROR}"
v="APT_SECURITY_MIRROR_$ARCH"; APT_SECURITY_MIRROR="${!v:-$APT_SECURITY_MIRROR}"

if ! compgen -G "$DIST_DIR/*.deb" > /dev/null; then
    echo "ERROR: no .deb files in $DIST_DIR; run 'make build-$TARGET' first" >&2
    exit 1
fi

"$CONTAINER_CLI" run --rm \
    "${PLATFORM_ARG[@]}" \
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
