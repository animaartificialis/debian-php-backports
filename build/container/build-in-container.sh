#!/usr/bin/env bash
# Runs inside the builder container. Downloads the official Debian source package,
# applies the reviewed patches from /target/patches, bumps the version and builds
# binary packages into /out.
#
# Mounts: /target (ro) = targets/<release>/<php>, /cache (rw), /out (rw)
# Environment: all variables from build/build.conf and target.conf.
set -euo pipefail

: "${DEBIAN_CODENAME:?}" "${SOURCE_PACKAGE:?}" "${SOURCE_VERSION:?}" "${SOURCE_POOL_URL:?}"
: "${SOURCE_DSC_SHA256:?}" "${VERSION_SUFFIX:?}" "${CHANGELOG_ENTRY:?}"
: "${DEBFULLNAME:?}" "${DEBEMAIL:?}" "${DEB_BUILD_OPTIONS:=nocheck}"

CACHE_DIR=/cache
OUT_DIR=/out
WORK_DIR=/build/work
DSC_NAME="${SOURCE_PACKAGE}_${SOURCE_VERSION}.dsc"
# NEW_VERSION may be set by target.conf (e.g. epoch or a different distribution tag).
NEW_VERSION="${NEW_VERSION:-${SOURCE_VERSION}${VERSION_SUFFIX}}"

step() {
    echo
    echo "==> $*"
}

sha256_of() {
    sha256sum "$1" | cut -d' ' -f1
}

# download_verified <file name> <expected sha256>
download_verified() {
    local name="$1" expected="$2" path="$CACHE_DIR/$1"
    if [ -f "$path" ] && [ "$(sha256_of "$path")" = "$expected" ]; then
        echo "    cached: $name"
        return
    fi
    echo "    downloading: $SOURCE_POOL_URL/$name"
    curl -fsSL --retry 3 -o "$path.part" "$SOURCE_POOL_URL/$name"
    mv "$path.part" "$path"
    if [ "$(sha256_of "$path")" != "$expected" ]; then
        echo "ERROR: sha256 mismatch for $name (expected $expected, got $(sha256_of "$path"))" >&2
        exit 1
    fi
}

# Print "<sha256> <file name>" for every file listed in the dsc Checksums-Sha256 section.
dsc_files() {
    awk '
        /^Checksums-Sha256:/ { in_section = 1; next }
        in_section && /^ / { print $1, $3; next }
        in_section { in_section = 0 }
    ' "$1"
}

