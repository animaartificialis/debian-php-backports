# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 1:7.4.33-38+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0163-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `7.4.33-36` it also has the security fixes Sury backported from PHP 8.2.36, such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0127` and its follow-up `0194` are dropped from the series,
- shipped alongside: `libargon2-1` and `libpcre2` 10.32 from buster (system PCRE2 for
  ABI compatibility with existing extensions, see `php7.3-sury`), and `php-common` rebuilt from Sury's `php-defaults` 108~exp1+debsuryorg12.1+1
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here.
