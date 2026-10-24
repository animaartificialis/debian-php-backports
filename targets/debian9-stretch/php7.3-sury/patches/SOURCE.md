# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.3 7.3.33-35+0~20261021.144+debian11~1.gbpecf76f` package (packages.sury.org), whose
`debian/patches/0139-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- built against the **system** PCRE2 10.32 taken from buster (stretch has 10.22, Sury
  requires >= 10.30). Not PHP's bundled copy: that one prefixes its symbols and breaks
  third-party extensions built against stretch PHP (e.g. `apcu.so: undefined symbol:
  pcre2_match_8`),
- the secure-DNS telemetry patch `0126` is dropped from the series,
- shipped alongside: `libargon2-1` 0~20171227-0.2 from buster (stretch's is older than
  PHP 7.3 needs; it depends only on glibc >= 2.14), and `php-common` rebuilt from Sury's `php-defaults` 101+0~20261021.78+debian11~1.gbp53f25f
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here.
