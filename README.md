# debian-php-backports

PHP packages with security fixes for Debian releases that no longer receive them.

> **The real fix is to upgrade to a supported Debian or Ubuntu release.** These packages
> are a last resort: they keep PHP safer until you can upgrade. An archived release also
> misses security fixes in many other packages, not only in PHP.

> **Only for archived Debian releases: squeeze, wheezy, jessie, stretch and buster.**
> On Debian 11 bullseye and newer, use [deb.sury.org](https://deb.sury.org/) instead —
> it builds every PHP version for supported releases and gets fixes first. Nothing
> here is built for, or should be installed on, a supported release.
>
> The Ubuntu targets, **Ubuntu 14.04 trusty** (PHP 5.6, 7.4), **Ubuntu 16.04 xenial** (PHP 5.6, 7.3, 7.4),
> **Ubuntu 18.04 bionic** (PHP 5.6, 7.2, 7.4) and **Ubuntu 20.04 focal** (PHP 5.6, 7.2, 7.4), exist
> for the same reason: the ondrej/php PPA dropped these releases when their standard support
> ended. On trusty that was in 2019, before PHP 7.4 existed, so there was no 7.4 build for it
> before this one. Trusty's ten years of support also ended in April 2024: nothing on it,
> its own PHP 5.5 included, gets fixes from Canonical any more. Xenial's own PHP 7.0,
> bionic's 7.2.24 and focal's 7.4.3 are still patched through Ubuntu Pro (ESM).
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

Each row is a target, named `<release>/<php>-<component>`, for example
`debian7-wheezy/php5.4-debian`. That is its directory under `targets/`, the name of its
tarball (`debian7-wheezy_php5.4-debian.tar.gz`) and the directory the tarball unpacks to.
A release is always a Debian or Ubuntu release in this README. The Release column shows
it the way target names spell it, with its apt codename after the dash.

The commands under ["Installing"](#installing) take four values from this table:
`RELEASE` is the Release column (`debian8-jessie`), `CODENAME` is its part after the dash
(`jessie`), `COMPONENT` is the Component column (`sury`) and `TARGET` is
`php<PHP>-<COMPONENT>` (`php5.6-sury`).

| Release | PHP | Component | Source package |
|---|---|---|---|
| `debian6-squeeze` | 5.4 | `debian7` | `php5` |
| `debian7-wheezy` | 5.4 | `debian` | `php5` |
| `debian8-jessie` | 5.6 | `debian` | `php5` |
| `debian8-jessie` | 5.6 | `sury` | `php5.6` |
| `debian8-jessie` | 7.1 | `sury` | `php7.1` |
| `debian9-stretch` | 5.6 | `sury` | `php5.6` |
| `debian9-stretch` | 7.0 | — not built here, use [Freexian ELTS](https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/) | `php7.0` |
| `debian9-stretch` | 7.3 | `sury` | `php7.3` |
| `debian9-stretch` | 7.4 | `sury` | `php7.4` |
| `debian10-buster` | 7.3 | — not built here, use [Freexian ELTS](https://www.freexian.com/lts/extended/docs/how-to-use-extended-lts/) | `php7.3` |
| `debian10-buster` | 5.6 | `sury` | `php5.6` |
| `debian10-buster` | 7.4 | `sury` | `php7.4` |
| `ubuntu14.04-trusty` | 5.6 | `sury` | `php5.6` |
| `ubuntu14.04-trusty` | 7.4 | `sury` | `php7.4` |
| `ubuntu16.04-xenial` | 5.6 | `sury` | `php5.6` |
| `ubuntu16.04-xenial` | 7.3 | `sury` | `php7.3` |
| `ubuntu16.04-xenial` | 7.4 | `sury` | `php7.4` |
| `ubuntu18.04-bionic` | 5.6 | `sury` | `php5.6` |
| `ubuntu18.04-bionic` | 7.2 | `sury` | `php7.2` |
| `ubuntu18.04-bionic` | 7.4 | `sury` | `php7.4` |
| `ubuntu20.04-focal` | 5.6 | `sury` | `php5.6` |
| `ubuntu20.04-focal` | 7.2 | `sury` | `php7.2` |
| `ubuntu20.04-focal` | 7.4 | `sury` | `php7.4` |

The exact package version of every target is in the notes of each
[tag](https://github.com/animaartificialis/debian-php-backports/releases/latest) (GitHub
releases, tagged `vYYYY.MM.DD.N`, are called tags here) and in the `BUILD-INFO.txt` of its
tarball. Every version is the version it was built from (Debian's or deb.sury.org's) plus
`+animaaN`, except on squeeze: `5.4.45-1+animaaN~squeeze`, built from wheezy's
`5.4.45-0+deb7u14`.

All targets are built for `amd64`. Five are also built for `arm64`: Debian 10 buster
PHP 5.6 and 7.4, and Ubuntu 20.04 focal PHP 5.6, 7.2 and 7.4. These are the first releases that
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
  release. A few dependencies newer than the release has ship in the same component: on
  stretch `libpcre2` and `libargon2-1` from buster, on xenial `libpcre2`, `libargon2-0`
  and `libtidy5` from bionic, on trusty those three plus `libzip4` and `libsystemd0` from
  xenial (and trusty's own `libgcrypt20` from universe; PHP 5.6 needs only `libtidy5`
  and `libzip4`), and everywhere but buster a `php-common` rebuilt from Sury's
  `php-defaults` source (next paragraph). The shipped `libpcre2` replaces the older one
  of the release. `libpcre2-dev` ships too, because
  `phpX.Y-dev` needs it; the other `-dev` packages are only used for the build. The rebuild keeps the same
  PHP extension API (`phpapi-…`), so extension packages you installed earlier (imagick,
  redis, apcu, …) keep working. Where his repository dropped the release, those can no
  longer be installed new.

  *About `php-common`:* Sury's PHP packages need a `php-common` newer than jessie,
  stretch, trusty, xenial and bionic have. His binary `php-common` is made for PHP 8 and declares
  `Breaks` on older versions of 42 PECL extension packages (`php-apcu` below 5.1.24,
  `php-imagick` below 3.7.0-12, `php-redis`, `php-memcached`, `php-xdebug`, …). Installed
  on an older release, it makes `apt-get` remove those extensions while upgrading PHP,
  even the release's own versions. Tags up to `v2026.10.23.1` shipped that binary
  (on focal too, although focal's own 2:75 would do). Now the `sury` component ships
  `php-common` rebuilt from the same `php-defaults` source with that field removed, as
  `2:101+0~20261021.78+debian11~1.gbp53f25f+animaa1` on every release: Sury's version
  plus the suffix, so it sorts above his binary and replaces it with a normal
  `apt-get upgrade`. Extensions that an earlier upgrade removed can then be installed
  again (from your own copy; the old repositories are gone).

  *On trusty:* `php7.4-fpm` and `php5.6-fpm` pull in trusty's `systemd` 204 package. Their
  init scripts need `systemd-tmpfiles`; trusty still boots with upstart. Installing `php7.4-dev`
  removes trusty's `libpcre3-dev`, because that package conflicts with `libpcre2-dev`.
  This matters only if you build PECL extensions or other software against PCRE.
  PHP 5.6 uses trusty's own PCRE 8.31, so `php5.6-dev` needs that `libpcre3-dev` and
  cannot be installed together with `php7.4-dev`. `libapache2-mod-php5.6` and
  `libapache2-mod-php7.4` work with trusty's Apache 2.4.7.
- **`debian<N>`** — the PHP of a *newer* Debian release built for an older one (squeeze
  gets wheezy's PHP 5.4; squeeze itself shipped 5.3). Adding it upgrades PHP to that
  version. On squeeze, PECL extension packages built for PHP 5.3 (`phpapi-20090626`) are
  removed by the upgrade, and `php5-suhosin` must be purged first. Use `apt-get dist-upgrade`.

### Verifying the fixes

- **CVE-2023-0662** (`max_multipart_body_parts` DoS limit):
  Check that the INI directive is recognized by PHP:
  ```sh
  php -i | grep -i max_multipart_body_parts
  # Expected: max_multipart_body_parts => -1 => -1
  ```
- **CVE-2026-109618 & CVE-2026-109619** ("PHP2Shell" bailout / memory corruption mitigation):
  The fix adds `zend_mm_safe_error_ex()` and routes allocation-overflow errors through it
  instead of a bailout. Check that the symbol is exported by the binary:
  ```sh
  nm -D $(which php) | grep zend_mm_safe_error_ex
  # Expected: ... T zend_mm_safe_error_ex
  ```

## Installing

Jessie and newer: use the [apt repository](#apt-repository). Squeeze, wheezy and trusty:
use a [tarball](#tarball). They cannot reach the repository, which is served over HTTPS
only: squeeze's OpenSSL 0.9.8 does not speak TLS 1.2, and the GnuTLS 2.12 of wheezy and
trusty fails the TLS handshake with GitHub's servers. A tarball also works on machines
without internet access.

### apt repository

The repository is signed with a dedicated RSA 4096 key (`repo/debian-php-backports.asc`),
fingerprint `32E9 9830 8C44 8BF6 CC57 BD7B FEE3 4861 1F66 C3D6`. RSA, because the `gpgv` of squeeze, wheezy and jessie cannot
verify Ed25519 signatures.

First set two values from the table under ["Packages"](#packages): the codename of your
release and the component (see also ["Components"](#components)). Not sure which release
you run? `lsb_release -sc` prints the codename; `cat /etc/os-release` works too.

```sh
CODENAME=jessie    # Release column after the dash: jessie stretch buster xenial bionic focal
COMPONENT=sury     # Component column: sury or debian
```

Then import the key and add the repository. On stretch, buster, xenial, bionic and focal:

```sh
curl -fsSL https://animaartificialis.github.io/debian-php-backports/debian-php-backports.asc \
  | gpg --dearmor -o /usr/share/keyrings/debian-php-backports.gpg
echo "deb [signed-by=/usr/share/keyrings/debian-php-backports.gpg] https://animaartificialis.github.io/debian-php-backports $CODENAME $COMPONENT" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get upgrade
```

Jessie has no `signed-by` (its apt predates it); use `apt-key` and a plain line:

```sh
wget -qO- https://animaartificialis.github.io/debian-php-backports/debian-php-backports.asc | apt-key add -
echo "deb https://animaartificialis.github.io/debian-php-backports $CODENAME $COMPONENT" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get upgrade
```

If `apt-get upgrade` says the PHP packages "have been kept back", the new packages need
a package you do not have yet (for example, Sury's `php-common` needs `psmisc` and
recommends `cron`). `apt-get upgrade` never installs new packages. Upgrade PHP like this
instead:

```sh
apt-get install --only-upgrade 'php*'
```

Jessie needs `apt-transport-https` and reasonably current CA certificates.

### Tarball

Every [tag](https://github.com/animaartificialis/debian-php-backports/releases) has one
tarball per target with its `.deb` files, a `Packages` index and `BUILD-INFO.txt`.
The `arm64` tarballs end in `_arm64.tar.gz`; all others are `amd64`.

The tarball is `${RELEASE}_${TARGET}.tar.gz` and unpacks to `$RELEASE/$TARGET/`, with
`RELEASE` and `TARGET` taken from the table under ["Packages"](#packages). For the
releases that cannot use the apt repository the values are:

| `RELEASE` | `TARGET` |
|---|---|
| `debian6-squeeze` | `php5.4-debian7` |
| `debian7-wheezy` | `php5.4-debian` |
| `ubuntu14.04-trusty` | `php5.6-sury` |
| `ubuntu14.04-trusty` | `php7.4-sury` |

On wheezy and trusty, `curl` (built with OpenSSL) can download it, `wget` cannot:

```sh
RELEASE=debian7-wheezy   # from the table above
TARGET=php5.4-debian     # from the table above
URL=https://github.com/animaartificialis/debian-php-backports/releases/latest/download
mkdir -p /srv/debian-php-backports && cd /srv/debian-php-backports
curl -fsSLO "$URL/${RELEASE}_${TARGET}.tar.gz" -O "$URL/SHA256SUMS"
grep -F "${RELEASE}_${TARGET}.tar.gz" SHA256SUMS | sha256sum -c -
tar xzf "${RELEASE}_${TARGET}.tar.gz"
echo "deb [trusted=yes] file:/srv/debian-php-backports/$RELEASE/$TARGET ./" \
  > "/etc/apt/sources.list.d/debian-php-backports-$TARGET.list"
apt-get update && apt-get upgrade
```

For a specific tag instead of the latest, replace `latest/download` with
`download/<tag>`, for example `download/v2026.10.26.1`.

Squeeze cannot download from GitHub at all: run the `curl` lines on another machine (or
download from the tag's page), check the sum there and copy the tarball over. Its apt has no
`[trusted=yes]`, so tell it to accept the unsigned local repository. This upgrades PHP 5.3
to 5.4; purge `php5-suhosin` first (see ["Components"](#components)):

```sh
mkdir -p /srv/debian-php-backports
tar -C /srv/debian-php-backports -xzf debian6-squeeze_php5.4-debian7.tar.gz
echo "deb file:/srv/debian-php-backports/debian6-squeeze/php5.4-debian7 ./" \
  > /etc/apt/sources.list.d/debian-php-backports.list
apt-get update && apt-get --allow-unauthenticated dist-upgrade
```

## How it is built

Each target builds in a podman or docker container of its own Debian or Ubuntu release,
from archived Debian or deb.sury.org sources pinned by SHA256:

1. A builder image is created from the release's own base image (`debian:<codename>-slim`,
   `debian/eol:squeeze`, or `ubuntu:<version>`), pointed at the release's archive
   (archive.debian.org for Debian, archive.ubuntu.com for Ubuntu), with the source package's build dependencies installed.
   For the `sury` targets on every release but buster, the image also rebuilds
   `php-common` from Sury's pinned `php-defaults` source without its `Breaks` field
   (`build/container/build-php-common.sh`, pins in `build/build.conf`), and the package
   ships with the target.
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

Requires podman or docker.

```sh
make list                                  # all targets
make build-debian8-jessie/php5.6-debian    # packages land in dist/debian8-jessie/php5.6-debian/
make test                                  # install test of everything built
```

Layout: `targets/<release>/<php>-<component>/target.conf` describes a target,
`build/` holds the build scripts and the builder `Containerfile`, `repo/` builds the apt
repository, `tests/` holds the install test.

## Maintenance

The `sury` targets pin deb.sury.org source packages (PHP, and `php-defaults` where
`php-common` is rebuilt) by exact version, and Sury removes old revisions from his pool.
A scheduled workflow (`.github/workflows/sury-watch.yml`, every eight hours) runs
`repo/check-sury-updates.py`, which compares the pinned revisions with Sury's index and
opens an issue labelled `sury-update` when a newer revision exists. Updates that an open
or closed issue already mentions are not reported again; a newer revision found while an
issue is open is added to it as a comment. A second kind of issue, labelled
`sury-dropped`, appears when a release this README sends to Sury is gone from his archive,
or its suite falls more than two weeks behind bookworm's (Sury refreshes every suite
daily) — bullseye is the last such release here. Those issues never receive update
comments. The script also runs locally: `repo/check-sury-updates.py --dry-run`.

## License

The build scripts are MIT licensed (see `LICENSE`). PHP and the patches keep their own
licenses: the fixes come from the PHP project via deb.sury.org, packaging from Debian
and deb.sury.org.
