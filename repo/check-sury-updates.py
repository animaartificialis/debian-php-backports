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

For testing: --dry-run prints the planned action instead of calling gh, --targets DIR
reads pins from another directory, and --issues FILE takes the issues from a JSON
file (same shape as `gh issue list --json number,state,body,comments`).
"""

import argparse
import gzip
import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES_URL = "https://packages.sury.org/php/dists/bookworm/main/source/Sources.gz"
LABEL = "sury-update"
MARKER = re.compile(r"<!-- sury-update: (\S+) (\S+) -->")


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


def decide(updates, issues):
    """Return ('create', updates) / ('comment', number, updates) / ('nothing', [])."""
    known = set()
    for issue in issues:
        texts = [issue.get("body") or ""] + [c.get("body") or "" for c in issue.get("comments") or []]
        known.update(MARKER.findall("\n".join(texts)))
    fresh = [u for u in updates if (u[0], u[2]) not in known]
    if not fresh:
        return ("nothing", [])
    open_issues = [i["number"] for i in issues if i.get("state", "").upper() == "OPEN"]
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


def gh(*args, stdin=None):
    return subprocess.run(["gh", *args], input=stdin, text=True, check=True,
                          stdout=subprocess.PIPE).stdout


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument("--dry-run", action="store_true", help="print the planned action, do not call gh")
    ap.add_argument("--targets", type=Path, default=ROOT / "targets", help="directory with the targets")
    ap.add_argument("--issues", type=Path, help="JSON file with issues instead of asking GitHub")
    args = ap.parse_args()

    pins = read_pins(args.targets)
    if not pins:
        sys.exit(f"no Sury pins found under {args.targets}")
    try:
        sury = read_sury(set(pins))
    except OSError as e:  # network error: stop here, before any issue is touched
        sys.exit(f"cannot read {SOURCES_URL}: {e}")
    updates = find_updates(pins, sury)
    for pkg, old, new, targets in updates:
        print(f"update: {pkg} {', '.join(old)} -> {new} ({', '.join(targets)})")
    if not updates:
        print("all pins are current")
        return

    if args.issues:
        issues = json.loads(args.issues.read_text())
    else:
        issues = json.loads(gh("issue", "list", "--label", LABEL, "--state", "all", "--limit", "500",
                               "--json", "number,state,body,comments"))
    action, *rest = decide(updates, issues)

    if action == "nothing":
        print("every update is already reported in an issue")
        return
    text = format_updates(rest[-1])
    if action == "comment":
        number = rest[0]
        body = "New revisions appeared on deb.sury.org since this issue was opened:\n\n" + text
        print(f"plan: comment on issue #{number}\n\n{body}\n")
        if not args.dry_run:
            gh("issue", "comment", str(number), "--body-file", "-", stdin=body)
    else:
        title = "Sury update: " + ", ".join(f"{pkg} {new}" for pkg, _, new, _ in rest[0])
        body = ("deb.sury.org has newer revisions of sources pinned in `targets/`. Sury removes "
                "old revisions from his pool, so the listed targets will stop building until "
                "their pins are updated. New revisions usually carry security fixes.\n\n" + text)
        print(f"plan: create issue '{title}'\n\n{body}\n")
        if not args.dry_run:
            gh("label", "create", LABEL, "--force", "--color", "D93F0B",
               "--description", "Newer revision of a pinned deb.sury.org source")
            gh("issue", "create", "--label", LABEL, "--title", title, "--body-file", "-", stdin=body)


if __name__ == "__main__":
    main()
