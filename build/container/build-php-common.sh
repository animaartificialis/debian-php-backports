#!/bin/sh
# Runs as root while the builder image is built. Rebuilds php-common from Sury's
# php-defaults source, without the "Breaks" field of the php-common package, installs it
# (Sury's PHP packages need php-common to build and to run) and keeps the .deb for the
# package build to ship.
#
# Sury's binary php-common breaks older versions of PECL extension packages (php-apcu,
# php-imagick, php-redis, ...). Those limits are about PHP 8; on a release where PHP 8
# never existed they only make apt remove working extensions when PHP is upgraded.
#
# Environment: DEBIAN_CODENAME, PHP_COMMON_SOURCE_VERSION, PHP_COMMON_DSC_SHA256,
# PHP_COMMON_VERSION (the binary version, with its epoch), DEBFULLNAME, DEBEMAIL. Source
# files already present in /cache (build.sh copies them from cache/<target>/) are used
# instead of being downloaded.
set -eu

: "${DEBIAN_CODENAME:?}" "${PHP_COMMON_SOURCE_VERSION:?}" "${PHP_COMMON_DSC_SHA256:?}"
: "${PHP_COMMON_VERSION:?}" "${DEBFULLNAME:?}" "${DEBEMAIL:?}"

POOL_URL=https://packages.sury.org/php/pool/main/p/php-defaults
DSC_NAME="php-defaults_${PHP_COMMON_SOURCE_VERSION}.dsc"
# The .deb and the sources it was built from stay in the image; build-in-container.sh
# copies them to /out and /cache.
KEEP_DIR=/usr/local/share/php-common
WORK_DIR=/tmp/php-common

sha256_of() {
    sha256sum "$1" | cut -d' ' -f1
}

# fetch <file name> <expected sha256>: from /cache if present, else from Sury's pool
fetch() {
    if [ -f "/cache/$1" ] && [ "$(sha256_of "/cache/$1")" = "$2" ]; then
        echo "    cached: $1"
        cp "/cache/$1" "$KEEP_DIR/src/$1"
    else
        echo "    downloading: $POOL_URL/$1"
        curl -fsSL --retry 3 -o "$KEEP_DIR/src/$1" "$POOL_URL/$1"
    fi
    if [ "$(sha256_of "$KEEP_DIR/src/$1")" != "$2" ]; then
        echo "ERROR: sha256 mismatch for $1 (expected $2, got $(sha256_of "$KEEP_DIR/src/$1"))" >&2
        exit 1
    fi
}

echo "==> php-common: rebuild of php-defaults $PHP_COMMON_SOURCE_VERSION as $PHP_COMMON_VERSION"
mkdir -p "$KEEP_DIR/src" "$WORK_DIR"
fetch "$DSC_NAME" "$PHP_COMMON_DSC_SHA256"
awk '/^Checksums-Sha256:/ { s = 1; next } s && /^ / { print $1, $3; next } s { s = 0 }' \
    "$KEEP_DIR/src/$DSC_NAME" | while read -r sha name; do fetch "$name" "$sha"; done

cd "$WORK_DIR"
dpkg-source -x "$KEEP_DIR/src/$DSC_NAME" src > /dev/null
cd src
# Drop the Breaks field (first line and continuation lines) of the php-common package.
# control.in is the template debian/control is generated from; same change there.
grep -q '^Breaks:' debian/control || { echo "ERROR: no Breaks field in debian/control: check the source" >&2; exit 1; }
for f in debian/control debian/control.in; do
    sed -i '/^Package: php-common$/,/^$/{ /^Breaks:/,/^[^ ]/{ /^Breaks:\|^ /d } }' "$f"
done
if grep -q '^Breaks:' debian/control; then
    echo "ERROR: a Breaks field is left in debian/control" >&2
    exit 1
fi
echo "    php-common package stanza after the change:"
sed -n '/^Package: php-common$/,/^Description:/p' debian/control | sed 's/^/        /'

# Releases whose debhelper predates compat 10 (trusty: 9.20131227, and its backports
# suite has no debhelper): php-defaults uses no compat-10-only helper, so build it at
# compat 9 with the release's own. dh-systemd is not installed yet either (the extra
# .debs come later), so the session-cleanup timer addon is left out.
if ! dpkg --compare-versions "$(dpkg-query -W -f='${Version}' debhelper)" ge 9.20160709; then
    echo "    debhelper $(dpkg-query -W -f='${Version}' debhelper): building php-common at compat 9"
    echo 9 > debian/compat
    sed -i -e 's/debhelper (>= 10)/debhelper (>= 9.20131227)/' debian/control debian/control.in
    sed -i -e 's/^DH_SYSTEMD := --with systemd/DH_SYSTEMD :=/' debian/rules
fi

# Build-Depends: debhelper (>= 10); already installed from backports where the release has an older one.
mk-build-deps -i -r -t 'apt-get -y --no-install-recommends' debian/control > /dev/null
export DEBFULLNAME DEBEMAIL
# debian/rules prefixes the binary php-common version with epoch 2: itself.
dch --newversion "${PHP_COMMON_VERSION#*:}" --distribution "$DEBIAN_CODENAME" --force-distribution \
    "Rebuild of deb.sury.org php-defaults for $DEBIAN_CODENAME without the Breaks of php-common on older PECL extension packages: they are about PHP 8, which this release never had, and would make apt remove working extensions."
dpkg-buildpackage -us -uc -b > "$WORK_DIR/build.log" 2>&1 || { cat "$WORK_DIR/build.log"; exit 1; }
cd "$WORK_DIR"
cp php-common_*.deb "$KEEP_DIR/"
deb="$(ls "$KEEP_DIR"/php-common_*.deb)"
if [ -n "$(dpkg-deb -f "$deb" Breaks)" ]; then
    echo "ERROR: the built php-common still has a Breaks field" >&2
    exit 1
fi
if [ "$(dpkg-deb -f "$deb" Version)" != "$PHP_COMMON_VERSION" ]; then
    echo "ERROR: built php-common is $(dpkg-deb -f "$deb" Version), expected $PHP_COMMON_VERSION" >&2
    exit 1
fi
dpkg -i "$deb" || apt-get install -f -y --no-install-recommends
echo "    built and installed: $(dpkg-query -W -f='${Package} ${Version}' php-common)"
rm -rf "$WORK_DIR"
