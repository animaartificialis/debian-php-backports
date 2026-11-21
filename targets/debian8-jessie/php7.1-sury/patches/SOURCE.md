# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.1 7.1.33-86+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0185-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `7.1.33-81` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
Since `7.1.33-84` it also has the security fixes Sury backported from PHP 8.2.36, such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the minimum versions of `libzip-dev` and `libtidy-dev` in `debian/control` are
  relaxed (`CONTROL_SED`); PHP 7.1 supports the versions jessie has,
- the secure-DNS telemetry patch `0176` and its follow-up `0298` are dropped from the series,
- Sury's `php-common` 2:102 (arch all), required by `php7.1-common`, is shipped alongside.
