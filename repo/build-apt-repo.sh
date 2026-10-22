#!/usr/bin/env bash
# Assemble an apt repository from built targets.
# Usage: repo/build-apt-repo.sh <dist-dir> <out-dir> [<gpg-key-id>]
#
# <dist-dir> holds <release>/<php>/ directories as produced by build/build.sh
# (e.g. dist/debian9-stretch/php7.3-sury/*.deb). Each Debian codename becomes a
# suite and the origin part of the PHP directory becomes the component:
#
#   debian9-stretch/php7.0-debian  ->  suite stretch, component debian
#   debian9-stretch/php7.3-sury    ->  suite stretch, component sury
#   debian6-squeeze/php5.4-debian7 ->  suite squeeze, component debian7
#
# so a server that only wants the fixed build of its own PHP version adds just the
# "debian" component and is never offered another PHP version.
#
# With a key id, Release is signed both as InRelease and as detached Release.gpg
# (apt older than 0.8.16, i.e. squeeze, only reads Release.gpg).
set -euo pipefail

[ $# -ge 2 ] || { echo "Usage: $0 <dist-dir> <out-dir> [<gpg-key-id>]" >&2; exit 1; }
DIST="$(realpath "$1")"; OUT="$2"; KEY="${3:-}"
mkdir -p "$OUT"; OUT="$(realpath "$OUT")"
ARCH=amd64

declare -A COMPONENTS
shopt -s nullglob
for dir in "$DIST"/*/*/; do
    release="$(basename "$(dirname "$dir")")"   # debian9-stretch
    php="$(basename "$dir")"                     # php7.3-sury
    codename="${release#*-}"                     # stretch
    component="${php#*-}"                        # sury
    debs=("$dir"*.deb)
    [ ${#debs[@]} -gt 0 ] || { echo "skip $release/$php: no .deb files" >&2; continue; }
    pool="$OUT/pool/$codename/$component"
    mkdir -p "$pool"
    cp -n "${debs[@]}" "$pool/"                  # shared deps (php-common) appear in several targets
    COMPONENTS[$codename]="${COMPONENTS[$codename]:-} $component"
done

[ ${#COMPONENTS[@]} -gt 0 ] || { echo "ERROR: no built targets under $DIST" >&2; exit 1; }

cd "$OUT"
for codename in "${!COMPONENTS[@]}"; do
    comps="$(tr ' ' '\n' <<<"${COMPONENTS[$codename]}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
    for comp in $comps; do
        bin="dists/$codename/$comp/binary-$ARCH"
        mkdir -p "$bin"
        apt-ftparchive packages "pool/$codename/$comp" > "$bin/Packages"
        gzip -9nk -f "$bin/Packages"
    done
    apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="debian-php-backports" \
        -o APT::FTPArchive::Release::Label="debian-php-backports" \
        -o APT::FTPArchive::Release::Suite="$codename" \
        -o APT::FTPArchive::Release::Codename="$codename" \
        -o APT::FTPArchive::Release::Architectures="$ARCH" \
        -o APT::FTPArchive::Release::Components="${comps% }" \
        release "dists/$codename" > "dists/$codename/Release"
    if [ -n "$KEY" ]; then
        rm -f "dists/$codename/InRelease" "dists/$codename/Release.gpg"
        gpg --batch --yes --local-user "$KEY" --digest-algo SHA256 --clearsign \
            -o "dists/$codename/InRelease" "dists/$codename/Release"
        gpg --batch --yes --local-user "$KEY" --digest-algo SHA256 --armor --detach-sign \
            -o "dists/$codename/Release.gpg" "dists/$codename/Release"
    fi
    echo "suite $codename: components ${comps% }"
done
