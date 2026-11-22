# Patch provenance (extended variant)

These patches are used by the two extended targets,
`targets/debian7-wheezy/php5.4-debian-extended` and
`targets/debian6-squeeze/php5.4-debian7-extended` (whose `patches/` is a symlink to
this directory). They are applied after all patches of the normal target
(`targets/debian7-wheezy/php5.4-debian/patches/series`, or the squeeze copy of it), in
the order of `series` here. See the normal target's `SOURCE.md` for those patches and
for the source package.

They are kept out of the normal targets because they are larger changes, or change
behaviour, and are less tested on PHP 5.4.

Sources, as for the normal targets:

- Freexian ELTS: http://deb.freexian.com/extended-lts/pool/main/p/php5/php5_5.6.40+dfsg-0+deb8u23.debian.tar.xz,
  sha256 `a9bb07558803ef70ea0f860cfdefd2006ad35fc99735dd2ef111bc6d10b9952e`, files
  `debian/patches/<name>`.
- deb.sury.org php5.6 5.6.40-109 (`php5.6_5.6.40-109+debsuryorg12.1+php+1.debian.tar.xz`,
  sha256 `ab7d01f462b480c5ca2eab68956d65add021977b4ee2681795baf8e8cf309a0b`).

Each patch was made with `git diff` against the deb7u30 tree with all earlier patches
applied, and applies with `patch --fuzz=0`. Each header has the source header and a
`debian-php-backports:` note that says what changed. The reproducers are in
`tests/php54-extended/cases/` (`make -C tests test-php54-extended`).

## CVE-2019-9675: Phar tar link name

`CVE-2019-9675-php54.patch` = ELTS `CVE-2019-9675.patch` (bug #77586). The `tar.c`
hunk is unchanged; the `bug71488.phpt` hunk is applied by hand (only the newline at the
end of the file differs).

In PHP 5.4 a link read from a tar file is already cut to 100 bytes (the bug #71488
fix in deb7u30), so the unchecked copy into the 100 byte `linkname` field cannot
overflow. The fix is kept as hardening. Behaviour change, as upstream: writing a
tar-based phar whose symlink target is 100 bytes or longer now fails with "link ... is
too long for format" instead of writing a link name without a terminating NUL.
