#!/usr/bin/env bash
# Host driver: build the builder image and/or the patched PHP packages for a target.
# Usage: build/build.sh <release>/<php> [image|build|all], e.g. debian8-jessie/php5.6-debian
#
# Packages go to dist/<release>/<php>/ (dist-<arch>/ for architectures other than amd64).
# The amd64 build also puts the exact sources it used into sources/<release>/<php>/
# (kept out of dist/, which the apt repository is made from).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Variables passed into the build container.
ENV_VARS=(
    VERSION_SUFFIX DEBFULLNAME DEBEMAIL DEB_BUILD_OPTIONS
    DEBIAN_CODENAME DEBIAN_VERSION BASE_IMAGE APT_MIRROR APT_SECURITY_MIRROR APT_SECURITY_SUITE APT_SOURCE_OPTIONS
    SOURCE_PACKAGE SOURCE_VERSION SOURCE_POOL_URL SOURCE_DSC_SHA256
    SURY_SOURCE_PACKAGE SURY_DEBIAN_TAR_URL SURY_DEBIAN_TAR_SHA256 SURY_PATCHES
    CHANGELOG_ENTRY TEST_PACKAGES TEST_PHP_BINARY NEW_VERSION BUILD_DEP_DSC_URL
    APT_COMPONENTS APT_BACKPORTS_SUITE BACKPORTS_PACKAGES EXTRA_DEB_URLS EXTRA_DEB_BUILD_ONLY CONTROL_SED RULES_SED DROP_PATCHES APT_EXTRA_CONF SOURCE_FIXUP_CMD
    PHP_COMMON_SOURCE_VERSION PHP_COMMON_VERSION
)

