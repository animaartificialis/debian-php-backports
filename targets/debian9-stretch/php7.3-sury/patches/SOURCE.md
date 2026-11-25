# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.3 7.3.33-42+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0142-Avoid-state-corruption-via-bailout.patch` and `0144-missing-in-previous-Avoid-state-corruption-via-bailo.patch`
fix CVE-2026-109618 and CVE-2026-109619. Since `7.3.33-36` it also has the security fixes Sury
backported from PHP 8.1.32 to 8.2.34 (see `debian/changelog`). Sury publishes `7.3.33-42` only for
Debian 12/13 and Ubuntu 22.04+; the Debian 12 build is used, its `debian/` directory is the same
as the others except for the changelog trailer.
Since `7.3.33-40` it also has the security fixes Sury backported from PHP 8.2.36, such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- built against the **system** PCRE2 10.32 taken from buster (stretch has 10.22, Sury
  requires >= 10.30). Not PHP's bundled copy: that one prefixes its symbols and breaks
  third-party extensions built against stretch PHP (e.g. `apcu.so: undefined symbol:
  pcre2_match_8`),
- the secure-DNS telemetry patch `0125` and its follow-up `0224` are dropped from the series,
- shipped alongside: `libargon2-1` 0~20171227-0.2 from buster (stretch's is older than
  PHP 7.3 needs; it depends only on glibc >= 2.14), and `php-common` rebuilt from Sury's `php-defaults` 106~exp1+debsuryorg12.1+1
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here.
