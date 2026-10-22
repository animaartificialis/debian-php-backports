# debian-php-backports

PHP packages with security fixes for Debian releases that no longer receive them.

> **Only for archived Debian releases: squeeze, wheezy, jessie, stretch and buster.**
> On Debian 11 bullseye and newer, use [deb.sury.org](https://deb.sury.org/) instead —
> it builds every PHP version for supported releases and gets fixes first. Nothing
> here is built for, or should be installed on, a supported release.
>
> The Ubuntu targets, **Ubuntu 18.04 bionic** (PHP 5.6, 7.2, 7.4) and **Ubuntu 20.04
> focal** (PHP 5.6, 7.4), exist for the same reason: the ondrej/php PPA dropped these
> releases when their standard support ended. Their own PHP (bionic 7.2.24, focal 7.4.3)
> is still patched by Canonical through Ubuntu Pro (ESM).

[deb.sury.org](https://deb.sury.org/) builds PHP — including old PHP versions — but only for
Debian and Ubuntu releases that are still supported. Servers running an archived Debian
release (squeeze to buster) get nothing. This repository covers those: it rebuilds PHP
for archived releases with the fixes applied, from sources you can check.

Current fix: **CVE-2026-109618** and **CVE-2026-109619** ("PHP2Shell", RCE via
out-of-memory bailout; [advisory](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)).

## Packages

| Debian | PHP | Component | Source from | Source package | Version |
|---|---|---|---|---|---|
| Debian 6 squeeze | 5.4 | `debian7` | Debian 7 | `php5` | `5.4.45-1+animaa1~squeeze` |
| Debian 7 wheezy | 5.4 | `debian` | Debian 7 | `php5` | `5.4.45-0+deb7u14+animaa1` |
| Debian 8 jessie | 5.6 | `debian` | Debian 8 | `php5` | `5.6.40+dfsg-0+deb8u12+animaa1` |
| Debian 8 jessie | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-104+0~20261021.134+debian8~1+animaa1` |
| Debian 8 jessie | 7.1 | `sury` | deb.sury.org | `php7.1` | `7.1.33-80+0~20261021.127+debian8~1+animaa1` |
| Debian 9 stretch | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-104+0~20261021.134+debian9~1+animaa1` |
| Debian 9 stretch | 7.0 | `debian` | Debian 9 | `php7.0` | `7.0.33-0+deb9u12+animaa1` |
| Debian 9 stretch | 7.3 | `sury` | deb.sury.org | `php7.3` | `7.3.33-35+0~20261021.144+debian9~1+animaa1` |
| Debian 9 stretch | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+debian9~1+animaa1` |
| Debian 10 buster | 7.3 | `debian` | Debian 10 | `php7.3` | `7.3.31-1~deb10u7+animaa1` |
| Debian 10 buster | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+debian10~1+animaa1` |
| Ubuntu 18.04 bionic | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-104+0~20261021.134+ubuntu18.04~1+animaa1` |
| Ubuntu 18.04 bionic | 7.2 | `sury` | deb.sury.org | `php7.2` | `7.2.34-66+0~20261021.122+ubuntu18.04~1+animaa1` |
| Ubuntu 18.04 bionic | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+ubuntu18.04~1+animaa1` |
| Ubuntu 20.04 focal | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-104+0~20261021.134+ubuntu20.04~1+animaa1` |
| Ubuntu 20.04 focal | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+ubuntu20.04~1+animaa1` |

Only `amd64` is built.

### Components

The apt component says where the source comes from, and therefore what adding it does:

- **`debian`** — the PHP version the release itself shipped, rebuilt from the last
  official Debian source with the fix added. A drop-in replacement: `apt-get upgrade`
  replaces only packages you already have, with the same version plus the fix.
  This is what most servers want.
- **`sury`** — Ondřej Surý's PHP packages (which already contain the fix), rebuilt for a
  release he no longer builds for. Use it if you already run his PHP version on that
  release. A few dependencies newer than the release has (Sury's `php-common`, and on
  stretch `libpcre2` and `libargon2-1` from buster) ship in the same component.
- **`debian<N>`** — the PHP of a *newer* Debian release built for an older one (squeeze
  gets wheezy's PHP 5.4; squeeze itself shipped 5.3). Adding it upgrades PHP to that
  version.

## Installing

### apt repository

The repository is signed with a dedicated RSA 4096 key (`repo/debian-php-backports.asc`),
fingerprint `32E9 9830 8C44 8BF6 CC57 BD7B FEE3 4861 1F66 C3D6`. RSA, because the `gpgv` of squeeze, wheezy and jessie cannot
verify Ed25519 signatures.

Import the key and add the components you want. On stretch, buster, bionic and focal:

```sh
curl -fsSL https://animaartificialis.github.io/debian-php-backports/debian-php-backports.asc \
  | gpg --dearmor -o /usr/share/keyrings/debian-php-backports.gpg
echo "deb [signed-by=/usr/share/keyrings/debian-php-backports.gpg] https://animaartificialis.github.io/debian-php-backports stretch debian" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get upgrade
```

Squeeze, wheezy and jessie have no `signed-by`; use `apt-key` and a plain line:

```sh
wget -qO- https://animaartificialis.github.io/debian-php-backports/debian-php-backports.asc | apt-key add -
echo "deb https://animaartificialis.github.io/debian-php-backports jessie debian" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get upgrade
```

Replace the codename and the component (`debian`, `sury`, `debian7`) to match the table.

The repository is served over HTTPS only. Wheezy and jessie need `apt-transport-https`
and reasonably current CA certificates. Squeeze cannot use it at all: its OpenSSL 0.9.8
does not speak TLS 1.2. On squeeze, use the release tarballs below.

### Download

Every [release](https://github.com/animaartificialis/debian-php-backports/releases) has one
tarball per target with all its `.deb` files, a `Packages` index and `BUILD-INFO.txt`.
Check it against `SHA256SUMS` and either install the packages with `dpkg -i`, or unpack
it and use it as a local repository (squeeze: use `dpkg -i`, its apt has no `[trusted=yes]`):

```sh
echo "deb [trusted=yes] file:/srv/debian-php-backports/debian9-stretch/php7.0-debian ./" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get upgrade
```

## How it is built

Each target builds in a podman container of its own Debian release, from archived Debian
or deb.sury.org sources pinned by SHA256:

1. A builder image is created from `debian:<codename>-slim`, pointed at
   archive.debian.org, with the source package's build dependencies installed.
2. The source package is downloaded and its `.dsc` checksum verified.
3. For `debian` targets, Sury's fix is added to `debian/patches/series` (the patch files
   are committed under `targets/*/patches/`, with their origin in `SOURCE.md`).
   `sury` targets use Sury's source package as it is.
4. The version gets the `+animaa1` suffix so it sorts above the version it was built
   from, and the packages are built with `dpkg-buildpackage`.
5. An install test, in a clean container of the same release, installs the built
   packages — over the stock ones where the release has them — and runs PHP.

The upstream test suite is skipped (`nocheck`); it takes hours on these releases.

Two kinds of changes go beyond adding the fix, each recorded in the target's `SOURCE.md`:

- Sury's packages carry a "secure DNS telemetry" patch. It is dropped from every `sury`
  target.
- PHP 5.4 was never shipped by Sury, so there is no upstream patch for it. The 5.4
  targets use a port of Sury's PHP 5.6 patch; the differences are listed in its
  `SOURCE.md` and the patch header.

## Building it yourself

Requires podman.

```sh
make list                                  # all targets
make build-debian9-stretch/php7.0-debian   # packages land in dist/debian9-stretch/php7.0-debian/
make test                                  # install test of everything built
```

Layout: `targets/<release>/<php>-<origin>/target.conf` describes a target,
`build/` holds the build scripts and the builder `Containerfile`, `repo/` builds the apt
repository, `tests/` holds the install test.

## License

The build scripts are MIT licensed (see `LICENSE`). PHP and the patches keep their own
licenses: the fixes come from the PHP project via deb.sury.org, packaging from Debian
and deb.sury.org.
