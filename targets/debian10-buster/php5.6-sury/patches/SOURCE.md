# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-109+debsuryorg12.1+php+1` package (packages.sury.org), whose
`debian/patches/0260-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `5.6.40-105` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
Since `5.6.40-108` it also has the security fixes Sury backported from PHP 8.2.36 (11 of the 12 CVEs; CVE-2026-127960 is not listed for 5.6), such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0250` and its follow-up `0389` are dropped from the series.
