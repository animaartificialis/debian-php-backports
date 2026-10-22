# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 1:7.4.33-31+0~20261021.121+debian11~1.gbpe9c428` package (packages.sury.org), whose
`debian/patches/0164-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0128` is dropped from the series,
- shipped alongside: Sury's `php-common` 2:101 (bionic has 1:60ubuntu1); everything else comes from bionic itself.
