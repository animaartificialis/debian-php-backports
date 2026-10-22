# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.1 7.1.33-80+0~20261021.127+debian12~1.gbp7a3318` package (packages.sury.org), whose
`debian/patches/0186-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the minimum versions of `libzip-dev` and `libtidy-dev` in `debian/control` are
  relaxed (`CONTROL_SED`); PHP 7.1 supports the versions jessie has,
- Sury's `php-common` 2:101 (arch all), required by `php7.1-common`, is shipped alongside.
