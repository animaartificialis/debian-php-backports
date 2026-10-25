#!/usr/bin/env bash
# Runs as root inside a plain BASE_IMAGE container; /dist holds the built .deb files.
set -euo pipefail

: "${DEBIAN_CODENAME:?}" "${APT_MIRROR:?}" "${APT_SECURITY_MIRROR:?}" "${APT_SECURITY_SUITE:?}"
: "${TEST_PACKAGES:?}" "${TEST_PHP_BINARY:?}" "${SOURCE_VERSION:?}" "${VERSION_SUFFIX:?}"

export DEBIAN_FRONTEND=noninteractive
read -r -a packages <<< "$TEST_PACKAGES"
FIRST_PACKAGE="${packages[0]}"
CHANGELOG="/usr/share/doc/$FIRST_PACKAGE/changelog.Debian.gz"
EXPECTED_VERSION="${NEW_VERSION:-${SOURCE_VERSION}${VERSION_SUFFIX}}"
CVE_ID="CVE-2026-109618"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

echo "==> Configure archive apt sources"
printf '%s\n' \
    "deb ${APT_SOURCE_OPTIONS:-} ${APT_MIRROR} ${DEBIAN_CODENAME} ${APT_COMPONENTS:-main}" \
    "deb ${APT_SOURCE_OPTIONS:-} ${APT_SECURITY_MIRROR} ${APT_SECURITY_SUITE} ${APT_COMPONENTS:-main}" \
    > /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive
if [ -n "${APT_EXTRA_CONF:-}" ]; then echo "$APT_EXTRA_CONF" >> /etc/apt/apt.conf.d/99archive; fi
# Slim images exclude /usr/share/doc; the changelog is needed for the assertions.
rm -f /etc/dpkg/dpkg.cfg.d/docker
# Do not start services (php-fpm) inside the test container.
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt-get update

if ! apt-cache show "$FIRST_PACKAGE" > /dev/null 2>&1; then
    echo "SKIP (negative): $FIRST_PACKAGE does not exist in the $DEBIAN_CODENAME archive"
else
echo "==> NEGATIVE case: install stock $TEST_PACKAGES"
apt-get install -y --no-install-recommends "${packages[@]}"
[ -f "$CHANGELOG" ] || fail "changelog $CHANGELOG not found"
# grep -c reads the whole input: with grep -q zcat would get SIGPIPE on long
# changelogs (php5) and pipefail would turn a match into a failure.
if zcat "$CHANGELOG" | grep -c "$CVE_ID" > /dev/null; then
    fail "stock changelog already mentions $CVE_ID"
fi
"$TEST_PHP_BINARY" -v
stock_version="$(dpkg-query -W -f='${Version}' "$FIRST_PACKAGE")"
if [ "$stock_version" = "$EXPECTED_VERSION" ]; then
    fail "stock $FIRST_PACKAGE already has version $EXPECTED_VERSION"
fi
echo "OK (negative): stock package is unpatched"
fi

# TEST_DUMMY_PACKAGES ("name=version ..."): empty packages standing in for PECL
# extensions a server has from the release or from Sury's old repository (php-apcu,
# php-imagick, ...). The upgrade must keep them: Sury's php-common breaks older versions
# of them, and apt would remove them instead of upgrading PHP.
if [ -n "${TEST_DUMMY_PACKAGES:-}" ]; then
    echo "==> Install stand-ins for installed extension packages: $TEST_DUMMY_PACKAGES"
    for spec in $TEST_DUMMY_PACKAGES; do
        name="${spec%%=*}"; version="${spec#*=}"
        mkdir -p "/tmp/dummy/$name/DEBIAN"
        printf 'Package: %s\nVersion: %s\nArchitecture: all\nMaintainer: install test <test@localhost>\nDescription: test stand-in for %s\n' \
            "$name" "$version" "$name" > "/tmp/dummy/$name/DEBIAN/control"
        dpkg-deb -b "/tmp/dummy/$name" "/tmp/dummy/$name.deb" > /dev/null
        dpkg -i "/tmp/dummy/$name.deb"
    done
fi

