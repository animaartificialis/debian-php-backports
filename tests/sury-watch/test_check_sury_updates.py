"""Tests for repo/check-sury-updates.py that need no network and no gh.

Run with: python3 -m unittest discover -s tests/sury-watch -t tests/sury-watch
"""

import contextlib
import email.utils
import importlib.util
import io
import json
import time
import unittest
import urllib.error
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[2] / "repo" / "check-sury-updates.py"
_spec = importlib.util.spec_from_file_location("check_sury_updates", SCRIPT)
sury = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sury)

UPDATE = ("php7.2", ["7.2.34-65"], "7.2.34-66", ["ubuntu20.04-focal/php7.2-sury"])
DROPPED_BODY = "the suite is gone\n\n<!-- sury-dropped: bullseye -->"


def issue(number, state="OPEN", body="", comments=(), labels=()):
    return {"number": number, "state": state, "body": body,
            "comments": [{"body": text} for text in comments],
            "labels": [{"name": name} for name in labels]}


class FakeResponse:
    """Just enough of an urlopen() response for dropped_releases()."""

    def __init__(self, text):
        self._text = text

    def read(self, _size=-1):
        return self._text.encode()

    def __enter__(self):
        return self

    def __exit__(self, *_exc):
        return False


def release_file(days_ago):
    stamp = email.utils.formatdate(time.time() - days_ago * 86400, usegmt=True)
    return f"Origin: packages.sury.org\nDate: {stamp}\nSuite: bullseye\n"


def http_error(code):
    """An HTTPError like urlopen() raises it. Closed: nothing reads the body, and CPython
    3.14 warns about an unclosed one at shutdown."""
    error = urllib.error.HTTPError("https://example.invalid", code, "error", {},
                                   io.BytesIO(b""))
    error.close()
    return error


def serve(responses):
    """urlopen() answering per release taken from the URL; unknown releases are 404."""

    def urlopen(url, timeout=60):
        rel = url.split("/dists/", 1)[1].split("/", 1)[0]
        answer = responses.get(rel)
        if isinstance(answer, Exception):
            raise answer
        if answer is None:
            raise http_error(404)
        assert timeout == 60
        return answer

    return urlopen


def for_all_watched(answer):
    return {rel: answer for rel in sury.WATCHED_RELEASES}


class DecideTest(unittest.TestCase):
    def test_comments_on_newest_update_issue(self):
        issues = [issue(3, body="<!-- sury-update: php7.4 7.4.32 -->")]
        self.assertEqual(sury.decide([UPDATE], issues), ("comment", 3, [UPDATE]))

    def test_never_comments_on_dropped_issue(self):
        self.assertEqual(sury.decide([UPDATE], [issue(5, body=DROPPED_BODY)]),
                         ("create", [UPDATE]))

    def test_dropped_marker_quoted_in_a_comment_does_not_exclude(self):
        # Only the script writes markers, and in the body: a comment is someone quoting it.
        issues = [issue(5, body="unrelated", comments=[DROPPED_BODY])]
        self.assertEqual(sury.decide([UPDATE], issues), ("comment", 5, [UPDATE]))

    def test_update_already_reported_is_nothing(self):
        issues = [issue(4, body="<!-- sury-update: php7.2 7.2.34-66 -->")]
        self.assertEqual(sury.decide([UPDATE], issues), ("nothing", []))


