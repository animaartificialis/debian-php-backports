# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-105+0~20261022.135+debian12~1.gbp37a17e` package (packages.sury.org), whose
`debian/patches/0261-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `5.6.40-105` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0251` is dropped from the series,
- shipped alongside: Sury's `php-common` 2:101 (focal has 2:75); everything else comes from focal itself.
