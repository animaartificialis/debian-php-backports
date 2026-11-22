#!/usr/bin/env bash
# Runs the reproducers in cases/ against the built packages of a PHP 5.4 target.
# Usage: tests/php54-extended/run.sh <release>/<php> [fixed|unfixed|report]
#   fixed:   every case must report FIXED (normal 5.4 targets)
#   unfixed: no case may report FIXED (-compat targets)
#   report:  only print the results
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <release>/<php> [fixed|unfixed|report]" >&2
    exit 1
fi
TARGET="${1%/}"
EXPECT="${2:-fixed}"
case "$EXPECT" in fixed|unfixed|report) ;; *) echo "ERROR: unknown mode '$EXPECT'" >&2; exit 1 ;; esac
TARGET_CONF="$REPO_ROOT/targets/$TARGET/target.conf"
[ -f "$TARGET_CONF" ] || { echo "ERROR: unknown target '$TARGET'" >&2; exit 1; }
# shellcheck source=/dev/null
source "$REPO_ROOT/build/build.conf"
# shellcheck source=/dev/null
source "$TARGET_CONF"

CONTAINER_CLI="${CONTAINER_CLI:-$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || true)}"
[ -n "$CONTAINER_CLI" ] || { echo "ERROR: neither podman nor docker was found in PATH" >&2; exit 1; }

# The 5.4 targets are built for amd64 only.
DIST_DIR="$REPO_ROOT/dist/$TARGET"
if ! compgen -G "$DIST_DIR/*.deb" > /dev/null; then
    echo "ERROR: no .deb files in $DIST_DIR; run 'make build-$TARGET' first" >&2
    exit 1
fi

"$CONTAINER_CLI" run --rm --platform linux/amd64 \
    -e DEBIAN_CODENAME="$DEBIAN_CODENAME" \
    -e APT_MIRROR="$APT_MIRROR" \
    -e APT_SECURITY_MIRROR="$APT_SECURITY_MIRROR" \
    -e APT_SECURITY_SUITE="$APT_SECURITY_SUITE" \
    -e APT_SOURCE_OPTIONS="${APT_SOURCE_OPTIONS:-}" \
    -e APT_EXTRA_CONF="${APT_EXTRA_CONF:-}" \
    -e TEST_PHP_BINARY="$TEST_PHP_BINARY" \
    -e EXPECT="$EXPECT" \
    -v "$DIST_DIR:/dist:ro" \
    -v "$SCRIPT_DIR:/tests:ro" \
    "$BASE_IMAGE" \
    bash /tests/in-container.sh
