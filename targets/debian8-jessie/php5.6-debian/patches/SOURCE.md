# Patch provenance

- Source URL: https://packages.sury.org/php/pool/main/p/php5.6/php5.6_5.6.40-105%2B0~20261022.135%2Bdebian12~1.gbp37a17e.debian.tar.xz
- Downloaded: 2026-10-22T18:52:07Z
- Tarball sha256: `9b87b75b08921b559888381ad0cc9a7be64f67c3e246413dd1f0327c2651afff`

## Patches

- `0253-GHSA-m33r-qmcv-p97q-soap-Fix-use-after-free-after-he.patch` sha256: `eb8a64f3f4b89b235b1dfc15bd104e7b218d5b623e8e1802921d26b75ba32cbd`
- `0254-GHSA-hmxp-6pc4-f3vv-soap-Fix-broken-Apache-map-value.patch` sha256: `48e15e14f60202ad43f9638288995b16171cd0572734245a3976eee0dc9ac519`
- `0257-GHSA-7qg2-v9fj-4mwv-fpm-XSS-within-status-endpoint.patch` sha256: `68aa942258adcbeb0b42a6d9d95e9cf083cb0d66a9974d2f907713ae17a7469c` (regenerated, see below)
- `0260-ext-openssl-openssl_encrypt-zend-mm-heap-overflow-on.patch` sha256: `b0f641d0baf0710b9c0571bb2c92a6bfbb6cffe375f8ad377f327cdc194d7739` (regenerated, see below)
- `0261-Avoid-state-corruption-via-bailout.patch` sha256: `d945982b5ab29bc5c42d1892750d72d39ae911df8b9f4f5ea47d133707ab72a4`

0253, 0254 and 0261 are Sury's files unchanged. Do not run `build/fetch-sury-patches.sh`
for this target: it would replace 0257 and 0260 with Sury's versions, whose NEWS hunks
do not apply to deb8u23, and overwrite this file.

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

## Fixes newer than ELTS deb8u23 (added 2026-11-14)

Sury's php5.6 5.6.40-105 stack was checked for every patch dated after April 2025
(0241–0264; patches without a `Date:` header are older backports of 2019–2021 bugs).
Added, in Sury's order and before 0261:

- `0253` — **CVE-2026-7261** (GHSA-m33r-qmcv-p97q): SOAP use-after-free after a header
  parsing failure with `SOAP_PERSISTENCE_SESSION`. Sury's file unchanged.
- `0254` — **CVE-2026-7262** (GHSA-hmxp-6pc4-f3vv): SOAP apache map value NULL check.
  Sury's file unchanged.
