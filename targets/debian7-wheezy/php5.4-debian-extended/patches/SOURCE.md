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

## CVE-2024-8929: mysqlnd heap over-read

`CVE-2024-8929-php54.patch` = ELTS `CVE-2024-8929/01` to `05` in one patch (the same
fix as Sury's `0267`, `0268` and `0311`; GHSA-h35g-vwh6-m678). A malicious or fake
MySQL server could make mysqlnd read past the end of a packet and so leak heap memory
to the PHP script (field defaults, the LOCAL INFILE name, the OK message, prepared
statement rows, text rows on 32 bit, the auth plugin name).

- `mysqlnd_ps_codec.c`: the checks are added by hand, because the 5.4 fetch functions
  take an extra `as_unicode` argument. The helpers get `TSRMLS_DC` (as Sury's).
- `mysqlnd_wireprotocol.c`: the auth response, result set header and field hunks and
  `02` (auth plugin name) apply unchanged. The binary row hunk is by hand; it uses
  `row_buffer->app`, the data size, as Sury's `0311` does. After a malformed row, the
  fields decoded so far are freed and all fields set to NULL (ELTS sets them to NULL
  without freeing strings already decoded, a small leak).
- `mysqlnd_result.c`: as upstream.
- The tests and `fake_server.inc` are unchanged.

Behaviour change: a malformed packet now gives a warning ("Malformed server packet",
"... is past the packet size") and the query or fetch fails, instead of returning data
read from outside the packet. Well-formed rows are read as before (the reproducer
checks this for all field types, binary and text protocol).

## CVE-2025-1218: mysqlnd temporal fields and OK message

`CVE-2025-1218-php54.patch` = Sury's `0322` + `0323` in one patch
(GHSA-r6x9-5r99-36j7). It needs the CVE-2024-8929 patch (it extends its checks), so it
comes after it. A binary DATE, TIME or DATETIME value shorter than its fixed layout,
and an OK message longer than the OK packet, made mysqlnd read past the field or
packet.

- `mysqlnd_ps_codec.c`: the helper and the three length checks are placed by hand
  (other context); the offset changes apply unchanged.
- `mysqlnd_wireprotocol.c`: the null bitmap check comes after the zvals of the row are
  created, and on failure they are set to NULL, so that the row can be freed as usual
  (Sury's returns before they exist). The OK packet hunk applies unchanged.
- NEWS hunks dropped; the tests apply unchanged.

Behaviour change: such packets now give a warning ("Field length is too short for the
field type", "Incomplete null bitmap", "OK packet ... shorter than expected") and the
fetch or command fails.