echo "==> Create local apt repository from /dist"
apt-get install -y --no-install-recommends dpkg-dev
mkdir /tmp/repo
cp /dist/*.deb /tmp/repo/
(cd /tmp/repo && dpkg-scanpackages . /dev/null > Packages)
# apt < 0.8.16 (squeeze) has no [trusted=yes]; there APT_EXTRA_CONF allows unauthenticated
if [ -n "${APT_EXTRA_CONF:-}" ]; then
    echo "deb file:/tmp/repo ./" > /etc/apt/sources.list.d/local.list
else
    echo "deb [trusted=yes] file:/tmp/repo ./" > /etc/apt/sources.list.d/local.list
fi
apt-get update

# Every package in /dist must be installable from /dist plus the release, e.g. no
# runtime dependency left out as build only. One at a time: php5 packages conflict.
echo "==> Simulate installing every built package"
while read -r pkg ver; do
    case "$pkg" in *-dbgsym) continue ;; esac
    apt-get install -s --no-install-recommends "$pkg=$ver" > /tmp/sim.log 2>&1 \
        || { cat /tmp/sim.log; fail "$pkg=$ver is not installable (runtime dependency missing from /dist?)"; }
done < <(awk '/^Package:/ { p = $2 } /^Version:/ { print p, $2 }' /tmp/repo/Packages)
echo "OK: every built package is installable"

echo "==> Upgrade to patched $TEST_PACKAGES"
apt-get install -y --no-install-recommends "${packages[@]}"
# Then the plain upgrade the README tells users to run: it brings the rebuilt php-common
# in where the release's own one satisfied the dependencies (focal).
apt-get upgrade -y --no-install-recommends
for spec in ${TEST_DUMMY_PACKAGES:-}; do
    name="${spec%%=*}"
    [ "$(dpkg-query -W -f='${Status}' "$name" 2>/dev/null)" = "install ok installed" ] \
        || fail "the upgrade removed $name (Breaks in php-common?)"
    echo "OK: $name survived the upgrade"
done
# PHP_COMMON_VERSION: the target ships its own php-common (build-php-common.sh); it must
# be the one installed, and without the Breaks field.
if [ -n "${PHP_COMMON_VERSION:-}" ]; then
    php_common_version="$(dpkg-query -W -f='${Version}' php-common)"
    [ "$php_common_version" = "$PHP_COMMON_VERSION" ] \
        || fail "php-common version is $php_common_version, expected $PHP_COMMON_VERSION"
    [ -z "$(dpkg-query -W -f='${Breaks}' php-common)" ] || fail "php-common still has a Breaks field"
    echo "OK: php-common $php_common_version without Breaks"
fi

echo "==> POSITIVE case"
zcat "$CHANGELOG" | grep -c "$CVE_ID" > /dev/null || fail "changelog does not mention $CVE_ID"
# Debian's packaging prints the package version in "php -v", Sury's does not;
# dpkg-query is the authoritative check.
"$TEST_PHP_BINARY" -v
installed_version="$(dpkg-query -W -f='${Version}' "$FIRST_PACKAGE")"
[ "$installed_version" = "$EXPECTED_VERSION" ] \
    || fail "$FIRST_PACKAGE version is $installed_version, expected $EXPECTED_VERSION"

hello="$("$TEST_PHP_BINARY" -r 'echo "hello\n";')"
[ "$hello" = "hello" ] || fail "hello world output: '$hello'"

script_output="$("$TEST_PHP_BINARY" -r '
$a = array(3, 1, 2);
sort($a);
$s = strtoupper(implode(",", $a));
$out = $s . "|" . str_repeat("ab", 2) . "|" . count(array_filter($a, function ($x) { return $x > 1; }));
if (function_exists("json_encode")) {
    $j = json_decode(json_encode(array("k" => $a)), true);
    $out .= "|" . $j["k"][2];
} else {
    $out .= "|3";
}
echo $out;
')"
[ "$script_output" = "1,2,3|abab|2|3" ] || fail "PHP script output: '$script_output'"
"$TEST_PHP_BINARY" -r 'exit(function_exists("json_encode") ? 0 : 1);' \
    || echo "NOTE: json extension not loaded, json part of the script was skipped"

# CVE-2023-0662: every target ships max_multipart_body_parts (ini_get() is false if unknown).
"$TEST_PHP_BINARY" -r 'exit(ini_get("max_multipart_body_parts") === false ? 1 : 0);' \
    || fail "max_multipart_body_parts is not a known INI setting (CVE-2023-0662 fix missing)"

# CVE-2026-109618 / CVE-2026-109619: verify zend_mm_safe_error_ex symbol is compiled into the binary.
# grep -c, not grep -q: grep -q stops at the first match, nm gets SIGPIPE, and pipefail
# turns the match into a failure (same trap as with zcat above). -F -w: plain text, whole
# word, so a longer symbol that merely starts the same does not count as the fix.
nm -D "$(command -v "$TEST_PHP_BINARY")" | grep -Fwc zend_mm_safe_error_ex > /dev/null \
    || fail "zend_mm_safe_error_ex symbol missing from $TEST_PHP_BINARY (CVE-2026-109618/109619 fix missing)"
echo "OK (positive): patched package installed and working"