- `0257` — **CVE-2026-6735** (GHSA-7qg2-v9fj-4mwv): XSS in the FPM status page
  (`request_uri` was not escaped, `query_string` was escaped with wrong flags). The NEWS
  hunk is dropped (Debian's NEWS differs); the code hunks are unchanged. Regenerated with
  `git diff` against deb8u23.
- `0260` — **GH-22187**: heap overflow in `openssl_encrypt()`/`openssl_decrypt()` with
  AES-WRAP-PAD (no CVE id). NEWS hunk dropped, code unchanged (only the context lines
  differ: Debian's 5.6 still uses a stack `EVP_CIPHER_CTX`). The fix is guarded by
  `#ifdef EVP_CIPH_WRAP_MODE`, which jessie's OpenSSL 1.0.1t does not define, so it
  compiles to nothing here: jessie's PHP cannot use wrap mode and is not affected. It is
  carried so the source matches Sury's and stays safe if built against a newer OpenSSL.

Considered and not added:

- `0241`–`0250`, `0252`: build fixes for newer toolchains (readdir_r, GCC/ICU checks,
  autoconf, LiteSpeed SAPI, `__attribute__`). Not security fixes; jessie's toolchain
  does not need them.
- `0251` "Add minimal privacy-preserving secure DNS telemetry": not a security fix; sends
  DNS queries to check the PHP version. Not wanted here.
- `0255`: only adds a test for GHSA-96wq-48vp-hh57 (metaphone() signed overflow with a
  2 GB string). The backport (Remi Collet) carries no code change for this branch, so
  there is nothing to apply; this was not checked independently.
- `0256`, `0264`: NEWS only. `0258`, `0259`: test fixes for 0257.
- `0262`, `0263` (CVE-2023-0662): already in ELTS deb8u17, see above.

## PHP 8.2.36 fixes (added 2026-11-19)

PHP 8.2.36 (2026-11-19) fixed 12 security bugs. deb.sury.org backported them to
php5.6 5.6.40-108 (patches 0390–0400); the files here come from the bookworm build of it:

- Source URL: https://packages.sury.org/php/pool/main/p/php5.6/php5.6_5.6.40-109%2Bdebsuryorg12.1%2Bphp%2B1.debian.tar.xz
  (version checked in `dists/bookworm/main/source/Sources.gz`, whose SHA256 matches
  `dists/bookworm/InRelease`)
- Downloaded: 2026-11-19
- Tarball sha256: `ab7d01f462b480c5ca2eab68956d65add021977b4ee2681795baf8e8cf309a0b`

In this tarball the older patches above have other numbers (0252, 0253, 0256, 0259,
0260); their content is the same as in 5.6.40-105. Added after 0261, in Sury's order:

| Patch | CVE | Advisory | Bug | File |
|---|---|---|---|---|
| `0390` | CVE-2026-15353 | GHSA-q23r-hr55-xmpg | SOAP: empty or invalid `arraySize` reads uninitialized memory | Sury's, unchanged |
| `0391` | CVE-2026-128090 | GHSA-68fq-fh7h-f8gr | Phar: OpenSSL signature downgraded to a keyless hash | Sury's, unchanged |
| `0392` | CVE-2026-129538 | GHSA-5j3f-64r7-f564 | php-cgi: PATH_INFO out-of-bounds read and write | Sury's, unchanged |
| `0393` | CVE-2026-129292 | GHSA-3mg3-cr28-46gc | FPM status page: method, user and script not escaped | Sury's, unchanged |
| `0394` | CVE-2026-129289 | GHSA-qc49-hpvq-g2w6 | FPM: unread request body parsed as a new FastCGI request | Sury's, unchanged |
| `0395` | CVE-2026-129506 | GHSA-4646-p932-gw34 | SOAP: DTD freed while attributes still use it | regenerated, see below |
| `0396` | CVE-2026-129496 | GHSA-gr4f-wgx5-jpfv | timezone cache use-after-free in error log timestamps | Sury's, unchanged |
| `0397` | CVE-2026-126714 | GHSA-fm2m-fjf5-v3cp | session files: interrupted write keeps the old suffix | Sury's, unchanged |
| `0398` | CVE-2026-115560 | GHSA-658j-r8rw-q6mx | session upload progress: serializer mismatch | Sury's, unchanged |
| `0399` | CVE-2026-128064 | GHSA-f6gg-rchx-xw8j | mixed-case `HTTPS://`/`FTPS://` used plaintext | Sury's, unchanged |
| `0400` | CVE-2026-129291 | GHSA-jm4m-qfqx-967m | FPM: epoll event left on a closed worker pipe, use-after-free | Sury's, unchanged |
| `0401` | CVE-2026-127960 | GHSA-mmf9-xm3v-hg2x | HTTP wrapper: quadratic folded response header joining | ours, see below |

Notes:

- `0395`: the code change is Sury's (and upstream's), but the context is not: deb8u23
  still has the older recursive `cleanup_xml_node()`, without Sury's rewrite for
  GHSA-rgrp-mwpx-f6rm (CVE-2026-91765). Sury's file applies only with fuzz, so it was
  regenerated with `git diff`. The new `XML_DTD_NODE` branch sits in the same `if/else`
  chain, before the branch that deletes non-element nodes, so the DTD is no longer
  unlinked and freed. In 5.6 only `soap_xmlParseFile()` (WSDL and imported schemas)
  runs this cleanup; SOAP requests go through `soap_xmlParseMemory()`, where the call
  is commented out, so a SOAP server already rejects a request with a DTD. The bug
  is reachable through an attacker-controlled WSDL or schema.
- `0398` only changes the default of `session.upload_progress.enabled` to 0. Upload
  progress was already turned off at run time by `0261`, so this changes only what
  `ini_get()` reports.
- `0400`: the advisory names PHP 8.1.20 as the start, because of a delayed cleanup added
  then. 5.6 has the same root problem in `fpm_child_close()` (the pipe is closed without
  removing its epoll event), and frees the worker record at once, so the patch applies
  to the same code.
- `0401` (CVE-2026-127960) is our own 5.6 port, not from Sury. The quadratic code came
  to deb8u23 with ELTS's backport of the CVE-2025-1217 fix (folded header support);
  Sury's 5.6 does not have that code and so has no patch. Upstream (php-src commit
  `7b2a39410308db2c5db21cfe51920a54d2682324`) collects the header in a `smart_str`. In
  5.6 the header is a `char *` with a length, and 5.6's `smart_str` grows in fixed
  128-byte steps, so the port keeps the `char *`, adds its allocated size
  (`last_header_line_size`), grows it by doubling with `erealloc()` and appends each
  folded line in place. The header text that is stored does not change.

Patch sha256:

- `0390-…` `922ed218bc4e84769974d3034cb978e5f0c0a5212acef806057b7461880bd8bd`
- `0391-…` `007d251f29ae2878444b802cd4ffffd89501ac251d397147efa2a3d59537e254`
- `0392-…` `fbe44fcde58e7058df2ed0105669d798debed0eb3556f466a183628834487215`
- `0393-…` `49209070d6bc56310d729f48ee3aeae6ae3ae2371c86cd576fb74cedac5a3597`
- `0394-…` `4283296ad0365727d8fe1b3ca9585cf43065663b81b68789391f5bcddfe40fe6`
- `0395-…` `a55799894959535b5f220da2f15d1915661237037f57e17cd1426e74fbd2a39f` (regenerated)
- `0396-…` `03b0b99ef9e0cde244cdb47f3ce10508347d6b2ea21db81069d6df7d37d777c0`
- `0397-…` `396d3e1ad1ad1d072a243f7b56b6d32c9661f3d5f4dd362d35284606b007dfa1`
- `0398-…` `6748dbeeb91f33952c75ee4fe36db3574a2b9a841a4a551c0e2a1638499640fa`
- `0399-…` `e66928e080c0ef082b2666cec951ea3d883e8dd35da0647493d75f739a764b2b`
- `0400-…` `4442a81705aca18e4383cb6b3ae583e49165a8e8286b1f2929b94dc120033b12`
- `0401-…` `0e0eb4dcd7a02ce3182ae5e61e4acb17a2e1937461c03d84bb8b707f6aa310a6` (ours)

Not checked in this round: Sury's 5.6.40-106 and -107 (0264–0389, November 2026) add
many more backports (for example CVE-2026-91765, CVE-2025-14181, CVE-2026-17543 and
CVE-2025-1735) that this target does not have yet. Some of them may already be in ELTS
deb8u23. They need their own review.
