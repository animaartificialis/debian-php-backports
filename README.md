# debian-php-backports

PHP packages with security fixes for Debian releases that no longer receive them.

> **Only for archived Debian releases: squeeze, wheezy, jessie, stretch and buster.**
> On Debian 11 bullseye and newer, use [deb.sury.org](https://deb.sury.org/) instead —
> it builds every PHP version for supported releases and gets fixes first. Nothing
> here is built for, or should be installed on, a supported release.
>
> The Ubuntu targets, **Ubuntu 16.04 xenial** (PHP 5.6, 7.3), **Ubuntu 18.04 bionic** (PHP 5.6,
> 7.2, 7.4) and **Ubuntu 20.04 focal** (PHP 5.6, 7.4), exist for the same reason: the
> ondrej/php PPA dropped these releases when their standard support ended. Their own PHP
> (xenial 7.0, bionic 7.2.24, focal 7.4.3) is still patched by Canonical through Ubuntu Pro (ESM).
>
> **Debian 9 stretch and Debian 10 buster with their own PHP (7.0 and 7.3): use
> [Freexian ELTS](https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/) first.** Its public repository already has the fix for
> amd64 and more (buster also arm64), with more security fixes than a rebuild here would
> have. The link explains how to add it to apt. ELTS is a service paid for by Freexian's
> customers; the public repository comes with no guarantee. This repository does not
> build these two.

[deb.sury.org](https://deb.sury.org/) builds PHP — including old PHP versions — but only for
Debian and Ubuntu releases that are still supported. Servers running an archived release
get nothing from him. This repository covers what nobody else fixes: it rebuilds PHP for
archived releases with the fixes applied, from sources you can check.

Current fix: **CVE-2026-109618** and **CVE-2026-109619** ("PHP2Shell", remote code
execution; advisories [GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)
and [GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)).

All targets carry the PHP group's mitigation for end-of-life PHP versions, the same patch
Ondřej ships ("Avoid state corruption via bailout"). It is not the full fix from PHP 8.2+,
but it closes both problems in a simpler way:

- On out of memory, the PHP process exits instead of continuing with broken state.
- Error and request state is reset at the end of each request.
- **Session upload progress is turned off** (`session.upload_progress` has no effect).
  This removes one of the confirmed attack paths. If your application shows upload
  progress bars, they stop working.

## Packages

| Debian | PHP | Component | Source from | Source package | Version |
|---|---|---|---|---|---|
| Debian 6 squeeze | 5.4 | `debian7` | Debian 7 | `php5` | `5.4.45-1+animaa2~squeeze` |
| Debian 7 wheezy | 5.4 | `debian` | Debian 7 | `php5` | `5.4.45-0+deb7u14+animaa2` |
| Debian 8 jessie | 5.6 | `debian` | Debian 8 | `php5` | `5.6.40+dfsg-0+deb8u12+animaa2` |
| Debian 8 jessie | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-105+0~20261022.135+debian8~1+animaa1` |
| Debian 8 jessie | 7.1 | `sury` | deb.sury.org | `php7.1` | `7.1.33-81+0~20261022.128+debian8~1+animaa1` |
| Debian 9 stretch | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-105+0~20261022.135+debian9~1+animaa1` |
| Debian 9 stretch | 7.0 | — | not built here: use [Freexian ELTS](https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/) | `php7.0` | ELTS `7.0.33-0+deb9u26` |
| Debian 9 stretch | 7.3 | `sury` | deb.sury.org | `php7.3` | `7.3.33-35+0~20261021.144+debian9~1+animaa1` |
| Debian 9 stretch | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+debian9~1+animaa1` |
| Debian 10 buster | 7.3 | — | not built here: use [Freexian ELTS](https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/) | `php7.3` | ELTS `7.3.31-1~deb10u16` |
| Debian 10 buster | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-105+0~20261022.135+debian10~1+animaa1` |
| Debian 10 buster | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+debian10~1+animaa1` |
| Ubuntu 16.04 xenial | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-105+0~20261022.135+ubuntu16.04~1+animaa1` |
| Ubuntu 16.04 xenial | 7.3 | `sury` | deb.sury.org | `php7.3` | `7.3.33-35+0~20261021.144+ubuntu16.04~1+animaa1` |
| Ubuntu 18.04 bionic | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-105+0~20261022.135+ubuntu18.04~1+animaa1` |
| Ubuntu 18.04 bionic | 7.2 | `sury` | deb.sury.org | `php7.2` | `7.2.34-66+0~20261021.122+ubuntu18.04~1+animaa1` |
| Ubuntu 18.04 bionic | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+ubuntu18.04~1+animaa1` |
| Ubuntu 20.04 focal | 5.6 | `sury` | deb.sury.org | `php5.6` | `5.6.40-105+0~20261022.135+ubuntu20.04~1+animaa1` |
| Ubuntu 20.04 focal | 7.4 | `sury` | deb.sury.org | `php7.4` | `1:7.4.33-31+0~20261021.121+ubuntu20.04~1+animaa1` |

All targets are built for `amd64`. Four are also built for `arm64`: Debian 10 buster
PHP 5.6 and 7.4, and Ubuntu 20.04 focal PHP 5.6 and 7.4. These are the first releases that
deb.sury.org no longer builds for. Older releases were rarely run on arm64, and buster's
own PHP 7.3 already has an arm64 fix from [Freexian ELTS](https://www.freexian.com/lts/extended/).

### Components

The apt component says where the source comes from, and therefore what adding it does:

- **`debian`** — the PHP version the release itself shipped, rebuilt from the last
  official Debian source with the fix added. A drop-in replacement: `apt-get upgrade`
  replaces only packages you already have, with the same version plus the fix.
  This is what most servers want. It adds this fix and the CVE-2023-0662 fix
  (`max_multipart_body_parts`) to the last official source, but not other fixes released
  after it. On jessie, where the last Debian source is old, the `sury`
  component has more fixes. Stretch and buster have no `debian` component: their own PHP
  is fixed in [Freexian ELTS](https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/).
- **`sury`** — Ondřej Surý's PHP packages (which already contain the fix), rebuilt for a
  release he no longer builds for. Use it if you already run his PHP version on that
  release. A few dependencies newer than the release has (Sury's `php-common`; on stretch
  `libpcre2` and `libargon2-1` from buster; on xenial `libpcre2`, `libargon2-0` and
  `libtidy5` from bionic) ship in the same component. The rebuild keeps the same PHP
  extension API (`phpapi-…`), so extension packages you installed from Ondřej earlier
  (imagick, redis, apcu, …) keep working. Where his repository dropped the release, those
  can no longer be installed new.
- **`debian<N>`** — the PHP of a *newer* Debian release built for an older one (squeeze
  gets wheezy's PHP 5.4; squeeze itself shipped 5.3). Adding it upgrades PHP to that
  version. On squeeze, PECL extension packages built for PHP 5.3 (`phpapi-20090626`) are
  removed by the upgrade, and `php5-suhosin` must be purged first. Use `apt-get dist-upgrade`.

## Installing

### apt repository

The repository is signed with a dedicated RSA 4096 key (`repo/debian-php-backports.asc`),
fingerprint `32E9 9830 8C44 8BF6 CC57 BD7B FEE3 4861 1F66 C3D6`. RSA, because the `gpgv` of squeeze, wheezy and jessie cannot
verify Ed25519 signatures.

Import the key and add the components you want. On stretch, buster, xenial, bionic and focal:

```sh
curl -fsSL https://animaartificialis.github.io/debian-php-backports/debian-php-backports.asc \
  | gpg --dearmor -o /usr/share/keyrings/debian-php-backports.gpg
echo "deb [signed-by=/usr/share/keyrings/debian-php-backports.gpg] https://animaartificialis.github.io/debian-php-backports buster sury" \
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

If `apt-get upgrade` says the PHP packages "have been kept back", the new packages need
a package you do not have yet (for example, Sury's `php-common` needs `psmisc` and
recommends `cron`). `apt-get upgrade` never installs new packages. Upgrade PHP like this
instead:

```sh
apt-get install --only-upgrade 'php*'
```

The repository is served over HTTPS only. Wheezy and jessie need `apt-transport-https`
and reasonably current CA certificates. Squeeze cannot use it at all: its OpenSSL 0.9.8
does not speak TLS 1.2. On squeeze, use the release tarballs below.

### Download

Every [release](https://github.com/animaartificialis/debian-php-backports/releases) has one
tarball per target with all its `.deb` files, a `Packages` index and `BUILD-INFO.txt`.
The `arm64` tarballs end in `_arm64.tar.gz`; all others are `amd64`.
Check it against `SHA256SUMS` and either install the packages with `dpkg -i`, or unpack
it and use it as a local repository (squeeze: use `dpkg -i`, its apt has no `[trusted=yes]`):

```sh
echo "deb [trusted=yes] file:/srv/debian-php-backports/debian8-jessie/php5.6-debian ./" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get upgrade
```

## How it is built

Each target builds in a podman container of its own Debian release, from archived Debian
or deb.sury.org sources pinned by SHA256:

1. A builder image is created from the release's own base image (`debian:<codename>-slim`,
   `debian/eol:squeeze`, or `ubuntu:<version>`), pointed at the release's archive
   (archive.debian.org for Debian), with the source package's build dependencies installed.
2. The source package is downloaded and its `.dsc` checksum verified.
3. For `debian` targets, Sury's fixes are added to `debian/patches/series` (the patch files
   are committed under `targets/*/patches/`, with their origin in `SOURCE.md`).
   `sury` targets use Sury's source package as it is.
4. The version gets an `+animaaN` suffix (`+animaa1`, raised on each rebuild of the same
   source) so it sorts above the version it was built from, and the packages are built
   with `dpkg-buildpackage`.
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
make build-debian8-jessie/php5.6-debian    # packages land in dist/debian8-jessie/php5.6-debian/
make test                                  # install test of everything built
```

Layout: `targets/<release>/<php>-<origin>/target.conf` describes a target,
`build/` holds the build scripts and the builder `Containerfile`, `repo/` builds the apt
repository, `tests/` holds the install test.

## Maintenance

The `sury` targets pin deb.sury.org source packages by exact version, and Sury removes old
revisions from his pool. A scheduled workflow (`.github/workflows/sury-watch.yml`, every six
hours) runs `repo/check-sury-updates.py`, which compares the pinned revisions with Sury's
index and opens an issue labelled `sury-update` when a newer revision exists. Updates that
an open or closed issue already mentions are not reported again; a newer revision found
while an issue is open is added to it as a comment. The script also runs locally:
`repo/check-sury-updates.py --dry-run`.

## License

The build scripts are MIT licensed (see `LICENSE`). PHP and the patches keep their own
licenses: the fixes come from the PHP project via deb.sury.org, packaging from Debian
and deb.sury.org.
