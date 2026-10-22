# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-104+0~20261021.134+debian12~1.gbp7401dd` package (packages.sury.org), whose
`debian/patches/0261-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0251` is dropped from the series,
- shipped alongside: Sury's `php-common` 2:101 (focal has 2:75); everything else comes from focal itself.
