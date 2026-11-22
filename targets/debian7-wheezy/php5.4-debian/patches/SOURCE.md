# Patch provenance

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
| `0395-…-php54` | CVE-2026-129506 | GHSA-4646-p932-gw34 | same code change, other context, see below; Sury's code since 2026-11-20 |
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
- `0395-…-php54` (replaced on 2026-11-20 by a port of Sury's file, when `0296` was
  added; see the next section): as on jessie, `cleanup_xml_node()` is the older recursive version
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
- `0395-…-php54` `5a57edbdebd9d93f52a9fea331cfa998715f98d452e23751e5340bf44aa828fe` (replaced on 2026-11-20, see the next section)
- `0396-…-php54` `9d58d0c662610260b4bfb6bdfa58bcedc87aaa3bfef7f5f47a762d7dfdab8cca`
- `0397-…-php54` `0c65fc172d8328d2c2bc25799e8d2f0e81adacfc873b61425db9f80d258085e0`
- `0398-…-php54` `2f018f586bb5d049b975b2d5a64599d71edab982893290d69e7d027f5e765636`
- `0399-…-php54` `51d142776e7599bf19e65901d74829b79ce0a48b7f2c0497b63283822cb3e90d` (replaced on 2026-11-20, see the next section)
- `0400-…-php54` `d63bbe3322e8e9c4a27070226db87d54ad7eb095b6beae4fde9eb46a0ccf7765`

Sury's 5.6.40-106 and -107 backports (0264–0389) and the 2020+ fixes were not checked
in this round; they are added in the next section.

## Fixes from 2020 to 2026 that deb7u30 does not have (added 2026-11-20)

deb7u30 (May 2020) is the last ELTS update of wheezy's PHP, so these targets had none of
the fixes from 2020 on. The gap analysis of 2026-11-19 lists 43 missing fixes for 5.4.
38 of them are added here. Where Freexian ELTS fixed jessie's PHP 5.6, its patch is the
source, because it is closest to 5.4; the other fixes come from Sury's php5.6 5.6.40-109
(the same tarball as the jessie target, sha256 `ab7d01f4…a0b`).

- ELTS source: http://deb.freexian.com/extended-lts/pool/main/p/php5/php5_5.6.40+dfsg-0+deb8u23.debian.tar.xz,
  sha256 `a9bb07558803ef70ea0f860cfdefd2006ad35fc99735dd2ef111bc6d10b9952e`, files
  `debian/patches/<name>.patch` (deb8u13 to deb8u23).

