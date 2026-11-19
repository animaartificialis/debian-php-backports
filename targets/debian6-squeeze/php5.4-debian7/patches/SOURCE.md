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

## PHP 8.2.36 fixes (added 2026-11-19)

Ported from deb.sury.org php5.6 5.6.40-109 (patches 0390–0400, the backports of PHP
8.2.36; tarball and checks as in `targets/debian8-jessie/php5.6-debian/patches/SOURCE.md`).
Each was regenerated with `git diff` against the deb7u30 tree with all earlier patches
applied; each header says what changed. For 11 of the 12 CVEs the 5.4 code is the same
as in 5.6, and the code change is unchanged:

| Patch | CVE | Advisory | 5.4 |
|---|---|---|---|
| `0390-…-php54` | CVE-2026-15353 | GHSA-q23r-hr55-xmpg | same code, applies unchanged |
| `0391-…-php54` | CVE-2026-128090 | GHSA-68fq-fh7h-f8gr | same code, applies unchanged |
| `0392-…-php54` | CVE-2026-129538 | GHSA-5j3f-64r7-f564 | same code, applies unchanged |
| `0393-…-php54` | CVE-2026-129292 | GHSA-3mg3-cr28-46gc | same code (with `0257-…-php54`), applies unchanged |
| `0394-…-php54` | CVE-2026-129289 | GHSA-qc49-hpvq-g2w6 | bug not in 5.4; only the FastCGI safeguard, see below |
| `0395-…-php54` | CVE-2026-129506 | GHSA-4646-p932-gw34 | same code change, other context, see below |
| `0396-…-php54` | CVE-2026-129496 | GHSA-gr4f-wgx5-jpfv | same code, applies unchanged |
| `0397-…-php54` | CVE-2026-126714 | GHSA-fm2m-fjf5-v3cp | same code, applies unchanged |
| `0398-…-php54` | CVE-2026-115560 | GHSA-658j-r8rw-q6mx | same code; upload progress already off through `0001` |
| `0399-…-php54` | CVE-2026-128064 | GHSA-f6gg-rchx-xw8j | same code, other context lines |
| `0400-…-php54` | CVE-2026-129291 | GHSA-jm4m-qfqx-967m | same code, applies unchanged |

Notes:

- `0394-…-php54` (CVE-2026-129289): the bug came with the lazy `php://input` stream in
  PHP 5.6.0. In 5.4, `sapi_deactivate()` either has the whole body in `post_data` (read
  up to `CONTENT_LENGTH`) or reads the rest with `sapi_module.read_post()` until it
  returns 0, so an unread body cannot stay on the connection. The `main/SAPI.c` hunk is
  dropped. Kept is the second part of the fix, the safeguard in `sapi/cgi/fastcgi.c`
  and `sapi/fpm/fpm/fastcgi.c`: a new FastCGI request is refused (and the connection
  closed) while the previous `FCGI_STDIN` record is only partly read.
- `0395-…-php54`: as on jessie, `cleanup_xml_node()` is the older recursive version
  (without Sury's GHSA-rgrp-mwpx-f6rm rewrite), so only the context differs. The new
  `XML_DTD_NODE` branch sits before the branch that deletes non-element nodes. As in
  5.6, only WSDL and schema loading (`soap_xmlParseFile()`) runs this cleanup, so the
  bug is reachable through an attacker-controlled WSDL or schema, not a SOAP request.
- `0398-…-php54` only changes the default of `session.upload_progress.enabled` to 0;
  `0001` already turns upload progress off at run time.
- `0400-…-php54`: as on jessie, 5.4's `fpm_child_close()` closes the pipe without
  removing its epoll event and frees the worker record at once.

Not applicable:

- **CVE-2026-127960** (GHSA-mmf9-xm3v-hg2x, quadratic joining of folded HTTP response
  headers): the code is not in 5.4. It came with the CVE-2025-1217 fix (folded header
  support in the HTTP wrapper), which deb7u30 (2020) does not have; 5.4's HTTP wrapper
  stores each header line as it is read. (jessie has that code from ELTS and gets an
  own port, `0401` there.)

Patch sha256:

- `0390-…-php54` `b05177255b9b8d18e589ee651277c74a39529f83a09b22d950c40320983f1c92`
- `0391-…-php54` `739d6fd807cb39698fdedf1bd74731f3dbebc24dadc687140d03049c81cdc2ba`
- `0392-…-php54` `ee8aaa580f448cf9657e695ca8b006b07a3dc611f3d8ca69f384ac1190eba089`
- `0393-…-php54` `9a9b98029a422180cc8fc82a370a7decf40c8ff9d4c4008bed0a4a6a14a16abb`
- `0394-…-php54` `ba02ce3bdf0565c0517326de8e44530f6946d607a0e5b379f76d742bce83874b`
- `0395-…-php54` `5a57edbdebd9d93f52a9fea331cfa998715f98d452e23751e5340bf44aa828fe`
- `0396-…-php54` `9d58d0c662610260b4bfb6bdfa58bcedc87aaa3bfef7f5f47a762d7dfdab8cca`
- `0397-…-php54` `0c65fc172d8328d2c2bc25799e8d2f0e81adacfc873b61425db9f80d258085e0`
- `0398-…-php54` `2f018f586bb5d049b975b2d5a64599d71edab982893290d69e7d027f5e765636`
- `0399-…-php54` `51d142776e7599bf19e65901d74829b79ce0a48b7f2c0497b63283822cb3e90d`
- `0400-…-php54` `d63bbe3322e8e9c4a27070226db87d54ad7eb095b6beae4fde9eb46a0ccf7765`

Not checked in this round: Sury's 5.6.40-106 and -107 (0264–0389) add many more
backports that these targets do not have yet (and deb7u30 is older than all 2020+
fixes). They need their own review.
