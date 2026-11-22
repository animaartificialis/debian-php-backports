#!/usr/bin/env bash
# Runs as root inside a plain BASE_IMAGE container; /dist holds the built .deb files,
# /tests this directory.
set -euo pipefail
: "${DEBIAN_CODENAME:?}" "${APT_MIRROR:?}" "${TEST_PHP_BINARY:?}" "${EXPECT:?}"
export DEBIAN_FRONTEND=noninteractive

printf '%s\n' \
    "deb ${APT_SOURCE_OPTIONS:-} ${APT_MIRROR} ${DEBIAN_CODENAME} main" \
    "deb ${APT_SOURCE_OPTIONS:-} ${APT_SECURITY_MIRROR} ${APT_SECURITY_SUITE} main" \
    > /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*.list
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive
if [ -n "${APT_EXTRA_CONF:-}" ]; then echo "$APT_EXTRA_CONF" >> /etc/apt/apt.conf.d/99archive; fi
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
apt-get update -qq
apt-get install -y -qq --no-install-recommends dpkg-dev > /dev/null
mkdir /tmp/repo
cp /dist/*.deb /tmp/repo/
(cd /tmp/repo && dpkg-scanpackages . /dev/null > Packages 2> /dev/null)
if [ -n "${APT_EXTRA_CONF:-}" ]; then
    echo "deb file:/tmp/repo ./" > /etc/apt/sources.list.d/local.list
else
    echo "deb [trusted=yes] file:/tmp/repo ./" > /etc/apt/sources.list.d/local.list
fi
apt-get update -qq
# Only packages from /dist: the archive's own php5 packages have the same names.
apt-get install -y -qq --no-install-recommends php5-cli php5-mysqlnd > /dev/null
"$TEST_PHP_BINARY" -v | head -1
dpkg-query -W -f='${Package} ${Version}\n' php5-cli php5-mysqlnd

fixed=0 unfixed=0 errors=0
for case in /tests/cases/*.php; do
    rc=0
    timeout 120 "$TEST_PHP_BINARY" -d phar.readonly=0 -d display_errors=stderr "$case" || rc=$?
    case "$rc" in
        0) fixed=$((fixed + 1)) ;;
        1) unfixed=$((unfixed + 1)) ;;
        *) errors=$((errors + 1)); echo "ERROR: $(basename "$case") exited with $rc" ;;
    esac
done
echo "fixed: $fixed, not fixed: $unfixed, errors: $errors"
[ "$errors" -eq 0 ] || exit 1
case "$EXPECT" in
    fixed) [ "$unfixed" -eq 0 ] || { echo "FAIL: some fixes are missing"; exit 1; } ;;
    unfixed) [ "$fixed" -eq 0 ] || { echo "FAIL: a normal target has an extended-only fix"; exit 1; } ;;
esac
echo "OK ($EXPECT)"