usage() {
    echo "Usage: $0 <release>/<php> [image|build|all]" >&2
    echo "Available targets: $(cd "$REPO_ROOT/targets" && find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | sort -V | tr '\n' ' ')" >&2
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

# shellcheck source=build.conf
source "$REPO_ROOT/build/build.conf"
# shellcheck source=/dev/null
source "$TARGET_DIR/target.conf"
# A variant (BASE_TARGET, below) may have no patches of its own.
if [ -z "${BASE_TARGET:-}" ] && [ ! -f "$TARGET_DIR/patches/series" ]; then
    echo "ERROR: $TARGET_DIR/patches/series not found." >&2
    echo "Run first: build/fetch-sury-patches.sh $TARGET" >&2
    exit 1
fi
# Space separated lists may be written over several lines in target.conf.
set -f
EXTRA_DEB_URLS="$(echo ${EXTRA_DEB_URLS:-})"
EXTRA_DEB_BUILD_ONLY="$(echo ${EXTRA_DEB_BUILD_ONLY:-})"
# EXTRA_DEB_BUILD_ONLY names packages of EXTRA_DEB_URLS that are installed for the build
# but not shipped (e.g. -dev packages no built package depends on).
extra_names=""
for url in $EXTRA_DEB_URLS; do
    name="$(basename "$url" | sed 's/%2B/+/g')"
    extra_names+=" ${name%%_*}"
done
for name in $EXTRA_DEB_BUILD_ONLY; do
    if [[ "$extra_names " != *" $name "* ]]; then
        echo "ERROR: EXTRA_DEB_BUILD_ONLY names '$name', which is not a package in EXTRA_DEB_URLS of $TARGET" >&2
        exit 1
    fi
done
set +f
# BASE_TARGET (set by target.conf, which also sources the base target's target.conf): a
# variant of another target. The build applies the base target's patches/series first and
# then the variant's own patches/series (if it has one), so the base patches are not
# copied. EXCLUDE_BASE_PATCHES names base patches the variant leaves out.
PATCH_DIR="$TARGET_DIR/patches"
BASE_TARGET_DIR=""
if [ -n "${BASE_TARGET:-}" ]; then
    BASE_TARGET_DIR="$REPO_ROOT/targets/$BASE_TARGET"
    if [ ! -f "$BASE_TARGET_DIR/patches/series" ]; then
        echo "ERROR: BASE_TARGET '$BASE_TARGET' of $TARGET has no patches/series" >&2
        exit 1
    fi
    for p in ${EXCLUDE_BASE_PATCHES:-}; do
        if ! grep -qxF "$p" "$BASE_TARGET_DIR/patches/series"; then
            echo "ERROR: EXCLUDE_BASE_PATCHES names '$p', which is not in $BASE_TARGET/patches/series" >&2
            exit 1
        fi
    done
elif [ -n "${EXCLUDE_BASE_PATCHES:-}" ]; then
    echo "ERROR: EXCLUDE_BASE_PATCHES is set, but $TARGET has no BASE_TARGET" >&2
    exit 1
fi
# The php-common rebuild (pins in build.conf) only happens for targets that ask for it.
if [ "${REBUILD_PHP_COMMON:-0}" != 1 ]; then
    PHP_COMMON_SOURCE_VERSION=""; PHP_COMMON_DSC_SHA256=""; PHP_COMMON_VERSION=""
fi

# Container engine: prefer podman if available, otherwise docker.
CONTAINER_CLI="${CONTAINER_CLI:-$(command -v podman 2>/dev/null || command -v docker 2>/dev/null || true)}"
if [ -z "$CONTAINER_CLI" ]; then
    echo "ERROR: neither podman nor docker was found in PATH" >&2
    exit 1
fi
CONTAINER_TYPE="$(basename "$CONTAINER_CLI")"

# Host architecture in Debian naming. podman already reports amd64/arm64; docker and the
# uname fallback report x86_64/aarch64.
detect_arch() {
    local arch
    if [ "$CONTAINER_TYPE" = "podman" ]; then
        arch="$("$CONTAINER_CLI" info --format '{{.Host.Arch}}' 2>/dev/null || uname -m)"
    else
        arch="$("$CONTAINER_CLI" info --format '{{.Architecture}}' 2>/dev/null || uname -m)"
    fi
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

# Packages are built natively for the host architecture (or fallback to first target arch).
# amd64 output goes to dist/, any other architecture to dist-<arch>/, so the amd64 layout stays as it was.
if [ -z "${ARCH:-}" ]; then
    ARCH="$(detect_arch)"
    if [[ " ${ARCHES:-amd64} " != *" $ARCH "* ]]; then
        ARCH="${ARCHES:-amd64}"
        ARCH="${ARCH%% *}"
    fi
fi
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
# Not dist-sources/: dist-*/ directories are taken for architectures.
SOURCES_DIR="$REPO_ROOT/sources/$TARGET"

PLATFORM_ARG=()
if [ "$ARCH" = "amd64" ]; then
    PLATFORM_ARG=(--platform linux/amd64)
elif [ "$ARCH" = "arm64" ]; then
    PLATFORM_ARG=(--platform linux/arm64)
fi

build_image() {
    echo "==> Building image $IMAGE from $BASE_IMAGE using $CONTAINER_TYPE ($ARCH)"
    # The build context is a copy of build/container/ plus the source files the image
    # build needs that an earlier package build left in cache/<target>/ (the build-dep
    # .dsc, the php-defaults source): packages.sury.org keeps only the current revision,
    # so a cached file may be the only copy. A bind mount would be podman-only.
    local ctx f
    ctx="$(mktemp -d)"
    trap 'rm -rf "$ctx"' RETURN
    cp -a "$REPO_ROOT/build/container/." "$ctx/"
    mkdir -p "$ctx/cache" "$CACHE_DIR"
    shopt -s nullglob
    for f in "$CACHE_DIR/$(basename "${BUILD_DEP_DSC_URL:-none}" | sed 's/%2B/+/g')" \
             "$CACHE_DIR/php-defaults_${PHP_COMMON_SOURCE_VERSION:-none}".*; do
        [ -f "$f" ] && cp "$f" "$ctx/cache/"
    done
    shopt -u nullglob
    "$CONTAINER_CLI" build \
        "${PLATFORM_ARG[@]}" \
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
        --build-arg PHP_COMMON_SOURCE_VERSION="${PHP_COMMON_SOURCE_VERSION:-}" \
        --build-arg PHP_COMMON_DSC_SHA256="${PHP_COMMON_DSC_SHA256:-}" \
        --build-arg PHP_COMMON_VERSION="${PHP_COMMON_VERSION:-}" \
        --build-arg DEBFULLNAME="$DEBFULLNAME" \
        --build-arg DEBEMAIL="$DEBEMAIL" \
        -t "$IMAGE" \
        -f "$ctx/Containerfile" \
        "$ctx"
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

    # A variant gets one patch directory: the base target's patches without the ones in
    # EXCLUDE_BASE_PATCHES, then its own, with one series listing both in that order.
    local target_mount="$TARGET_DIR"
    if [ -n "$BASE_TARGET_DIR" ]; then
        target_mount="$tmp_dir/target"
        mkdir -p "$target_mount/patches"
        cp -a "$BASE_TARGET_DIR/patches/." "$target_mount/patches/"
        local f p
        for p in ${EXCLUDE_BASE_PATCHES:-}; do
            rm -f "$target_mount/patches/$p"
            sed -i "\|^${p}\$|d" "$target_mount/patches/series"
            echo "==> Leaving out base patch $p"
        done
        if [ -f "$PATCH_DIR/series" ]; then
            for f in "$PATCH_DIR"/*; do
                case "$(basename "$f")" in series|SOURCE.md) continue ;; esac
                if [ -e "$BASE_TARGET_DIR/patches/$(basename "$f")" ]; then
                    echo "ERROR: $(basename "$f") is in both $BASE_TARGET and $TARGET" >&2
                    exit 1
                fi
                cp -a "$f" "$target_mount/patches/"
            done
            cat "$PATCH_DIR/series" >> "$target_mount/patches/series"
        fi
        cp "$TARGET_DIR/target.conf" "$target_mount/"
    fi

    echo "==> Building packages in $IMAGE using $CONTAINER_TYPE (output: $DIST_DIR)"
    local run_opts=("${PLATFORM_ARG[@]}")
    if [ "$CONTAINER_TYPE" = "podman" ]; then
        # Map the calling user onto the image's builder user (uid 1000), whatever its
        # own uid is; plain keep-id only works where the host user is uid 1000 too.
        run_opts+=(--userns=keep-id:uid=1000,gid=1000)
    else
        # Older glibc / GNU Make 4.x has a known bug with jobserver pipes closing when
        # file descriptor limits are set to 1048576 (default in Docker Desktop).
        run_opts+=(--user 1000:1000 --ulimit nofile=1024:65536)
    fi

    "$CONTAINER_CLI" run --rm \
        "${run_opts[@]}" \
        --env-file "$env_file" \
        -v "$target_mount:/target:ro" \
        -v "$REPO_ROOT/build/container/build-in-container.sh:/usr/local/bin/build-in-container.sh:ro" \
        -v "$CACHE_DIR:/cache" \
        -v "$DIST_DIR:/out" \
        "$IMAGE"
}

sha256_of() {
    sha256sum "$1" | cut -d' ' -f1
}

# copy_dsc <dsc name> <expected dsc sha256> <dest dir>: copy a source package (the .dsc and
# every file in its Checksums-Sha256 section) from the cache, verifying each file again.
copy_dsc() {
    local dsc="$1" expected="$2" dest="$3" sha name count=0
    if [ ! -f "$CACHE_DIR/$dsc" ] || [ "$(sha256_of "$CACHE_DIR/$dsc")" != "$expected" ]; then
        echo "ERROR: $CACHE_DIR/$dsc is missing or does not match its pinned sha256" >&2
        exit 1
    fi
    mkdir -p "$dest"
    cp "$CACHE_DIR/$dsc" "$dest/"
    while read -r sha name; do
        if [ ! -f "$CACHE_DIR/$name" ] || [ "$(sha256_of "$CACHE_DIR/$name")" != "$sha" ]; then
            echo "ERROR: $CACHE_DIR/$name (from $dsc) is missing or does not match the .dsc" >&2
            exit 1
        fi
        cp "$CACHE_DIR/$name" "$dest/"
        count=$((count + 1))
    done < <(awk '/^Checksums-Sha256:/ { s = 1; next } s && /^ / { print $1, $3; next } s { s = 0 }' "$CACHE_DIR/$dsc")
    [ "$count" -gt 0 ] || { echo "ERROR: no files listed in $dsc" >&2; exit 1; }
}

# Keep the sources a build used: upstream pools drop old revisions (deb.sury.org keeps
# only the newest), and a pin whose source is gone can never be rebuilt. Sources are the
# same on every architecture, so only the amd64 build collects them.
collect_sources() {
    [ "$ARCH" = amd64 ] || return 0
    echo "==> Collecting the sources of $TARGET into $SOURCES_DIR"
    rm -rf "$SOURCES_DIR"
    mkdir -p "$SOURCES_DIR"
    copy_dsc "${SOURCE_PACKAGE}_${SOURCE_VERSION}.dsc" "$SOURCE_DSC_SHA256" "$SOURCES_DIR/upstream"
    if [ -n "${PHP_COMMON_SOURCE_VERSION:-}" ]; then
        copy_dsc "php-defaults_${PHP_COMMON_SOURCE_VERSION}.dsc" "$PHP_COMMON_DSC_SHA256" "$SOURCES_DIR/php-defaults"
    fi
    # The target's target.conf, patches and SOURCE.md, plus the global build settings.
    mkdir -p "$SOURCES_DIR/target"
    # -L: a variant may share its patches/ with another variant through a symlink.
    cp -aL "$TARGET_DIR/." "$SOURCES_DIR/target/"
    if [ -n "$BASE_TARGET_DIR" ]; then
        mkdir -p "$SOURCES_DIR/base-target"
        cp -a "$BASE_TARGET_DIR/." "$SOURCES_DIR/base-target/"
    fi
    cp "$REPO_ROOT/build/build.conf" "$SOURCES_DIR/build.conf"
    {
        echo "Sources of the $TARGET packages of debian-php-backports"
        echo "($(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'commit unknown'))."
        echo
        echo "upstream/      the source package, as pinned in target/target.conf:"
        echo "               $SOURCE_PACKAGE $SOURCE_VERSION from $SOURCE_POOL_URL"
        if [ -n "${PHP_COMMON_SOURCE_VERSION:-}" ]; then
            echo "php-defaults/  the php-common source, as pinned in build.conf:"
            echo "               php-defaults $PHP_COMMON_SOURCE_VERSION from deb.sury.org"
        fi
        echo "target/        target.conf and the patches added to debian/patches/series"
        if [ -n "$BASE_TARGET_DIR" ]; then
            echo "base-target/   the target this one is a variant of ($BASE_TARGET): its patches"
            echo "               are added first, then the ones in target/ (both series in order)"
            if [ -n "${EXCLUDE_BASE_PATCHES:-}" ]; then
                echo "               Left out of the base patches (EXCLUDE_BASE_PATCHES in target.conf):"
                for p in $EXCLUDE_BASE_PATCHES; do echo "                 $p"; done
            fi
        fi
        echo "build.conf     global build settings"
        echo
        echo "Unpack with: dpkg-source -x upstream/${SOURCE_PACKAGE}_${SOURCE_VERSION}.dsc"
    } > "$SOURCES_DIR/README.txt"
    (cd "$SOURCES_DIR" && find . -type f ! -name SHA256SUMS -printf '%P\n' | LC_ALL=C sort \
        | xargs -d '\n' sha256sum > SHA256SUMS)
}

START_TIME="$(date +%s)"
case "$ACTION" in
    image) build_image ;;
    build) build_packages; collect_sources ;;
    all) build_image; build_packages; collect_sources ;;
    *) usage ;;
esac
ELAPSED=$(( $(date +%s) - START_TIME ))
printf '==> Done: %s %s in %dm%02ds\n' "$TARGET" "$ACTION" $((ELAPSED / 60)) $((ELAPSED % 60))
