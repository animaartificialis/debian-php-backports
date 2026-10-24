#!/usr/bin/env python3
"""Open a GitHub issue when deb.sury.org has a newer revision of a source we pin.

The `sury` targets pin Ondřej Surý's source packages by exact version, and some of
them also ship his php-common. Sury removes old revisions from his pool, so a new
revision breaks our build and usually carries a security fix. This script runs from
.github/workflows/sury-watch.yml and reports new revisions as issues in this repo.

The rules, so that nobody gets spammed when an issue sits for weeks:

- Each reported update is marked in the issue text as
  `<!-- sury-update: PACKAGE REVISION -->`. All issues with the `sury-update`
  label, open and closed, with their comments, are searched for these markers.
- An update that is marked somewhere: nothing is done.
- New updates and an open `sury-update` issue: one comment on that issue.
- New updates and no open issue: one new issue. A closed issue is never reopened,
  and the revisions it mentions are not reported again.
- Any error while reading Sury's index or the issues stops the run before anything
  is created or changed.

It also watches the releases for which the README sends people to deb.sury.org
(WATCHED_RELEASES). When Sury's suite for one of them is gone, or its Release file lags
bookworm's by more than LAG_DAYS, it opens one issue with the `sury-dropped` label (marker
`<!-- sury-dropped: RELEASE -->`), so we can decide whether to build for that release
here. Those issues are kept apart from the update issues: they never become the target
of an update comment, and issues from before that split, which still carry the
`sury-update` label, are moved to the new one. An error while reading a watched suite
only warns, for that release alone, so it does not hide updates found in Sury's index
or a dropped release found elsewhere in the list.

For testing: --dry-run prints the planned action instead of calling gh, --targets DIR
reads pins from another directory, --issues FILE takes the issues from a JSON file
(same shape as `gh issue list --json number,state,body,comments,labels`), and
--simulate PACKAGE=REVISION pretends that all targets of PACKAGE pin REVISION, so the
whole path, including real issues, can be tried. Issues from a simulated run say so
in the title and text.
"""

import argparse
import datetime
import email.utils
import gzip
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES_URL = "https://packages.sury.org/php/dists/bookworm/main/source/Sources.gz"
LABEL = "sury-update"
LABEL_DESCRIPTION = "Newer revision of a pinned deb.sury.org source"
DROPPED_LABEL = "sury-dropped"
DROPPED_LABEL_DESCRIPTION = "deb.sury.org stopped building for a release the README sends there"
MARKER = re.compile(r"<!-- sury-update: (\S+) (\S+) -->")
DROPPED = re.compile(r"<!-- sury-dropped: (\S+) -->")
# Releases the README sends to deb.sury.org; Sury has said he will stop building bullseye.
WATCHED_RELEASES = ["bullseye"]
# A watched suite is dropped when its Release file lags this suite's by more than LAG_DAYS.
REFERENCE_RELEASE = "bookworm"
LAG_DAYS = 14


def revision(version):
    """Sury's own revision of a version: '1:7.4.33-31+0~2026...' -> '7.4.33-31'."""
    return version.split(":", 1)[-1].split("+", 1)[0]


def newer(a, b):
    return subprocess.run(["dpkg", "--compare-versions", a, "gt", b]).returncode == 0


def read_pins(targets_dir):
    """{package: {revision: [target, ...]}} from the targets that use Sury's pool."""
    pins = {}
    for conf in sorted(targets_dir.glob("*/*/target.conf")):
        target = conf.parent.relative_to(targets_dir).as_posix()
        text = conf.read_text()
        pkg = re.search(r"^SOURCE_PACKAGE=(\S+)", text, re.M)
        ver = re.search(r"^SOURCE_VERSION=(\S+)", text, re.M)
        url = re.search(r"^SOURCE_POOL_URL=(\S+)", text, re.M)
        if pkg and ver and url and "packages.sury.org" in url.group(1):
            pins.setdefault(pkg.group(1), {}).setdefault(revision(ver.group(1)), []).append(target)
        common = re.search(r"php-defaults/php-common_(\S+?)_all\.deb", text)
        if common:
            rev = revision(common.group(1).replace("%2B", "+"))
            pins.setdefault("php-defaults", {}).setdefault(rev, []).append(target)
    return pins


def read_sury(packages):
    """{package: newest revision} from Sury's Sources index."""
    with urllib.request.urlopen(SOURCES_URL, timeout=60) as r:
        text = gzip.decompress(r.read()).decode("utf-8", "replace")
    found = {}
    for stanza in text.split("\n\n"):
        pkg = re.search(r"^Package: (\S+)", stanza, re.M)
        ver = re.search(r"^Version: (\S+)", stanza, re.M)
        if pkg and ver and pkg.group(1) in packages:
            rev = revision(ver.group(1))
            if pkg.group(1) not in found or newer(rev, found[pkg.group(1)]):
                found[pkg.group(1)] = rev
    return found


