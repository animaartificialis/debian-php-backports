# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.2 7.2.34-66+0~20261021.122+debian11~1.gbpe0bcd4` package (packages.sury.org), whose
`debian/patches/0159-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0144` is dropped from the series.

Nothing is shipped alongside: `php7.2-common` depends on `php-common (>= 1:81~)`, which focal's
own 2:75 satisfies (higher epoch); everything comes from focal itself.
