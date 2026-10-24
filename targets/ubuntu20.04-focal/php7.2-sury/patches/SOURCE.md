# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.2 7.2.34-66+0~20261021.122+debian11~1.gbpe0bcd4` package (packages.sury.org), whose
`debian/patches/0159-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0144` is dropped from the series,
- shipped alongside: `php-common` rebuilt from Sury's `php-defaults` 101+0~20261021.78+debian11~1.gbp53f25f
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here. Focal's own 2:75 would satisfy the dependencies of PHP 7.2, but the
  focal `php5.6-sury` and `php7.4-sury` targets ship this `php-common`, so the `sury`
  component carries it anyway; shipping it here keeps the tarball and the component
  the same. Everything else comes from focal itself.
