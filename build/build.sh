#!/usr/bin/env bash
# Host driver: build the builder image and/or the patched PHP packages for a target.
# Usage: build/build.sh <release>/<php> [image|build|all], e.g. debian10-buster/php7.3-debian
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Variables passed into the build container.
ENV_VARS=(
    VERSION_SUFFIX DEBFULLNAME DEBEMAIL DEB_BUILD_OPTIONS
    DEBIAN_CODENAME DEBIAN_VERSION BASE_IMAGE APT_MIRROR APT_SECURITY_MIRROR APT_SECURITY_SUITE APT_SOURCE_OPTIONS
    SOURCE_PACKAGE SOURCE_VERSION SOURCE_POOL_URL SOURCE_DSC_SHA256
    SURY_SOURCE_PACKAGE SURY_DEBIAN_TAR_URL SURY_DEBIAN_TAR_SHA256 SURY_PATCHES
    CHANGELOG_ENTRY TEST_PACKAGES TEST_PHP_BINARY NEW_VERSION BUILD_DEP_DSC_URL
    APT_COMPONENTS APT_BACKPORTS_SUITE BACKPORTS_PACKAGES EXTRA_DEB_URLS CONTROL_SED RULES_SED DROP_PATCHES APT_EXTRA_CONF SOURCE_FIXUP_CMD
)

usage() {
    echo "Usage: $0 <release>/<php> [image|build|all]" >&2
    echo "Available targets: $(cd "$REPO_ROOT/targets" && find . -mindepth 2 -maxdepth 2 -type d -printf '%P\n' | sort -V | tr '\n' ' ')" >&2
    exit 1
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage
TARGET="${1%/}"
ACTION="${2:-all}"
TARGET_DIR="$REPO_ROOT/targets/$TARGET"

if [ ! -f "$TARGET_DIR/target.conf" ]; then
    echo "ERROR: unknown target '$TARGET' ($TARGET_DIR/target.conf not found)" >&2
    usage
fi
if [ ! -f "$TARGET_DIR/patches/series" ]; then
    echo "ERROR: $TARGET_DIR/patches/series not found." >&2
    echo "Run first: build/fetch-sury-patches.sh $TARGET" >&2
    exit 1
fi

# shellcheck source=build.conf
source "$REPO_ROOT/build/build.conf"
# shellcheck source=/dev/null
source "$TARGET_DIR/target.conf"
# Space separated lists may be written over several lines in target.conf.
EXTRA_DEB_URLS="$(echo ${EXTRA_DEB_URLS:-})"

# Packages are built natively for the host architecture. amd64 output goes to dist/,
# any other architecture to dist-<arch>/, so the amd64 layout stays as it was.
ARCH="${ARCH:-$(podman info --format '{{.Host.Arch}}')}"
if [[ " ${ARCHES:-amd64} " != *" $ARCH "* ]]; then
    echo "ERROR: target '$TARGET' is not built for $ARCH (ARCHES=\"${ARCHES:-amd64}\")" >&2
    exit 1
fi
DIST_ROOT=dist; [ "$ARCH" = amd64 ] || DIST_ROOT="dist-$ARCH"
# Per-architecture mirror overrides from target.conf, e.g. APT_MIRROR_arm64 (Ubuntu keeps
# everything but amd64/i386 on ports.ubuntu.com).
v="APT_MIRROR_$ARCH"; APT_MIRROR="${!v:-$APT_MIRROR}"
v="APT_SECURITY_MIRROR_$ARCH"; APT_SECURITY_MIRROR="${!v:-$APT_SECURITY_MIRROR}"

IMAGE="php-backport-builder:${TARGET//\//-}-$ARCH"
DIST_DIR="$REPO_ROOT/$DIST_ROOT/$TARGET"
CACHE_DIR="$REPO_ROOT/cache/$TARGET"

build_image() {
    echo "==> Building image $IMAGE from $BASE_IMAGE"
    podman build \
        --build-arg BASE_IMAGE="$BASE_IMAGE" \
        --build-arg APT_MIRROR="$APT_MIRROR" \
        --build-arg APT_SECURITY_MIRROR="$APT_SECURITY_MIRROR" \
        --build-arg APT_SECURITY_SUITE="$APT_SECURITY_SUITE" \
        --build-arg APT_SOURCE_OPTIONS="${APT_SOURCE_OPTIONS:-}" \
        --build-arg DEBIAN_CODENAME="$DEBIAN_CODENAME" \
        --build-arg SOURCE_PACKAGE="$SOURCE_PACKAGE" \
        --build-arg BUILD_DEP_DSC_URL="${BUILD_DEP_DSC_URL:-}" \
        --build-arg APT_COMPONENTS="${APT_COMPONENTS:-main}" \
        --build-arg APT_EXTRA_CONF="${APT_EXTRA_CONF:-}" \
        --build-arg DPKG_SEARCH_WRAPPER="${DPKG_SEARCH_WRAPPER:-}" \
        --build-arg APT_BACKPORTS_SUITE="${APT_BACKPORTS_SUITE:-}" \
        --build-arg BACKPORTS_PACKAGES="${BACKPORTS_PACKAGES:-}" \
        --build-arg EXTRA_DEB_URLS="${EXTRA_DEB_URLS:-}" \
        --build-arg CONTROL_SED="${CONTROL_SED:-}" \
        -t "$IMAGE" \
        -f "$REPO_ROOT/build/container/Containerfile" \
        "$REPO_ROOT/build/container"
}

build_packages() {
    mkdir -p "$DIST_DIR" "$CACHE_DIR"

    local tmp_dir env_file var
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' RETURN
    env_file="$tmp_dir/build.env"
    for var in "${ENV_VARS[@]}"; do
        printf '%s=%s\n' "$var" "${!var:-}" >> "$env_file"
    done

    echo "==> Building packages in $IMAGE (output: $DIST_DIR)"
    # Map the calling user onto the image's builder user (uid 1000), whatever its
    # own uid is; plain keep-id only works where the host user is uid 1000 too.
    podman run --rm \
        --userns=keep-id:uid=1000,gid=1000 \
        --env-file "$env_file" \
        -v "$TARGET_DIR:/target:ro" \
        -v "$REPO_ROOT/build/container/build-in-container.sh:/usr/local/bin/build-in-container.sh:ro" \
        -v "$CACHE_DIR:/cache" \
        -v "$DIST_DIR:/out" \
        "$IMAGE"
}

START_TIME="$(date +%s)"
case "$ACTION" in
    image) build_image ;;
    build) build_packages ;;
    all) build_image; build_packages ;;
    *) usage ;;
esac
ELAPSED=$(( $(date +%s) - START_TIME ))
printf '==> Done: %s %s in %dm%02ds\n' "$TARGET" "$ACTION" $((ELAPSED / 60)) $((ELAPSED % 60))