def suite_date(rel):
    """Date of Sury's Release file for rel: a datetime, "gone" on 404, None if unreadable."""
    url = f"https://packages.sury.org/php/dists/{rel}/Release"
    try:
        with urllib.request.urlopen(url, timeout=60) as r:
            head = r.read(4096).decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return "gone"
        print(f"warning: cannot read {url}: {e}", file=sys.stderr)
        return None
    except OSError as e:  # one unreachable suite must not hide the rest of the list
        print(f"warning: cannot read {url}: {e}", file=sys.stderr)
        return None
    date = re.search(r"^Date: (.+)$", head, re.M)
    if not date:
        return None
    try:
        stamp = email.utils.parsedate_to_datetime(date.group(1))
    except (TypeError, ValueError):
        print(f"warning: unreadable Date in {url}: {date.group(1)!r}", file=sys.stderr)
        return None
    # A zone-less header (-0000 means "unknown") is read as UTC, which is what
    # Debian's archive writes; the hours this may be off do not matter here.
    if stamp.tzinfo is None:
        stamp = stamp.replace(tzinfo=datetime.timezone.utc)
    return stamp


def dropped_releases():
    """Watched releases whose Sury suite is gone, or lags REFERENCE_RELEASE by more than
    LAG_DAYS. Sury refreshes every suite daily, so a frozen one shows up within days, and
    comparing with a suite he still builds is not fooled by a pause of the whole archive."""
    reference = suite_date(REFERENCE_RELEASE)
    if not isinstance(reference, datetime.datetime):
        print(f"warning: no date for the reference suite {REFERENCE_RELEASE}; "
              "only gone suites are reported", file=sys.stderr)
        reference = None
    dropped = []
    for rel in WATCHED_RELEASES:
        stamp = suite_date(rel)
        if stamp == "gone":
            dropped.append((rel, "the suite is gone"))
        elif stamp and reference:
            lag = (reference - stamp).total_seconds() / 86400
            if lag > LAG_DAYS:
                dropped.append((rel, f"the suite has not changed for {int(lag)} days "
                                     f"longer than {REFERENCE_RELEASE}"))
    return dropped


def find_updates(pins, sury):
    """[(package, [old revision, ...], new revision, [target, ...]), ...]"""
    updates = []
    for pkg, revs in sorted(pins.items()):
        new = sury.get(pkg)
        if new is None:
            print(f"warning: {pkg} is not in Sury's index", file=sys.stderr)
            continue
        old = sorted(r for r in revs if newer(new, r))
        if old:
            updates.append((pkg, old, new, sorted(t for r in old for t in revs[r])))
    return updates


def issue_text(issue):
    """Body and comment bodies of one issue, as one string."""
    return "\n".join([issue.get("body") or ""] +
                     [c.get("body") or "" for c in issue.get("comments") or []])


def markers(pattern, issues):
    """Every match of pattern's one capture group, anywhere in the issues."""
    found = set()
    for issue in issues:
        found.update(pattern.findall(issue_text(issue)))
    return found


def is_dropped(issue):
    """True for a dropped-release issue; the marker only counts in the body, so someone
    quoting it in a comment does not turn an update issue into a dropped one."""
    return bool(DROPPED.search(issue.get("body") or ""))


def decide(updates, issues):
    """Return ('create', updates) / ('comment', number, updates) / ('nothing', [])."""
    known = markers(MARKER, issues)
    fresh = [u for u in updates if (u[0], u[2]) not in known]
    if not fresh:
        return ("nothing", [])
    # A dropped-release issue is not the place for update news, in body or comments.
    open_issues = [i["number"] for i in issues
                   if i.get("state", "").upper() == "OPEN" and not is_dropped(i)]
    if open_issues:
        return ("comment", max(open_issues), fresh)
    return ("create", fresh)


def format_updates(updates):
    lines = ["| Package | Pinned | Newest on deb.sury.org | Targets |", "|---|---|---|---|"]
    for pkg, old, new, targets in updates:
        lines.append(f"| `{pkg}` | {', '.join(old)} | **{new}** | {', '.join(f'`{t}`' for t in targets)} |")
    lines.append("")
    lines += [f"<!-- sury-update: {pkg} {new} -->" for pkg, _, new, _ in updates]
    return "\n".join(lines)


def ensure_dropped_label():
    gh("label", "create", DROPPED_LABEL, "--force", "--color", "FBCA04",
       "--description", DROPPED_LABEL_DESCRIPTION)


def migrate_labels(issues, dry_run):
    """Move dropped-release issues that still carry the update label to the dropped one."""
    for issue in issues:
        labels = {label.get("name") for label in issue.get("labels") or []}
        if is_dropped(issue) and LABEL in labels:
            print(f"plan: move issue #{issue['number']} to the {DROPPED_LABEL} label")
            if not dry_run:
                ensure_dropped_label()
                gh("issue", "edit", str(issue["number"]), "--add-label", DROPPED_LABEL,
                   "--remove-label", LABEL)