Each patch was regenerated with `git diff` against the deb7u30 tree with all earlier
patches applied (all apply with `patch --fuzz=0`); each header has the source header and
a `debian-php-backports:` note that says what changed. Tests are kept, except where a
test needs a 5.6 feature (see the notes). The new patches go after `0260` and before
`0390`, in this order: first the ELTS patches (in ELTS's order), then the Sury patches
(in Sury's order). `0390`–`0398` and `0400` are unchanged and still apply; `0399` is
regenerated (context only, see below), and `0395` is now Sury's (see below).

From ELTS (file `CVE-…-php54.patch` = ELTS's `CVE-….patch`):

| Patch | CVE | Bug | 5.4 |
|---|---|---|---|
| `CVE-2020-7070-php54` | CVE-2020-7070 | cookie names were URL-decoded (`__Host-` spoofing) | unchanged |
| `CVE-2020-7068-php54` | CVE-2020-7068 | Phar: use after free when parsing a zip | unchanged |
| `CVE-2020-7071-php54` | CVE-2020-7071 | `FILTER_VALIDATE_URL` accepts invalid userinfo | unchanged |
| `CVE-2021-21702-php54` | CVE-2021-21702 | SOAP: NULL dereference in WSDL parsing | unchanged |
| `CVE-2021-21704-php54` | CVE-2021-21704 | pdo_firebird: several overflows and crashes | unchanged |
| `CVE-2021-21705-php54` | CVE-2021-21705 | `FILTER_VALIDATE_URL`: SSRF bypass via the password | unchanged |
| `CVE-2021-21707-php54` | CVE-2021-21707 | XML functions: `%00` in URIs truncates the path | unchanged |
| `CVE-2022-31625-php54` | CVE-2022-31625 | pgsql: free of an uninitialized array after a failed parameter conversion | completed, see below |
| `CVE-2022-31626-php54` | CVE-2022-31626 | mysqlnd: buffer overflow with a long password | unchanged |
| `CVE-2022-31628-1-php54`, `-2-php54` | CVE-2022-31628 | Phar: endless loop with a "quine" gzip file | unchanged |
| `CVE-2022-31629-php54` | CVE-2022-31629 | cookie names mangled into `__Host-`/`__Secure-` | unchanged |
| `CVE-2023-0567-php54` | CVE-2023-0567 | bcrypt: invalid hashes pass validation | adapted, see below |
| `CVE-2023-0568-php54` | CVE-2023-0568 | one byte overrun when a slash is appended to a path | unchanged |
| `CVE-2022-31631-php54` | CVE-2022-31631 | pdo_sqlite: `PDO::quote()` may return an unquoted string | unchanged |
| `CVE-2023-3823-php54` | CVE-2023-3823 | XXE through libxml2 global state | one hunk by hand, see below |
| `CVE-2023-3824-php54` | CVE-2023-3824 | Phar: buffer overflow in `phar_dir_read()` | adapted, see below |
| `CVE-2024-2756-php54` | CVE-2024-2756 | `__Host-`/`__Secure-` bypass (incomplete CVE-2022-31629 fix) | unchanged |
| `CVE-2024-5458-php54` | CVE-2024-5458 | `FILTER_VALIDATE_URL` bypass with invalid host names | unchanged |
| `CVE-2024-8925-php54` | CVE-2024-8925 | multipart parsing with very long boundaries | unchanged |
| `CVE-2024-8927-php54` | CVE-2024-8927 | `cgi.force_redirect` bypass through `HTTP_REDIRECT_STATUS` | unchanged |
| `CVE-2024-11233-php54` | CVE-2024-11233 | 1 byte over-read in `convert.quoted-printable-decode` | unchanged |
| `CVE-2024-11234-php54` | CVE-2024-11234 | HTTP wrapper: CRLF injection with `request_fulluri` | unchanged (comes before `0399`) |
| `CVE-2024-11236-01-php54`, `-02-php54` | CVE-2024-11236 | integer overflow in the dblib and firebird quoters | unchanged |
| `GHSA-4w77-75f9-2c8w-php54` | — | CLI server: use after free of the content type | unchanged |

From Sury's php5.6 5.6.40-109 (file `NNNN-…-php54.patch` = Sury's `NNNN-….patch`):

| Patch | CVE | Advisory | Bug | 5.4 |
|---|---|---|---|---|
| `0210` | CVE-2023-3247 | GHSA-76gg-c692-v2mw | SOAP HTTP Digest: too few random bytes in the cnonce | NEWS hunk dropped |
| `0264` | CVE-2026-17543 | GHSA-7qpv-r5mr-78m4 | pgsql: SQL injection via `E'...'` backslash breakout | adapted tests, see below |
| `0265` | CVE-2026-7260 | GHSA-vc5h-9ppw-p5f3 | Phar: stack overflow on circular symlinks | unchanged |
| `0282` | CVE-2025-1220 | GHSA-3cr5-j632-f35r | NUL byte in host names | other context, see below |
| `0283` | CVE-2025-6491 | GHSA-453j-q27h-5p8x | SOAP: NULL dereference with a huge namespace prefix | unchanged |
| `0284` | CVE-2025-1735 | GHSA-hrwm-9436-5mv3 | pgsql, pdo_pgsql: escaping errors not checked | adapted, see below |
| `0286` | — | GHSA-www2-q4fc-65wf | `dns_get_record()` and others: NUL bytes in names | unchanged |
| `0287` | CVE-2025-14177 | GHSA-3237-qqm7-mfv7 | `getimagesize()`: uninitialized memory in APPn data | unchanged |
| `0292` | CVE-2026-6722 | GHSA-85c2-q967-79q5 | SOAP: stale `ref_map` pointer, use after free | unchanged |
| `0296` | CVE-2026-91765 | GHSA-rgrp-mwpx-f6rm | SOAP: unbounded recursion in XML cleanup and decoding | other context in `php_soap.h` |
| `0297` | CVE-2025-14181 | GHSA-cj93-vc83-wgqv | SOAP HTTP client: integer overflow in response parsing | unchanged |
| `0300` | CVE-2026-92842 | GHSA-88hq-2827-7pg6 | `convert.*` filters: overflow with NUL in `line-break-chars` | unchanged |
| `0301` | — | GHSA-ch8v-r6jh-4vvr | `FILTER_SANITIZE_ENCODED` did not encode 0xFF | unchanged |
| `0310` | CVE-2026-6103 | GHSA-j3wh-g957-2m85 | Phar TAR: integer overflow lets an entry be injected | unchanged |
| `0316` | CVE-2026-6722 | GHSA-85c2-q967-79q5 | 5.6 part of `0292` (without it `0292` frees a value twice) | unchanged |
| `0395` | CVE-2026-129506 | GHSA-4646-p932-gw34 | (from the previous round) | now Sury's code, see below |

Notes and adaptations (also in each patch header):

- `CVE-2022-31625`: ELTS's patch changes only `pg_query_params()`. The upstream commit
  (55f6895f, Sury's `0195`) also changes `pg_send_execute()`. In 5.4 the same code (an
  array from `safe_emalloc()` freed up to `num_params` when converting a parameter fails)
  is in all four functions that take parameters, so `pg_query_params()`, `pg_execute()`,
  `pg_send_query_params()` and `pg_send_execute()` all get the same one-line change.
  (Applied as is, the ELTS hunk would land on `pg_execute()` in 5.4, because the four
  blocks have the same context.)
- `CVE-2023-0567`: 5.4's `BF_decode()` does not have the `end - dptr == size` check that
  ELTS removes; only the two "PHP hacks" are removed (the `$` break in
  `BF_safe_atoi64()` and the zero fill), as upstream. The `password_bcrypt_short.phpt`
  test is dropped (5.4 has no `password_verify()`).
- `CVE-2023-3823`: in `_dom_document_schema_validate()` 5.4 does not call
  `xmlSchemaSetValidOptions()`, so the sanitize macro goes before
  `xmlSchemaSetValidErrors()`. The other hunks apply unchanged.
- `CVE-2023-3824`: 5.4 converts the key with `PHAR_STR()`/`PHAR_STR_FREE()` and checks
  `zend_hash_has_more_elements()` first; both are kept. The checks and the copy are
  ELTS's (count must be `sizeof(php_stream_dirent)`, the key must fit into `d_name`, the
  name is terminated at `keylen`).
- `CVE-2021-21707`: as in ELTS, the new `php_error_docref()` calls have no `TSRMLS_CC`;
  this only matters for ZTS builds, and Debian builds PHP without ZTS.
- `CVE-2024-11234` changes a context line of `0399`, so `0399` is regenerated; its code
  change is the same.
- `0264`: the code change is Sury's (no more `E` before the quoted value). Its second
  pgsql.c hunk only removes a comment that 5.4 does not have. Two tests that are not in
  5.4 are dropped, two others are changed the same way in their 5.4 form, and the
  `PGSQL_DML_ESCAPE` part of the new test is removed (5.4 has no `PGSQL_DML_ESCAPE`).
  The `E` was only needed with `standard_conforming_strings=off`, where
  `PQescapeStringConn()` already doubles backslashes; bytea values are escaped with
  `PQescapeByteaConn()`, which also follows the connection's setting.
- `0282`: the NUL check is added at the start of `parse_ip_address_ex()`; 5.4 already
  declares `p` inside the IPv6 branch, so Sury's move of that declaration is not needed.
- `0284`: 5.4's pdo_pgsql quoter still has the fallbacks to `PQescapeBytea()` and
  `PQescapeString()` without a connection, so the NULL check comes after either call,
  and the error check after the `#endif` (`err` stays 0 with `PQescapeString()`). The
  four hunks for the `PGSQL_DML_ESCAPE` paths of `php_pgsql_insert()` and
  `build_assignment_string()` are dropped: that flag (5.6) does not exist in 5.4, and
  these functions take their values from `php_pgsql_convert()`, which has the check. The
  text value hunk of `php_pgsql_convert()` is placed by hand (other context). As on
  jessie, `PDO::quote()` and the PDO placeholder parser check the quoter's return value,
  so the NULL dereference of CVE-2025-14180 (PHP 8 only) does not appear.
- `0296` + `0395`: `0296` rewrites `cleanup_xml_node()` without recursion. Only
  `php_soap.h` differs: 5.4 has no `SOAP_SSL_METHOD_*` defines, so the two new defines
  go after `WSDL_CACHE_BOTH`. The `LIBXML_VERSION < 21300` branch is the one built here
  (libxml2 2.8.0 on wheezy, 2.7.8 on squeeze): documents nested deeper than 2048 are
  rejected. Our earlier `0395` was written against the old recursive function; Sury's
  `0395` applies unchanged on top of `0296`, so the file now has Sury's code change.
- `0292` + `0316`: as on jessie, both are needed (`0316` is the 5.6 part, also right for
  5.4: `parse_packet_soap()` freed the returned value while `ref_map` still pointed to
  it).

Behaviour and limits worth knowing:

- A WSDL nested about 100000 deep still crashes, but inside libxml2's own recursive
  parser (2.8.0 on wheezy, 2.7.8 on squeeze), before PHP sees the tree;
  `DOMDocument::loadXML()` crashes the same way. That is outside of PHP (as on jessie).
- On squeeze (libpq 8.4, no `PQescapeLiteral()`), `pg_escape_literal()` and
  `pg_escape_identifier()` use PHP's own fallback, which does not check the encoding, so
  they still return a quoted string for invalid UTF-8 where wheezy returns `false`. This
  is unchanged by this round.
- Some of the new test files from Sury and ELTS use syntax newer than PHP 5.4 (return
  types, `[...]` defaults, variadics) and fail on 5.4; they are kept as shipped. The
  package build does not run the test suite (`nocheck`).

Also not added: the older Sury hardening patches without an id (0127, 0166, 0181 and
others in section (a-3) of the gap analysis) and `0380` (SOAP bailout handling).

Not added here (left for a later round, B2): CVE-2021-21703 (FPM scoreboard in shared
memory, local root; 5.4's scoreboard layout differs, so this is a large adaptation),
CVE-2024-8929 (mysqlnd heap over-read; Sury `0267`, `0268`, `0311`) and CVE-2025-1218
(`0322`, `0323`, which depend on it), and the CVE-2025-1736 chain (`0274`–`0277`)
with CVE-2026-91766 (`0294`, which must come after it).

Not applicable to 5.4 (see the gap analysis): CVE-2026-91767, CVE-2026-91769 (5.4
checks only the CN, not the SAN), CVE-2026-91768 (5.4's FastCGI ACL is IPv4 only).

Also not applicable to 5.4 (checked against the 5.4 code, 2026-11-22):

- CVE-2024-3096 (`password_verify()` and NUL bytes): 5.4 has no `password_hash()` or
  `password_verify()` (added in 5.5).
- CVE-2024-8932 (`ldap_escape()` overflow): 5.4 has no `ldap_escape()` (added in 5.6).
- CVE-2025-1219 (libxml streams use the wrong Content-Type after a redirect): the bug is
  in code that reads the HTTP headers to find the document's charset (added with the
  fix for bug #51903). 5.4's `ext/libxml` does not read the HTTP headers at all.

Patch sha256:

- `CVE-2020-7070-php54` `f936d8030b1619b2b0276b8260cf528f6277d28466506c5e675f421daa5f8b81`
- `CVE-2020-7068-php54` `748b06b67223b2d3bc2d0cdb8504e06681e88a2dd810e6eab3bfd558e3d08b5f`
- `CVE-2020-7071-php54` `7be420b8e297845808f05c3da3cd54c9d861c60ad44ed3545a49d6a94ead1f0a`
- `CVE-2021-21702-php54` `9f562df516a6ac86405eb7efe01d5abe3a563526579de778fb57d8babd88c2a0`
- `CVE-2021-21704-php54` `2ad9f4cbee924c9e598b0645abdd21e0e929f539aaa063ddbf2ea74f58c4c2b2`
- `CVE-2021-21705-php54` `69f9eb4cb4b2c5c33f1d57194eade80a1f47f076c1328134b8b68f45e17271fd`
- `CVE-2021-21707-php54` `429a6d878e24d924e3787a27af4146d67751a056dc14ea49937975595e217ef5`
- `CVE-2022-31625-php54` `061a7bf18d94550c8bd67f5b8df8f032e33a368464f879a74469f8f6cc2264c9`
- `CVE-2022-31626-php54` `776161b942a0ad1ca9db639737537909fa1e3ad73c8f00295aa1499b484e9ac5`
- `CVE-2022-31628-1-php54` `ab6db9bc9dd0da00ce5d4b9c3ea62ca25815bd4d161b022f740fb9fbfdc78e57`
- `CVE-2022-31628-2-php54` `e5285df7cb2a9c2e1328894ed35b8aa7daa52f8a6e966fcfb2b0310f52ccc0fc`
- `CVE-2022-31629-php54` `18f4a7a5846141d8715c79f6d9c19e74ad8bcd8486e0833b2c76fcb57ea5a031`
- `CVE-2023-0567-php54` `1880a6ca5f7df44087bfb1eeb5a186c002c3d254f3d1018a25e92e68cbe65acb`
- `CVE-2023-0568-php54` `2efa96ea80681f07865488f0131b1ad4fd15bc6ad55659e539ecee9a6bf81e61`
- `CVE-2022-31631-php54` `6bb7c5b3ec967d22a237d3ef6df10a1e640f5f5bf4eeeae45917a3bab58291f6`
- `CVE-2023-3823-php54` `0ee3c4a23490187bbeafda9c50811b309bb1facbfbebbb6bf5ec629684379108`
- `CVE-2023-3824-php54` `b9ed59c3ae645dd80dd5c656667622fff14ffec4091202d975b02c054b36576e`
- `CVE-2024-2756-php54` `40d0e01f2f40619011afd8db6e517a648ad54ae9fc498d211b963317f51b74c4`
- `CVE-2024-5458-php54` `c813209a6b1ae73341d9f089c0983f5d9500798cba52015e7b95f613ee5d1b91`
- `CVE-2024-8925-php54` `7770c62aca30e5ca35eb59c038caeafd90e824043e6f483134970798059d089c`
- `CVE-2024-8927-php54` `5deb78608600a7b768ddf710a9bc81a7d0bb90c77c81300417de7f42f3c21784`
- `CVE-2024-11233-php54` `11bd491090de9721286c6d514faaebb014d07bded499636ca1b2c9a0e2091096`
- `CVE-2024-11234-php54` `81b8952e10795b5a089cf7baf4cd072df4ccf0bdd12728c3986a6677edff1eaf`
- `CVE-2024-11236-01-php54` `4dfa2f06d0b23c9290cab65e77024977098aee516babd6fe9c97d7205a195d95`
- `CVE-2024-11236-02-php54` `c52c5448a164f04dbb2c4ffeb196ccfac38dd2ce3d61dbd5e74a6199ea0e6db2`
- `GHSA-4w77-75f9-2c8w-php54` `cc150ae99a3d5c42261052fe2040b9479e0cef9a01736e441227c0059d5ab097`
- `0210-…-php54` `f85ef0998cf848c2c30a6893fcfc016c8e72a5c6945dfc885219fdabedf62891`
- `0264-…-php54` `3bb43dbcdde4cfc9ae4fdc68139305d510eb03d7f4ec2f029be7976139f6f86d`
- `0265-…-php54` `02522de046764e0b6e650905e8591ba0925a03f4b3078b73531792f98730cc5f`
- `0282-…-php54` `6c5fe063d402b6917758ddc0a1e3647c6e5897bed848747a6e4c1663b070c2da`
- `0283-…-php54` `d4d037d6136b0478f4af01bf794386b75e2af71f6c0e66273502f40c505d3c62`
- `0284-…-php54` `cf3ebb66d0fca75adad20637dc8c73eb00031172f350d3e1ce359410a07d66c5`
- `0286-…-php54` `a32b6693bafa7de5642f595cf828fe77dcc48be3057b8548a9c0efb2c606d647`
- `0287-…-php54` `1a29ed14b6812bed75c813f4852e052555bb92ed24e1190c1f72bf7b07c1c99a`
- `0292-…-php54` `261f1d41922b839c0b7319fc6e73e0beef8a5629cd1e591c8bf807607d75db30`
- `0296-…-php54` `527d290fc7673784f154ff9d1524b4d10d88aa076889f531bc6975d75ef7db9c`
- `0297-…-php54` `ad929b483900418f16ab534e8e9a6c2d941617cdd10520c13152dfe371e00091`
- `0300-…-php54` `fd78ce854aa1635439f7c5c28d96bdcb55ed13077ffb9e89e4cf8dd91ce1971c`
- `0301-…-php54` `02ce5c5de3ac47464069f4a3463c011ccc81d9d09dd4d6db3f929099617dd3cc`
- `0310-…-php54` `92b122987520c0c11b2db92696be57d936e8cfc06a90fa940227b1b208108c3d`
- `0316-…-php54` `da66bfaf259b9827f5628c1b7bd98fd6fce6c6e9f55cf20257811aa0957c6bdd`
- `0395-…-php54` `e1c06194689177eb09656868bd2052930663491378903ac2af7cb48cf4e42bc2`
- `0399-…-php54` `1a81fe4e2515d63010d7bc3fa8458dd61b083650564f5dd44eeb52086a397315`
