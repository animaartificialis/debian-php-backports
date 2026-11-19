# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-109+debsuryorg12.1+php+1` package (packages.sury.org), whose
`debian/patches/0260-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `5.6.40-105` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
Since `5.6.40-108` it also has the security fixes Sury backported from PHP 8.2.36 (11 of the 12 CVEs; CVE-2026-127960 is not listed for 5.6), such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the minimum versions of `libzip-dev` and `libtidy-dev` in `debian/control` are
  relaxed (`CONTROL_SED`); PHP 5.6 supports the versions jessie has,
- dropped from the series: `0052-Adjust-tidy-extension-for-tidy-html5.patch` (jessie has
  the old libtidy with `buffio.h`) and the secure-DNS telemetry patch with its follow-up `0389` (it also needs
  libsodium >= 1.0.12),
- Sury's `php-common` 2:101 (arch all), required by `php5.6-common`, is shipped alongside.
