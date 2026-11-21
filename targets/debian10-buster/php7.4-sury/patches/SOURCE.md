# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 1:7.4.33-38+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0163-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `7.4.33-36` it also has the security fixes Sury backported from PHP 8.2.36, such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.
