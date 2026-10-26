# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php5.6 5.6.40-105+0~20261022.135+debian12~1.gbp37a17e` package (packages.sury.org), whose
`debian/patches/0261-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and CVE-2026-109619.
Since `5.6.40-105` it also has the CVE-2023-0662 backport (`max_multipart_body_parts`).
The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0251` is dropped from the series,
- built with debhelper compat 9: trusty's debhelper is 9.20131227, trusty-backports has
  no newer one (same as the trusty php7.4 target), with trusty's `dh-systemd`,
- built without `-Wno-error=incompatible-pointer-types`: gcc 4.8 does not know that
  warning (it came in gcc 5), and an unknown `-Wno-error=` is a hard error,
- built against trusty's PCRE 8.31 (`libpcre3` 1:8.31): the packaging asks for
  `libpcre3 (>= 2:8.35)`, the epoch of xenial's 8.38, and the dependency is relaxed in
  `debian/control` and `debian/control.in`. PHP 5.6 builds and runs with 8.31 (trusty's own
  PHP 5.5 uses it); a newer `libpcre3` would replace a core trusty package,
- `php5.6-fpm` uses trusty's `libsystemd-daemon` (systemd 204) for `sd_notify` instead of
  `libsystemd` (`libsystemd-dev` replaced by `libsystemd-daemon-dev` in Build-Depends):
  PHP 5.6's configure falls back to it, so no `libsystemd0` from xenial is needed,
- shipped alongside: a `php-common` rebuilt from Sury's `php-defaults` source without
  its `Breaks` on older PECL extension packages (`REBUILD_PHP_COMMON=1`), bionic's
  `libtidy5` 5.2.0 and xenial's `libzip4` 1.0.1 (the same files the trusty php7.4 target
  ships),
- only installed for the build (`EXTRA_DEB_BUILD_ONLY`): `libtidy-dev`, `libzip-dev` and
  trusty's `dh-systemd`. Everything else comes from trusty itself, including its
  OpenSSL 1.0.1f, ICU 52, libgd 2.1.0 and Apache 2.4.7 (`apache2-dev` from trusty-updates).