main() {
    step "Build of $SOURCE_PACKAGE $SOURCE_VERSION -> $NEW_VERSION for $DEBIAN_CODENAME"

    # Clean artifacts of a previous build so /out only holds this build.
    rm -f "$OUT_DIR"/*.deb "$OUT_DIR"/*.udeb "$OUT_DIR"/*.changes "$OUT_DIR"/*.buildinfo \
          "$OUT_DIR"/SHA256SUMS "$OUT_DIR"/BUILD-INFO.txt "$OUT_DIR"/Packages "$OUT_DIR"/Packages.gz

    step "Step 1: download source package into $CACHE_DIR"
    download_verified "$DSC_NAME" "$SOURCE_DSC_SHA256"
    local sha name count=0
    while read -r sha name; do
        download_verified "$name" "$sha"
        count=$((count + 1))
    done < <(dsc_files "$CACHE_DIR/$DSC_NAME")
    if [ "$count" -eq 0 ]; then
        echo "ERROR: no files found in Checksums-Sha256 section of $DSC_NAME" >&2
        exit 1
    fi

    step "Step 2: extract source in $WORK_DIR"
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    dpkg-source -x "$CACHE_DIR/$DSC_NAME" src
    cd src
    echo "    source format: $(cat debian/source/format 2>/dev/null || echo '1.0 (no debian/source/format)')"
    if [ -n "${CONTROL_SED:-}" ]; then
        echo "    relaxing debian/control: $CONTROL_SED"
        sed -i -e "$CONTROL_SED" debian/control
    fi
    if [ -n "${RULES_SED:-}" ]; then
        echo "    adjusting debian/rules: $RULES_SED"
        sed -i -e "$RULES_SED" debian/rules
    fi
    if [ -n "${SOURCE_FIXUP_CMD:-}" ]; then
        echo "    source fixup: $SOURCE_FIXUP_CMD"
        bash -c "$SOURCE_FIXUP_CMD"
    fi

    if [ -n "${DROP_PATCHES:-}" ]; then
        step "Step 2b: drop patches from the upstream series: $DROP_PATCHES"
        QUILT_PATCHES=debian/patches quilt pop -a -q
        local drop
        for drop in $DROP_PATCHES; do
            grep -qxF "$drop" debian/patches/series || { echo "ERROR: $drop not in series" >&2; exit 1; }
            sed -i "\|^${drop}\$|d" debian/patches/series
            echo "    dropped: $drop"
        done
        QUILT_PATCHES=debian/patches quilt push -a -q
    fi

    step "Step 3: add patches from /target/patches"
    mkdir -p debian/patches
    touch debian/patches/series
    local patches=()
    local patch
    while read -r patch; do
        [ -n "$patch" ] || continue
        patches+=("$patch")
        cp "/target/patches/$patch" "debian/patches/$patch"
        if grep -qxF "$patch" debian/patches/series; then
            echo "    already in series: $patch"
        else
            echo "$patch" >> debian/patches/series
            echo "    added to series: $patch"
        fi
    done < /target/patches/series

    local quilt_log rc=0
    quilt_log="$(QUILT_PATCHES=debian/patches quilt push -a 2>&1)" || rc=$?
    echo "$quilt_log"
    # quilt exits 2 when there is nothing left to apply.
    if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
        echo "ERROR: patches do not apply (quilt push -a exit code $rc)" >&2
        exit 1
    fi

    step "Step 4: changelog entry $NEW_VERSION"
    export DEBFULLNAME DEBEMAIL
    dch --newversion "$NEW_VERSION" --distribution "$DEBIAN_CODENAME" --force-distribution \
        --force-bad-version \
        "$CHANGELOG_ENTRY"
    head -n 8 debian/changelog

    step "Step 5: dpkg-buildpackage (DEB_BUILD_OPTIONS=$DEB_BUILD_OPTIONS)"
    export DEB_BUILD_OPTIONS
    dpkg-buildpackage -us -uc -b -j"$(nproc)"

    step "Step 6: collect artifacts into $OUT_DIR"
    cd "$WORK_DIR"
    shopt -s nullglob
    local artifacts=(*.deb *.udeb *.changes *.buildinfo)
    shopt -u nullglob
    if [ "${#artifacts[@]}" -eq 0 ]; then
        echo "ERROR: no build artifacts found" >&2
        exit 1
    fi
    cp "${artifacts[@]}" "$OUT_DIR/"
    # Extra .deb files the built packages depend on (e.g. Sury php-common) ship with them.
    local url name
    for url in ${EXTRA_DEB_URLS:-}; do
        name="$(basename "$url" | sed 's/%2B/+/g')"
        [ -f "$CACHE_DIR/$name" ] || curl -fsSL --retry 3 -o "$CACHE_DIR/$name" "$url"
        cp "$CACHE_DIR/$name" "$OUT_DIR/"
        echo "    extra: $name"
    done
    (cd "$OUT_DIR" && sha256sum ./*.deb > SHA256SUMS)
    # Packages index so the directory works as a local apt repository:
    #   deb [trusted=yes] file:/path/to/dir ./
    (cd "$OUT_DIR" && dpkg-scanpackages . /dev/null 2>/dev/null > Packages && gzip -9n -c Packages > Packages.gz)
    {
        echo "codename:        $DEBIAN_CODENAME"
        echo "source package:  $SOURCE_PACKAGE"
        echo "source version:  $SOURCE_VERSION"
        echo "new version:     $NEW_VERSION"
        echo "patches applied: ${patches[*]:-(none, source package used as is)}"
        echo "patches dropped: ${DROP_PATCHES:-(none)}"
        echo "build date:      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "architecture:    $(dpkg-architecture -qDEB_HOST_ARCH)"
    } > "$OUT_DIR/BUILD-INFO.txt"

    step "Summary"
    cat "$OUT_DIR/BUILD-INFO.txt"
    echo "built packages:"
    (cd "$OUT_DIR" && ls -1 ./*.deb | sed 's|^\./|    |')
}

main "$@" 2>&1 | tee "$OUT_DIR/build.log"
