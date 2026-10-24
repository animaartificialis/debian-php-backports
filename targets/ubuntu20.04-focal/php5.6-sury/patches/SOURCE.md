# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-105+0~20261022.135+debian12~1.gbp37a17e` package (packages.sury.org), whose
`debian/patches/0261-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `5.6.40-105` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0251` is dropped from the series,
- shipped alongside: `php-common` rebuilt from Sury's `php-defaults` 101+0~20261021.78+debian11~1.gbp53f25f
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here. Focal's own 2:75 would satisfy the dependencies, but earlier releases
  shipped Sury's binary and only a higher version replaces it. Everything else comes from focal itself.
