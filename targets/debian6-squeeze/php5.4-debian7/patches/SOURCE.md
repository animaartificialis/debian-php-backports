# Patch provenance

Same port and same file as `targets/debian7-wheezy/php5.4-debian/patches/`.

Sury never shipped PHP 5.4, so there is no ready-made patch for it.
`0001-Avoid-state-corruption-via-bailout-php54.patch` is a manual port of Sury's
`0261-Avoid-state-corruption-via-bailout.patch` from `php5.6 5.6.40-104` (the same
file as in `targets/debian8-jessie/php5.6-debian/patches/`, sha256
`35b6472ae1b8f90498766811dfa2379d371906a090311962a1df9627677aa7f6`).

Differences from the original, also described in the patch header:

- three hunks in `Zend/zend_alloc.c` are dropped: they change overflow checks that
  only exist in 5.6 (`_safe_emalloc_string()` and two more `safe_address()`
  variants); all four checks that 5.4 does have are converted,
- the `zend_mm_safe_error_ex()` declaration in `Zend/zend_alloc.h` sits after
  `_safe_emalloc()`.

The remaining 12 files apply with unchanged content. The patch was produced as a
`diff -ruN` of the 5.4.45-0+deb7u14 tree (Debian patches applied) before and after.

- Patch sha256: `c3081399f25fd59fac43fd4d2fbc66ad43ea1fb2e158b24953b4525059981500`
- Created: 2026-10-21T21:27:15Z

## CVE-2023-0662 (added 2026-10-22)

`0262-…-php54.patch` and `0263-…-php54.patch` are deb.sury.org php5.6 5.6.40-105 patches
0262 and 0263 (Jakub Zelenka, `max_multipart_body_parts`). 0262 applies unchanged; in
0263 only whitespace in the context of the `main/main.c` hunk differs. Both were
regenerated with `git diff` against the 5.4.45-0+deb7u14 tree with 0001 applied.

- `0262-…-php54.patch` sha256: `e5ae5539a6612345eb3fff2edf2bc3124b1f45d8899176b4594791c8c45ae093`
- `0263-…-php54.patch` sha256: `756aa9d81926f270cd384a032fcc509013cdf5a09efecc52842b591e57daae00`

## Base: Freexian ELTS php5 5.4.45-0+deb7u30 (changed 2026-11-14)

The source package is no longer Debian LTS's last wheezy update `5.4.45-0+deb7u14`, but
`5.4.45-0+deb7u30` (May 2020) from the public repository of
[Freexian ELTS](https://www.freexian.com/lts/extended/), which kept fixing wheezy's PHP
after Debian LTS ended:

- `.dsc`: http://deb.freexian.com/extended-lts/pool/main/p/php5/php5_5.4.45-0+deb7u30.dsc,
  sha256 `31731d1836e333fa2ac029e0ad5c51acb04b67be53c150bd11b4833ece60240d`
- `.debian.tar.gz` sha256 `919feddd1dc9601cfc5c9414426abe12e925e1b7476ad3714286fcebdce4dd6b`
- `php5_5.4.45.orig.tar.gz` is the same file as in Debian's deb7u14 (sha256
  `25bc4723955f4e352935258002af14a14a9810b491a19400d76fcdfa9d04b28f`), and the
  Build-Depends are unchanged.

deb7u15 to deb7u30 fix CVE-2018-14851, CVE-2018-14883, CVE-2018-17082, CVE-2018-19518,
CVE-2018-19935, CVE-2018-20783, CVE-2018-1000888, CVE-2019-9022, CVE-2019-9637,
CVE-2019-9638, CVE-2019-9639, CVE-2019-9640, CVE-2019-9641, CVE-2019-11034,
CVE-2019-11035, CVE-2019-11036, CVE-2019-11039, CVE-2019-11040, CVE-2019-11041,
CVE-2019-11042, CVE-2019-11043 (php-fpm remote code execution), CVE-2019-11045,
CVE-2019-11046, CVE-2019-11047, CVE-2019-11048, CVE-2019-11050, CVE-2019-18218,
CVE-2020-7059, CVE-2020-7060, CVE-2020-7062, CVE-2020-7063, CVE-2020-7064, CVE-2020-7066
and CVE-2020-7067 (see `debian/changelog` of the package). All credit for these goes to
the Freexian ELTS team.

0001, 0262 and 0263 are kept unchanged: deb7u30 predates them, and they apply to it
with line offsets only (no fuzz).

## Fixes from 2026 (added 2026-11-14)

Ported from deb.sury.org php5.6 5.6.40-105 (the same patches as the jessie target, see
`targets/debian8-jessie/php5.6-debian/patches/SOURCE.md` for what was considered).
Each was regenerated with `git diff` against the deb7u30 tree with 0001, 0262 and 0263
applied; each header says what changed.

- `0253-…-php54.patch` — **CVE-2026-7261** (GHSA-m33r-qmcv-p97q, SOAP use-after-free with
  `SOAP_PERSISTENCE_SESSION`). The code is the same in 5.4; only a whitespace-only hunk
  in `do_soap_call()` is dropped.
  sha256 `f90517444d13cb6a42ef4bed19c2ee4d99cc5bddefb513596ec34b2ab8495d53`
- `0254-…-php54.patch` — **CVE-2026-7262** (GHSA-hmxp-6pc4-f3vv, SOAP apache map NULL
  check). Applies unchanged.
  sha256 `8514e3239c72d04e7a5df3410f04d9dda21a025a9445c4bd87344574081f2785`
- `0257-…-php54.patch` — **CVE-2026-6735** (GHSA-7qg2-v9fj-4mwv, XSS in the FPM status
  page). NEWS hunk dropped; the code applies unchanged (5.4 has the same function and
  `ENT_DISALLOWED`/`ENT_HTML_DOC_XML1`).
  sha256 `57c65ec2dc7aad66e26fd8006e37e89686e594de0d076195d9e5b2b640e2520f`
- `0260-…-php54.patch` — **GH-22187** (heap overflow in `openssl_encrypt()`/
  `openssl_decrypt()` with AES-WRAP-PAD, no CVE id). NEWS hunk dropped; the same block
  is added after the `outlen` computation, whose surrounding code differs in 5.4. It is
  guarded by `#ifdef EVP_CIPH_WRAP_MODE`, which OpenSSL 1.0.1t (wheezy) and 0.9.8
  (squeeze) do not define, so it compiles to nothing on these releases: their PHP cannot
  use wrap mode and is not affected. Carried for parity with the other targets.
  sha256 `42e39338c857cccfc6493021c2f8130ae70cbc56410c381546b62a032ab370f4`