def report_dropped(dropped, issues, dry_run):
    """One issue per dropped release, unless any issue already carries its marker."""
    # Body only, as in is_dropped(): a marker quoted in a comment does not count.
    known = {rel for issue in issues for rel in DROPPED.findall(issue.get("body") or "")}
    for rel, why in dropped:
        if rel in known:
            print(f"{rel}: already reported in an issue")
            continue
        title = f"deb.sury.org stopped building for {rel}"
        body = (f"Sury's `{rel}` suite on packages.sury.org: {why}. The README sends `{rel}` users "
                "to deb.sury.org, so check whether to build PHP for it here (first release he no "
                "longer covers), update the README, and bump any `targets/` pins whose source "
                f"lives in that suite's `pool/`.\n\n"
                f"<!-- sury-dropped: {rel} -->")
        print(f"plan: create issue '{title}'\n\n{body}\n")
        if not dry_run:
            ensure_dropped_label()
            gh("issue", "create", "--label", DROPPED_LABEL, "--title", title, "--body-file", "-",
               stdin=body)


def gh(*args, stdin=None):
    return subprocess.run(["gh", *args], input=stdin, text=True, check=True,
                          stdout=subprocess.PIPE).stdout


def fetch_issues():
    """Issues carrying either label, deduplicated; gh has no OR for --label."""
    issues = {}
    for label in (LABEL, DROPPED_LABEL):
        for issue in json.loads(gh("issue", "list", "--label", label, "--state", "all",
                                   "--limit", "500",
                                   "--json", "number,state,body,comments,labels")):
            issues[issue["number"]] = issue
    return list(issues.values())


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("--dry-run", action="store_true", help="print the planned action, do not call gh")
    ap.add_argument("--targets", type=Path, default=ROOT / "targets", help="directory with the targets")
    ap.add_argument("--issues", type=Path, help="JSON file with issues instead of asking GitHub")
    ap.add_argument("--simulate", action="append", default=[], metavar="PACKAGE=REVISION",
                    help="pretend that all targets of PACKAGE pin REVISION (testing only)")
    args = ap.parse_args()

    pins = read_pins(args.targets)
    for item in args.simulate:
        pkg, _, rev = item.partition("=")
        if pkg not in pins or not rev:
            sys.exit(f"--simulate: unknown package or empty revision: {item!r}")
        pins[pkg] = {rev: sorted(t for ts in pins[pkg].values() for t in ts)}
    test = " [TEST, simulated pins: " + ", ".join(args.simulate) + "]" if args.simulate else ""
    if not pins:
        sys.exit(f"no Sury pins found under {args.targets}")
    try:
        sury = read_sury(set(pins))
    except OSError as e:  # network error: stop here, before any issue is touched
        sys.exit(f"cannot read {SOURCES_URL}: {e}")
    updates = find_updates(pins, sury)
    for pkg, old, new, targets in updates:
        print(f"update: {pkg} {', '.join(old)} -> {new} ({', '.join(targets)})")
    # A warning per suite, not a failed run: the dropped check is a second, newer source
    # of truth and must never hide updates found in Sury's index.
    dropped = dropped_releases()
    for rel, why in dropped:
        print(f"dropped: {rel} ({why})")
    if not updates and not dropped:
        print("all pins are current")
        return

    if args.issues:
        issues = json.loads(args.issues.read_text())
    else:
        issues = fetch_issues()
    migrate_labels(issues, args.dry_run)
    report_dropped(dropped, issues, args.dry_run)
    if not updates:
        return
    action, *rest = decide(updates, issues)

    if action == "nothing":
        print("every update is already reported in an issue")
        return
    text = format_updates(rest[-1])
    if action == "comment":
        number = rest[0]
        body = "New revisions appeared on deb.sury.org since this issue was opened" + test + ":\n\n" + text
        print(f"plan: comment on issue #{number}\n\n{body}\n")
        if not args.dry_run:
            gh("issue", "comment", str(number), "--body-file", "-", stdin=body)
    else:
        title = "Sury update: " + ", ".join(f"{pkg} {new}" for pkg, _, new, _ in rest[0]) + test
        body = (("This is a test of the workflow; nothing needs to be done.\n\n" if test else "") +
                "deb.sury.org has newer revisions of sources pinned in `targets/`. Sury removes "
                "old revisions from his pool, so the listed targets will stop building until "
                "their pins are updated. New revisions usually carry security fixes.\n\n" + text)
        print(f"plan: create issue '{title}'\n\n{body}\n")
        if not args.dry_run:
            gh("label", "create", LABEL, "--force", "--color", "D93F0B",
               "--description", LABEL_DESCRIPTION)
            gh("issue", "create", "--label", LABEL, "--title", title, "--body-file", "-", stdin=body)


if __name__ == "__main__":
    main()
