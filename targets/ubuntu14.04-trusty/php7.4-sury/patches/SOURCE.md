# Patch provenance

No additional patches. The source is Ondřej Surý's complete
`php7.4 1:7.4.33-31+0~20261021.121+debian11~1.gbpe9c428` package (packages.sury.org), whose
`debian/patches/0164-Avoid-state-corruption-via-bailout.patch` fixes CVE-2026-109618 and
CVE-2026-109619. The `.dsc` SHA256 is pinned in `target.conf`.

Changes:

- the secure-DNS telemetry patch `0128` is dropped from the series,
- built with debhelper compat 9: trusty's debhelper is 9.20131227, trusty-backports has
  no newer one, and a newer debhelper needs a dpkg-dev that trusty cannot take. Neither
  the php7.4 source nor the `php-common` rebuild uses a compat-10-only helper; for the
  latter, `build-php-common.sh` lowers the compat level the same way,
- built without `-Wno-error=incompatible-pointer-types`: gcc 4.8 does not know that
  warning (it came in gcc 5), and an unknown `-Wno-error=` is a hard error,
- LDAP's SASL support and mbstring's oniguruma are linked through `SASL_CFLAGS`/
  `SASL_LIBS` and `ONIG_CFLAGS`/`ONIG_LIBS` in `debian/rules`: trusty's libsasl2-dev
  and libonig-dev ship no pkg-config files, and xenial's libsasl2 runtime cannot
  replace trusty's in one dpkg call (its `modules-db` Breaks the older `libsasl2-2`),
- built with trusty's libgcrypt 1.6.1 (the packaging asks for > 1.6.3); only the
  deprecated gcrypt extension uses it,
- shipped alongside: a `php-common` rebuilt from Sury's `php-defaults` source without
  its `Breaks` on older PECL extension packages (`REBUILD_PHP_COMMON=1`), bionic's
  `libargon2-0` and `libtidy5` 5.2.0, bionic's `libpcre2` 10.31, xenial's `libpcre3`
  8.38 and `libstdc++6` 5.3.1
  (bionic's `libpcre2-dev` conflicts with trusty's `libpcre3-dev`, and the newer one
  needs the newer C++ runtime), xenial's `libzip` 1.0.1 and `libsystemd` 229 (trusty
  predates `libsystemd0`), and xenial's `apache2-dev` 2.4.18, which provides
  `dh-apache2`. trusty's `libpcre3-dev` is purged in the builder so the newer one can
  replace it. Everything else comes from trusty itself, including its libonig 5.9.
