# Patch provenance

- Source URL: https://packages.sury.org/php/pool/main/p/php5.6/php5.6_5.6.40-105%2B0~20261022.135%2Bdebian12~1.gbp37a17e.debian.tar.xz
- Downloaded: 2026-10-22T18:52:07Z
- Tarball sha256: `9b87b75b08921b559888381ad0cc9a7be64f67c3e246413dd1f0327c2651afff`

## Patches

- `0261-Avoid-state-corruption-via-bailout.patch` sha256: `d945982b5ab29bc5c42d1892750d72d39ae911df8b9f4f5ea47d133707ab72a4`

## Base: Freexian ELTS php5 5.6.40+dfsg-0+deb8u23 (changed 2026-11-14)

The source package is no longer Debian LTS's last jessie update `5.6.40+dfsg-0+deb8u12`
(2020), but `5.6.40+dfsg-0+deb8u23` (April 2025) from the public repository of
[Freexian ELTS](https://www.freexian.com/lts/extended/), the Extended LTS team that kept
fixing jessie's PHP after Debian LTS ended:

- `.dsc`: http://deb.freexian.com/extended-lts/pool/main/p/php5/php5_5.6.40+dfsg-0+deb8u23.dsc,
  sha256 `eb6eb6eeacc96f2c994a58f38521e80e944efdfc46099980687f83e28cf06612`
- `.debian.tar.xz` sha256 `a9bb07558803ef70ea0f860cfdefd2006ad35fc99735dd2ef111bc6d10b9952e`
- `php5_5.6.40+dfsg.orig.tar.gz` is the same file as in Debian's deb8u12 (sha256
  `1ffdf771591b6afdff5c3b2b22febe6043f92bc67bb6f8e4629183127819345d`), and the
  Build-Depends are unchanged, so jessie's `apt-get build-dep php5` still works.

deb8u13 to deb8u23 fix CVE-2020-7070, CVE-2019-9675, CVE-2020-7068, CVE-2020-7071,
CVE-2021-21702, CVE-2021-21703, CVE-2021-21704, CVE-2021-21705, CVE-2021-21707,
CVE-2022-31625, CVE-2022-31626, CVE-2022-31628, CVE-2022-31629, CVE-2022-31631,
CVE-2023-0567, CVE-2023-0568, CVE-2023-0662, CVE-2023-3823, CVE-2023-3824,
CVE-2024-2756, CVE-2024-3096, CVE-2024-5458, CVE-2024-8925, CVE-2024-8927,
CVE-2024-8929, CVE-2024-8932, CVE-2024-11233, CVE-2024-11234, CVE-2024-11236,
GHSA-4w77-75f9-2c8w, CVE-2025-1217, CVE-2025-1219, CVE-2025-1734, CVE-2025-1736 and
CVE-2025-1861 (see `debian/changelog` of the package). All credit for these goes to
the Freexian ELTS team.

What happened to the patches of the deb8u12 build (`5.6.40+dfsg-0+deb8u12+animaa2`):

- **Kept:** `0261-Avoid-state-corruption-via-bailout.patch` (CVE-2026-109618 and
  CVE-2026-109619, 2026). ELTS has nothing like it: deb8u23 predates it. It applies to
  deb8u23 unchanged (only line offsets in `main/main.c` and `main/php_variables.c`).
- **Dropped:** `0262-Fix-repeated-warning-for-file-uploads-limit-exceedin.patch` and
  `0263-Introduce-max_multipart_body_parts-INI.patch` (CVE-2023-0662). ELTS deb8u17
  already has the same fix as `debian/patches/CVE-2023-0662.patch` (php-src commits
  716de0cf and e45850c1, the same two commits). Its code is the same as Sury's except for
  a missing `TSRMLS_CC`, which only matters in ZTS builds (Debian builds php5 without
  ZTS). `max_multipart_body_parts` is still there, default `-1`.
