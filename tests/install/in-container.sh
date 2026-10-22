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

echo "==> Upgrade to patched $TEST_PACKAGES"
apt-get install -y --no-install-recommends "${packages[@]}"

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

echo "OK (positive): patched package installed and working"
