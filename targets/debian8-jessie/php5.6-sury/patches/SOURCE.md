# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-104+0~20261021.134+debian12~1.gbp7401dd` package (packages.sury.org), whose
`debian/patches/0251-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the minimum versions of `libzip-dev` and `libtidy-dev` in `debian/control` are
  relaxed (`CONTROL_SED`); PHP 5.6 supports the versions jessie has,
- dropped from the series: `0053-Adjust-tidy-extension-for-tidy-html5.patch` (jessie has
  the old libtidy with `buffio.h`) and the secure-DNS telemetry patch (it also needs
  libsodium >= 1.0.12),
- Sury's `php-common` 2:101 (arch all), required by `php5.6-common`, is shipped alongside.
