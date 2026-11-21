# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-110+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0260-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `5.6.40-105` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
Since `5.6.40-108` it also has the security fixes Sury backported from PHP 8.2.36 (11 of the 12 CVEs; CVE-2026-127960 is not listed for 5.6), such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0250` and its follow-up `0389` are dropped from the series,
- shipped alongside: `php-common` rebuilt from Sury's `php-defaults` 102+debsuryorg12.1+3
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here.
