# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 1:7.4.33-31+0~20261021.121+debian11~1.gbpe9c428` package (packages.sury.org), whose
`debian/patches/0164-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0128` is dropped from the series,
- shipped alongside: `libargon2-1` and `libpcre2` 10.32 from buster (system PCRE2 for
  ABI compatibility with existing extensions, see `php7.3-sury`), and `php-common` rebuilt from Sury's `php-defaults` 101+0~20261021.78+debian11~1.gbp53f25f
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here.
