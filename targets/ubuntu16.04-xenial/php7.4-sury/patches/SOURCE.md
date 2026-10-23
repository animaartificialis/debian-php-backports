# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 7.4.33-31+0~20261021.121+debian11~1.gbpe9c428` package (packages.sury.org), whose
`debian/patches/0164-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- built with debhelper 10 from xenial-backports (Sury's packaging needs >= 9.20160709),
- built against the **system** PCRE2 10.31 taken from bionic (xenial has 10.21, Sury
  requires >= 10.30), for the same reason as `debian9-stretch/php7.4-sury`,
- the secure-DNS telemetry patch `0128` is dropped from the series,
- shipped alongside: Sury's `php-common` 2:101, and from bionic `libargon2-0`
  0~20161029-1.1 (xenial has no argon2) and `libtidy5` 5.2.0 (xenial has only the 2009
  libtidy-0.99). All of them depend only on glibc >= 2.14.
