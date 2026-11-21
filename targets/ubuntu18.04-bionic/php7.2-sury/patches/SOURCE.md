# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.2 7.2.34-71+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0160-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `7.2.34-69` it also has the security fixes Sury backported from PHP 8.2.36, such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0143` and its follow-up `0257` are dropped from the series,
- shipped alongside: Sury's `php-common` 2:102 (bionic has 1:60ubuntu1); everything else comes from bionic itself.
