# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 7.4.33-38+debsuryorg12.1+1` package (packages.sury.org), whose
`debian/patches/0163-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `7.4.33-36` it also has the security fixes Sury backported from PHP 8.2.36, such as CVE-2026-129538 and CVE-2026-129496 (see `debian/changelog`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- built with debhelper 10 from xenial-backports (Sury's packaging needs >= 9.20160709),
- built against the **system** PCRE2 10.31 taken from bionic (xenial has 10.21, Sury
  requires >= 10.30), for the same reason as `debian9-stretch/php7.4-sury`,
- the secure-DNS telemetry patch `0127` and its follow-up `0194` are dropped from the series,
- shipped alongside: from bionic `libargon2-0` 0~20161029-1.1 (xenial has no argon2) and
  `libtidy5` 5.2.0 (xenial has only the 2009 libtidy-0.99), both depending only on
  glibc >= 2.14, and `php-common` rebuilt from Sury's `php-defaults` 106~exp1+debsuryorg12.1+1
  (`.dsc` SHA256 pinned in `build/build.conf`) without the `Breaks` field of `php-common`:
  it lists older PECL extension packages (`php-apcu (<< 5.1.24-1~)`, `php-imagick
  (<< 3.7.0-12~)`, …) that do not work with PHP 8, and would make apt remove working
  extensions here.