class ReportDroppedTest(unittest.TestCase):
    def test_known_marker_is_skipped(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            sury.report_dropped([("bullseye", "the suite is gone")],
                                [issue(1, body=DROPPED_BODY)], dry_run=True)
        self.assertIn("already reported", out.getvalue())

    def test_dry_run_prints_the_plan_and_never_calls_gh(self):
        out = io.StringIO()
        with mock.patch.object(sury, "gh", side_effect=AssertionError("gh was called")):
            with contextlib.redirect_stdout(out):
                sury.report_dropped([("bullseye", "the suite is gone")], [], dry_run=True)
        self.assertIn("plan: create issue 'deb.sury.org stopped building for bullseye'",
                      out.getvalue())
        self.assertIn("<!-- sury-dropped: bullseye -->", out.getvalue())


class DroppedReleasesTest(unittest.TestCase):
    def test_404_means_the_suite_is_gone(self):
        with mock.patch.object(sury.urllib.request, "urlopen", serve({})):
            dropped = sury.dropped_releases()
        self.assertIn(("bullseye", "the suite is gone"), dropped)

    def test_recent_release_is_not_dropped(self):
        with mock.patch.object(sury.urllib.request, "urlopen",
                               serve(for_all_watched(FakeResponse(release_file(1))))):
            self.assertEqual(sury.dropped_releases(), [])

    def test_stale_release_is_dropped(self):
        stale = FakeResponse(release_file(sury.STALE_DAYS + 10))
        with mock.patch.object(sury.urllib.request, "urlopen", serve(for_all_watched(stale))):
            reason = dict(sury.dropped_releases()).get("bullseye")
        self.assertIsNotNone(reason)
        self.assertIn("has not changed for", reason)

    def test_unreadable_date_only_warns(self):
        bad = FakeResponse("Origin: packages.sury.org\nDate: not a date\n")
        with mock.patch.object(sury.urllib.request, "urlopen", serve(for_all_watched(bad))):
            with contextlib.redirect_stderr(io.StringIO()) as err:
                self.assertEqual(sury.dropped_releases(), [])
        self.assertIn("unreadable Date", err.getvalue())

    def test_other_http_errors_only_warn(self):
        responses = for_all_watched(http_error(500))
        with mock.patch.object(sury.urllib.request, "urlopen", serve(responses)):
            with contextlib.redirect_stderr(io.StringIO()) as err:
                self.assertEqual(sury.dropped_releases(), [])
        self.assertIn("cannot read", err.getvalue())

    def test_connection_error_only_warns(self):
        offline = for_all_watched(urllib.error.URLError("offline"))
        with mock.patch.object(sury.urllib.request, "urlopen", serve(offline)):
            with contextlib.redirect_stderr(io.StringIO()) as err:
                self.assertEqual(sury.dropped_releases(), [])
        self.assertIn("cannot read", err.getvalue())

    def test_one_failing_suite_does_not_hide_the_others(self):
        responses = for_all_watched(http_error(500))
        responses["bullseye"] = http_error(404)
        with mock.patch.object(sury.urllib.request, "urlopen", serve(responses)):
            with contextlib.redirect_stderr(io.StringIO()):
                dropped = sury.dropped_releases()
        self.assertIn(("bullseye", "the suite is gone"), dropped)


class FetchIssuesTest(unittest.TestCase):
    def test_lists_both_labels_and_dedupes(self):
        listed = {
            sury.LABEL: [issue(7, body=DROPPED_BODY), issue(8)],
            sury.DROPPED_LABEL: [issue(7, body=DROPPED_BODY)],
        }
        queried = []

        def fake_gh(*args, **_kwargs):
            queried.append(args[3])  # ('issue', 'list', '--label', label, ...)
            return json.dumps(listed[args[3]])

        with mock.patch.object(sury, "gh", side_effect=fake_gh):
            issues = sury.fetch_issues()
        self.assertEqual(queried, [sury.LABEL, sury.DROPPED_LABEL])
        self.assertEqual(sorted(i["number"] for i in issues), [7, 8])

    def test_asks_for_the_labels_needed_to_migrate(self):
        with mock.patch.object(sury, "gh", return_value="[]") as fake_gh:
            sury.fetch_issues()
        self.assertIn("number,state,body,comments,labels", fake_gh.call_args.args)


class MigrateLabelsTest(unittest.TestCase):
    def test_old_dropped_issue_is_moved(self):
        calls = []
        with mock.patch.object(sury, "gh", side_effect=lambda *a, **k: calls.append(a) or ""):
            sury.migrate_labels(
                [issue(9, body=DROPPED_BODY, labels=[sury.LABEL])], dry_run=False)
        self.assertIn(("issue", "edit", "9", "--add-label", sury.DROPPED_LABEL,
                       "--remove-label", sury.LABEL), calls)

    def test_update_issue_is_left_alone(self):
        body = "<!-- sury-update: php7.2 7.2.34-66 -->"
        with mock.patch.object(sury, "gh", side_effect=AssertionError("gh was called")):
            sury.migrate_labels([issue(9, body=body, labels=[sury.LABEL])], dry_run=False)

    def test_dry_run_never_calls_gh(self):
        out = io.StringIO()
        with mock.patch.object(sury, "gh", side_effect=AssertionError("gh was called")):
            with contextlib.redirect_stdout(out):
                sury.migrate_labels(
                    [issue(9, body=DROPPED_BODY, labels=[sury.LABEL])], dry_run=True)
        self.assertIn("move issue #9", out.getvalue())


if __name__ == "__main__":
    unittest.main()
