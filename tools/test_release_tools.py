#!/usr/bin/env python3
"""Tests of the release gate and packaging. Standard library only. Run: python tools/test_release_tools.py"""
import contextlib
import hashlib
import http.server
import io
import json
import os
import socket
import subprocess
import sys
import tarfile
import tempfile
import threading
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

sys.path.insert(0, str(Path(__file__).parent))
import package_release  # noqa: E402
import release_gate  # noqa: E402

PRE_ALPHA = "v0.1.0-pre-alpha.1"
COMMIT = "a" * 40
LATER_COMMIT = "b" * 40
GATE = Path(__file__).with_name("release_gate.py")


def published(version=PRE_ALPHA, target=COMMIT, **changes):
    """A complete, consistent published release, as GitHub describes one."""
    release = {
        "id": 7,
        "tag_name": version,
        "draft": False,
        "prerelease": True,
        "target_commitish": target,
        "assets": [{"name": name, "state": "uploaded"} for name in sorted(release_gate.expected_assets(version))],
    }
    release.update(changes)
    return release


def git(root, *args):
    return subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@t", *args], cwd=root, check=True, capture_output=True, text=True
    ).stdout.strip()


def write(root, name, text="x"):
    path = Path(root, name)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


class Repo:
    """A small git repository with some gameplay in it, and a record that passes every gate."""

    def __init__(self, root):
        self.root = root
        git(root, "init", "-q")
        write(root, "src/main.cpp", "int main;")
        write(root, "project/project.godot", "x")
        write(root, "project/tests/test_a.gd", "x")
        write(root, "docs/readme.md", "x")
        self.commit("start")
        self.evidence = "docs/evidence/m3/accepted.md"
        write(root, self.evidence, "the owner said so")

    def commit(self, message="change"):
        git(self.root, "add", "-A")
        git(self.root, "commit", "-q", "-m", message)

    def gameplay(self):
        return release_gate.fingerprint(self.root)

    def good_record(self, version=PRE_ALPHA, state="publish"):
        label = release_gate.label_of(version)
        return {
            "version": version,
            "milestone": "M3",
            "state": state,
            "summary": "A slice.",
            "owner_acceptance": {
                "status": "accepted",
                "record": self.evidence,
                "build": "dagon-windows from run 1",
                "fingerprint": self.gameplay(),
                "scope": "Keyboard on Windows.",
            },
            "criteria": {key: {"status": "met", "evidence": self.evidence} for key in release_gate.CRITERIA[label]},
            "known_limitations": ["Short."],
            "deferred": ["All physical PlayStation hardware"],
        }

    def save(self, record):
        write(self.root, f"release/{record['version']}.json", json.dumps(record))
        return record

    def evaluate(self, ci_result="success", tags=None, releases=None):
        return release_gate.evaluate(self.root, self.gameplay(), ci_result, tags or {}, (releases or {}).get)


class GateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Repo(self.temporary.name)

    def blocked(self, needle, ci_result="success"):
        outcome, messages, failed = self.repo.evaluate(ci_result)
        self.assertEqual(outcome["publish"], "false")
        self.assertTrue(failed, messages)
        self.assertTrue(any(needle in message and message.startswith("error::") for message in messages), messages)

    def test_every_gate_passed_publishes(self):
        self.repo.save(self.repo.good_record())
        outcome, messages, failed = self.repo.evaluate()
        self.assertEqual(outcome, {"version": PRE_ALPHA, "record": f"release/{PRE_ALPHA}.json", "publish": "true"})
        self.assertFalse(failed, messages)

    def test_failed_ci_blocks_and_packages_nothing(self):
        self.repo.save(self.repo.good_record())
        outcome, messages, failed = self.repo.evaluate("failure")
        self.assertEqual((outcome["version"], outcome["publish"], failed), ("", "false", True))
        self.assertTrue(any("GCC, Clang and MSVC" in message for message in messages), messages)

    def test_a_skipped_or_cancelled_ci_is_not_success(self):
        for result in ("skipped", "cancelled", ""):
            self.repo.save(self.repo.good_record())
            self.blocked("did not succeed", result)

    def test_pending_acceptance_blocks_and_says_so(self):
        record = self.repo.good_record()
        record["owner_acceptance"]["status"] = "pending"
        self.repo.save(record)
        self.blocked("owner gameplay acceptance is pending")

    def test_acceptance_needs_a_record_that_exists(self):
        record = self.repo.good_record()
        record["owner_acceptance"]["record"] = "docs/evidence/m3/nothing.md"
        self.repo.save(record)
        self.blocked("acceptance record does not exist")

    def test_acceptance_must_state_the_build_and_its_scope(self):
        for field, needle in (("build", "which build"), ("scope", "what the acceptance covers")):
            record = self.repo.good_record()
            record["owner_acceptance"][field] = " "
            self.repo.save(record)
            self.blocked(needle)

    def test_changed_gameplay_voids_the_acceptance(self):
        self.repo.save(self.repo.good_record())
        write(self.repo.root, "src/main.cpp", "int changed;")
        self.repo.commit()
        self.blocked("has changed since the owner accepted it")

    def test_a_changed_workflow_blocks_a_record_asking_to_publish(self):
        self.repo.save(self.repo.good_record())
        write(self.repo.root, ".github/workflows/ci.yml", "scons target=template_release optimize=none")
        self.repo.commit()
        self.blocked("has changed since the owner accepted it")

    def test_acceptance_survives_documents_tests_release_tools_and_the_record_itself(self):
        before = self.repo.gameplay()
        for name in ("docs/readme.md", "README.md", "CREDITS.md", "LICENSE", "project/tests/test_a.gd", "tests/unit/test_a.cpp", "tools/ci_annotate.sh", "tools/release_gate.py", "tools/publish_release.sh", "tools/test_release_tools.py", "tools/art/generate.py"):
            write(self.repo.root, name, "changed")
        self.repo.save(self.repo.good_record())
        self.repo.commit()
        self.assertEqual(self.repo.gameplay(), before)
        self.assertEqual(self.repo.evaluate()[0]["publish"], "true")

    def test_acceptance_survives_a_squash(self):
        accepted = self.repo.gameplay()
        git(self.repo.root, "checkout", "-q", "-b", "feature")
        write(self.repo.root, "src/new.cpp", "feature")
        self.repo.commit("one")
        write(self.repo.root, "docs/note.md", "two")
        self.repo.commit("two")
        feature = self.repo.gameplay()
        self.assertNotEqual(feature, accepted)
        git(self.repo.root, "checkout", "-q", "-")
        git(self.repo.root, "merge", "-q", "--squash", "feature")
        self.repo.commit("squashed")
        self.assertEqual(self.repo.gameplay(), feature)

    def test_every_game_build_and_export_input_voids_the_acceptance(self):
        for name in (
            "src/core/a.cpp",
            "project/assets/art.png",
            "project/export_presets.cfg",
            "project/scenes/ui/title.tscn",
            "SConstruct",
            "methods.py",
            ".gitmodules",
            ".gitattributes",
            ".github/workflows/ci.yml",
            ".github/workflows/release.yml",
            "tools/run_godot_checks.sh",
            "tools/export_check.sh",
            "tools/prepare_project.sh",
            "tools/test_storage.sh",
            "tools/package_release.py",
            "tools/install_godot.sh",
            "tools/install_export_templates.sh",
            "tools/extract_templates.py",
        ):
            with self.subTest(name):
                before = self.repo.gameplay()
                write(self.repo.root, name, f"changed {name}")
                self.repo.commit()
                self.assertNotEqual(self.repo.gameplay(), before)

    def test_a_new_godot_cpp_version_voids_the_acceptance(self):
        git(self.repo.root, "update-index", "--add", "--cacheinfo", f"160000,{'1' * 40},godot-cpp")
        git(self.repo.root, "commit", "-q", "-m", "module")
        before = self.repo.gameplay()
        git(self.repo.root, "update-index", "--add", "--cacheinfo", f"160000,{'2' * 40},godot-cpp")
        git(self.repo.root, "commit", "-q", "-m", "module again")
        self.assertNotEqual(self.repo.gameplay(), before)

    def test_every_listed_input_exists_so_a_rename_cannot_silently_drop_it(self):
        root = Path(__file__).parent.parent
        for name in release_gate.ACCEPTANCE_INPUTS:
            self.assertTrue((root / name).exists(), name)

    def test_every_criterion_must_be_met(self):
        for key in release_gate.CRITERIA["pre-alpha"]:
            record = self.repo.good_record()
            record["criteria"][key]["status"] = "pending"
            self.repo.save(record)
            self.blocked(f"({key} is pending)")

    def test_a_deferred_check_is_not_a_pass(self):
        record = self.repo.good_record()
        record["criteria"]["working_controls"]["status"] = "deferred"
        self.repo.save(record)
        self.blocked("(working_controls is deferred)")

    def test_a_missing_criterion_is_not_a_pass(self):
        record = self.repo.good_record()
        del record["criteria"]["interactions"]
        self.repo.save(record)
        self.blocked("(interactions is missing)")

    def test_a_met_criterion_needs_evidence_that_exists(self):
        record = self.repo.good_record()
        record["criteria"]["interactions"]["evidence"] = "docs/none.md"
        self.repo.save(record)
        self.blocked("has no evidence in the repository: interactions")

    def test_known_limitations_must_be_documented(self):
        record = self.repo.good_record()
        record["known_limitations"] = []
        self.repo.save(record)
        self.blocked("known limitations are not documented")

    def test_a_release_candidate_cannot_leave_checks_deferred(self):
        record = self.repo.good_record("v0.3.0-rc.1")
        self.repo.save(record)
        self.blocked("cannot leave checks deferred")

    def test_each_label_has_its_own_criteria(self):
        for version in ("v0.2.0-alpha.1", "v0.3.0-rc.1"):
            with self.subTest(version):
                record = self.repo.good_record(version)
                record["deferred"] = []
                self.repo.save(record)
                self.assertEqual(self.repo.evaluate()[0]["publish"], "true")
                write(self.repo.root, f"release/{version}.json", "{}")
                Path(self.repo.root, f"release/{version}.json").unlink()

    def test_a_pre_alpha_record_cannot_pass_as_alpha(self):
        record = self.repo.good_record()
        record["version"] = "v0.2.0-alpha.1"
        self.repo.save(record)
        self.blocked("is not a alpha criterion")

    def test_stable_and_mislabelled_versions_are_refused(self):
        for version in ("v1.0.0", "v0.1.0", "v1.0.0-rc.1", "v0.2.0-pre-alpha.1", "v0.1.0-beta.1", "v0.3.0-rc.0", "0.1.0-pre-alpha.1", "v0.1.0-pre-alpha.1+x"):
            self.assertTrue(release_gate.version_problems(version), version)

    def test_the_targets_are_allowed_and_a_correction_is_a_new_number(self):
        for version in (PRE_ALPHA, "v0.1.0-pre-alpha.2", "v0.2.0-alpha.1", "v0.3.0-rc.1"):
            self.assertEqual(release_gate.version_problems(version), [], version)

    def test_a_file_must_be_named_for_its_version(self):
        record = self.repo.good_record()
        write(self.repo.root, "release/other.json", json.dumps(record))
        self.blocked("should be named")

    def test_a_complete_release_is_skipped_without_comparing_it_to_head(self):
        self.repo.save(self.repo.good_record())
        write(self.repo.root, "src/main.cpp", "main has moved on")
        self.repo.commit()
        outcome, messages, failed = self.repo.evaluate(tags={PRE_ALPHA: COMMIT}, releases={PRE_ALPHA: published()})
        self.assertEqual((outcome["version"], outcome["publish"], failed), ("", "false", False), messages)
        self.assertTrue(any("already published, at " + COMMIT in message for message in messages), messages)

    def inconsistent(self, needle, tags, releases, state="publish"):
        self.repo.save(self.repo.good_record(state=state))
        outcome, messages, failed = self.repo.evaluate(tags=tags, releases=releases)
        self.assertEqual((outcome["version"], outcome["publish"], failed), ("", "false", True), messages)
        self.assertTrue(any(needle in message and message.startswith("error::") for message in messages), messages)

    def test_a_tag_with_no_published_release_is_a_blocker_in_every_state(self):
        for state in release_gate.STATES:
            with self.subTest(state):
                self.inconsistent(f"the tag exists at {COMMIT}, with no published release", {PRE_ALPHA: COMMIT}, {}, state)

    def test_a_release_whose_tag_moved_is_a_blocker(self):
        self.inconsistent(f"the tag points at {LATER_COMMIT}, and the release recorded the target {COMMIT}", {PRE_ALPHA: LATER_COMMIT}, {PRE_ALPHA: published()})

    def test_a_release_with_no_tag_is_a_blocker(self):
        self.inconsistent("the release has no tag", {}, {PRE_ALPHA: published()})

    def test_a_release_with_a_branch_for_its_target_is_a_blocker(self):
        self.inconsistent("which is not a commit", {PRE_ALPHA: COMMIT}, {PRE_ALPHA: published(target="main")})

    def test_a_release_that_is_not_a_prerelease_is_a_blocker(self):
        self.inconsistent("not marked as a prerelease", {PRE_ALPHA: COMMIT}, {PRE_ALPHA: published(prerelease=False)})

    def test_a_release_marked_as_a_draft_is_a_blocker(self):
        self.inconsistent("the release is not published", {PRE_ALPHA: COMMIT}, {PRE_ALPHA: published(draft=True)})

    def test_a_release_named_for_another_tag_is_a_blocker(self):
        self.inconsistent("named for the tag 'v9'", {PRE_ALPHA: COMMIT}, {PRE_ALPHA: published(tag_name="v9")})

    def test_an_incomplete_publication_is_a_blocker(self):
        release = published()
        release["assets"] = [asset for asset in release["assets"] if asset["name"] != "SHA256SUMS.txt"]
        self.inconsistent("the release is missing: SHA256SUMS.txt", {PRE_ALPHA: COMMIT}, {PRE_ALPHA: release})

    def test_an_upload_that_never_finished_is_a_blocker(self):
        release = published()
        release["assets"][0]["state"] = "starter"
        self.inconsistent("the release is missing: " + release["assets"][0]["name"], {PRE_ALPHA: COMMIT}, {PRE_ALPHA: release})

    def test_an_inconsistent_release_stops_a_different_requested_release(self):
        self.repo.save(self.repo.good_record())
        self.repo.save(self.repo.good_record("v0.1.0-pre-alpha.2"))
        outcome, _, failed = self.repo.evaluate(tags={PRE_ALPHA: COMMIT})
        self.assertEqual((outcome["publish"], failed), ("false", True))

    def test_a_question_that_goes_unanswered_is_not_read_as_absent(self):
        self.repo.save(self.repo.good_record())

        def unanswered(version):
            raise release_gate.StateUnknown("GitHub answered 500")

        with self.assertRaises(release_gate.StateUnknown):
            release_gate.evaluate(self.repo.root, self.repo.gameplay(), "success", {}, unanswered)

    def test_two_requested_releases_stop_both(self):
        self.repo.save(self.repo.good_record())
        self.repo.save(self.repo.good_record("v0.1.0-pre-alpha.2"))
        outcome, messages, failed = self.repo.evaluate()
        self.assertEqual((outcome["publish"], failed), ("false", True))
        self.assertTrue(any("Only one release" in message for message in messages), messages)

    def test_a_planned_record_reports_what_remains_and_does_nothing(self):
        record = self.repo.good_record(state="planned")
        record["owner_acceptance"]["status"] = "pending"
        self.repo.save(record)
        outcome, messages, failed = self.repo.evaluate()
        self.assertEqual((outcome["version"], outcome["publish"], failed), ("", "false", False))
        self.assertTrue(any("owner gameplay acceptance" in message for message in messages), messages)

    def test_a_candidate_is_packaged_and_never_published_even_with_every_gate_passed(self):
        self.repo.save(self.repo.good_record(state="candidate"))
        outcome, _, failed = self.repo.evaluate()
        self.assertEqual((outcome["version"], outcome["publish"], failed), (PRE_ALPHA, "false", False))

    def test_a_candidate_with_open_gates_reports_them_without_failing(self):
        record = self.repo.good_record(state="candidate")
        record["owner_acceptance"]["status"] = "pending"
        self.repo.save(record)
        outcome, messages, failed = self.repo.evaluate()
        self.assertEqual((outcome["version"], outcome["publish"], failed), (PRE_ALPHA, "false", False))
        self.assertTrue(any("Remaining" in message and "acceptance" in message for message in messages), messages)

    def test_a_rehearsal_can_never_be_published(self):
        rehearsal = Path(__file__).with_name("release_rehearsal.json")
        write(self.repo.root, "tools/release_rehearsal.json", rehearsal.read_text(encoding="utf-8"))
        self.repo.save(self.repo.good_record())
        outcome, _, failed = release_gate.evaluate(self.repo.root, self.repo.gameplay(), "success", {}, {}.get, rehearse=True)
        self.assertEqual((outcome["publish"], failed), ("false", False))
        self.assertEqual(outcome["record"], release_gate.REHEARSAL_RECORD)
        self.assertTrue(release_gate.version_problems(outcome["version"]), "its version must be unpublishable")

    def test_the_repository_records_are_valid_and_the_m3_record_has_no_acceptance(self):
        root = Path(__file__).parent.parent
        records = release_gate.load_records(root)
        self.assertTrue(records)
        for path, record in records:
            self.assertEqual(release_gate.format_problems(path, record), [], path.name)
        m3 = next(record for _, record in records if record["version"] == PRE_ALPHA)
        if m3["state"] == "planned":
            self.assertEqual(m3["owner_acceptance"]["status"], "pending")


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for name in package_release.LEGAL:
            write(self.root, f"legal/{name}", name)

    def export(self, platform, proof=None):
        folder = self.root / f"export-{platform}"
        for name in package_release.PLATFORMS[platform]["files"]:
            write(folder, name, name)
        return folder

    def package(self, platform="linux", folder=None, out="out"):
        return package_release.package(platform, PRE_ALPHA, folder or self.export(platform), self.root / "legal", self.root / out)

    def quietly(self, call, *args):
        with contextlib.redirect_stdout(io.StringIO()):
            return call(*args)

    def test_linux_keeps_the_executable_bit_and_only_on_the_binary(self):
        target = self.quietly(self.package)
        self.assertEqual(target.name, f"dagon-{PRE_ALPHA}-linux-x86_64.tar.gz")
        with tarfile.open(target) as archive:
            modes = {Path(member.name).name: member.mode for member in archive.getmembers()}
        self.assertEqual(modes["dagon.x86_64"], 0o755)
        self.assertEqual(modes["dagon.pck"], 0o644)

    def test_a_package_holds_the_export_and_the_license_and_credits(self):
        target = self.quietly(self.package, "windows")
        self.assertEqual(target.name, f"dagon-{PRE_ALPHA}-windows-x86_64.zip")
        with zipfile.ZipFile(target) as archive:
            names = sorted(Path(name).name for name in archive.namelist())
        self.assertEqual(names, ["CREDITS.md", "LICENSE", "dagon.exe", "dagon.pck", "dagon.windows.template_release.x86_64.dll"])

    def test_the_same_export_gives_the_same_package(self):
        for platform in package_release.PLATFORMS:
            first = self.quietly(self.package, platform, None, "one").read_bytes()
            second = self.quietly(self.package, platform, None, "two").read_bytes()
            self.assertEqual(hashlib.sha256(first).digest(), hashlib.sha256(second).digest(), platform)

    def test_a_package_has_the_same_bytes_whenever_it_is_made(self):
        for platform in package_release.PLATFORMS:
            folder = self.export(platform)
            digests = set()
            for clock in (1_000_000_000, 2_000_000_000):
                for path in folder.iterdir():
                    os.utime(path, (clock, clock))
                with mock.patch("time.time", return_value=clock):
                    target = self.quietly(self.package, platform, folder, f"{platform}-{clock}")
                digests.add(hashlib.sha256(target.read_bytes()).hexdigest())
            self.assertEqual(len(digests), 1, platform)

    def test_the_gzip_header_holds_no_time_and_no_file_name(self):
        with mock.patch("time.time", return_value=2_000_000_000):
            data = self.quietly(self.package).read_bytes()
        self.assertEqual(data[:2], b"\x1f\x8b")
        self.assertEqual(data[3], 0, "the FNAME flag is set")
        self.assertEqual(int.from_bytes(data[4:8], "little"), 0, "the gzip MTIME field is set")

    def test_timestamps_inside_a_package_are_fixed(self):
        with zipfile.ZipFile(self.quietly(self.package, "windows")) as archive:
            self.assertEqual({info.date_time for info in archive.infolist()}, {(1980, 1, 1, 0, 0, 0)})
        with tarfile.open(self.quietly(self.package, "linux")) as archive:
            self.assertEqual({member.mtime for member in archive.getmembers()}, {0})

    def test_an_incomplete_or_extra_export_is_refused(self):
        folder = self.export("linux")
        (folder / "dagon.pck").unlink()
        with self.assertRaises(SystemExit) as missing:
            self.package("linux", folder)
        self.assertIn("should hold exactly", str(missing.exception))
        write(folder, "dagon.pck")
        write(folder, "extra.txt")
        with self.assertRaises(SystemExit):
            self.package("linux", folder)

    def fake_game(self, lines, code=0):
        """A shell script stands in for the game, so these run on Linux, which is where CI runs them."""
        folder = self.export("linux")
        script = "#!/bin/sh\n" + "".join(f'echo "{line}"\n' for line in lines)
        script += 'if [ "$DAGON_AUTOSTART" = new_game ]; then echo x > "$DAGON_STORAGE_DIR/save.dat"; fi\n'
        script += f"exit {code}\n"
        write(folder, "dagon.x86_64", script)
        return self.quietly(self.package, "linux", folder)

    GOOD = (
        "dagon: extension initialized build=release",
        "Completed load for: 'res://scenes/ui/title.tscn'",
        "dagon: session start beat=0 persisted=0",
        "dagon: prompt: [E] Examine",
    )

    def smoke(self, target):
        return self.quietly(package_release.smoke, "linux", target)

    def test_smoke_passes_on_a_game_that_gives_every_proof(self):
        self.smoke(self.fake_game(self.GOOD))

    def test_smoke_fails_when_any_proof_is_missing(self):
        for missing in self.GOOD:
            with self.subTest(missing), self.assertRaises(SystemExit) as caught:
                self.smoke(self.fake_game([line for line in self.GOOD if line != missing]))
            self.assertIn(missing, str(caught.exception))

    def test_smoke_fails_on_an_exit_code_or_a_logged_error(self):
        with self.assertRaises(SystemExit) as code:
            self.smoke(self.fake_game(self.GOOD, code=3))
        self.assertIn("exited with 3", str(code.exception))
        with self.assertRaises(SystemExit) as error:
            self.smoke(self.fake_game((*self.GOOD, "ERROR: something broke")))
        self.assertIn("logged errors", str(error.exception))


class PrepareTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = Repo(self.temporary.name)
        write(self.root, "fake-module", "x")
        git(self.root, "update-index", "--add", "--cacheinfo", f"160000,{'1' * 40},godot-cpp")
        git(self.root, "commit", "-q", "-m", "module")
        self.commit = git(self.root, "rev-parse", "HEAD")
        self.record = write(self.root, "record.json", json.dumps(self.repo.good_record()))
        for name in (f"dagon-{PRE_ALPHA}-linux-x86_64.tar.gz", f"dagon-{PRE_ALPHA}-windows-x86_64.zip"):
            write(self.root, f"packages/{name}", name)
        for job, compiler in (("logs-windows", "MSVC 19"), ("logs-linux", "g++ 11"), ("logs-linux-clang", "clang 18")):
            write(self.root, f"logs/{job}/build-release.log", f"other\ndagon: compiler: {compiler}\n")
        write(self.root, "logs/logs-linux/godot/godot-version.txt", "4.7.2.stable\n")

    def prepare(self):
        args = SimpleNamespace(
            record=str(self.record),
            packages=str(self.root / "packages"),
            logs=str(self.root / "logs"),
            out=str(self.root / "prepared"),
            commit=self.commit,
            run_url="https://example/run/1",
        )
        previous = os.getcwd()
        os.chdir(self.root)
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                release_gate.prepare(args)
        finally:
            os.chdir(previous)
        return self.root / "prepared"

    def test_notes_state_the_commit_limits_and_what_was_not_tested(self):
        notes = (self.prepare() / "RELEASE_NOTES.md").read_text(encoding="utf-8")
        for expected in (self.commit, "Short.", "Keyboard on Windows.", "https://example/run/1", "MSVC 19", "g++ 11", "clang 18", "4.7.2.stable", "not a stable release", "not a jam submission"):
            self.assertIn(expected, notes)
        not_tested = notes.split("## Not tested", 1)[1].split("##", 1)[0]
        self.assertIn("have not passed", not_tested)
        self.assertIn("PlayStation", not_tested)
        self.assertIn("Validation only, not shipped: clang 18", notes)

    def test_notes_claim_acceptance_only_when_it_covers_this_build(self):
        record = json.loads(self.record.read_text(encoding="utf-8"))
        claim, none = "so the acceptance applies to it", "No owner acceptance covers this build"
        record["owner_acceptance"]["fingerprint"] = self.repo.gameplay()
        self.record.write_text(json.dumps(record), encoding="utf-8")
        notes = (self.prepare() / "RELEASE_NOTES.md").read_text(encoding="utf-8")
        self.assertIn(claim, notes)
        self.assertNotIn(none, notes)
        for change in ({"status": "pending"}, {"fingerprint": "sha256:other"}):
            with self.subTest(change):
                altered = dict(record, owner_acceptance={**record["owner_acceptance"], **change})
                self.record.write_text(json.dumps(altered), encoding="utf-8")
                notes = (self.prepare() / "RELEASE_NOTES.md").read_text(encoding="utf-8")
                self.assertNotIn(claim, notes)
                self.assertNotIn("Keyboard on Windows.", notes)
                self.assertIn(none, notes)

    def test_the_rehearsal_record_can_be_prepared(self):
        self.record.write_text(Path(__file__).with_name("release_rehearsal.json").read_text(encoding="utf-8"), encoding="utf-8")
        for name in list((self.root / "packages").iterdir()):
            name.rename(name.with_name(name.name.replace(PRE_ALPHA, "v0.1.0-pre-alpha.0")))
        notes = (self.prepare() / "RELEASE_NOTES.md").read_text(encoding="utf-8")
        self.assertIn("rehearsal", notes)
        self.assertIn("No owner acceptance covers this build", notes)

    def test_checksums_verify_and_provenance_names_the_commit(self):
        prepared = self.prepare()
        lines = (prepared / "SHA256SUMS.txt").read_text(encoding="utf-8").splitlines()
        self.assertEqual(len(lines), 2)
        for line in lines:
            value, name = line.split("  ", 1)
            self.assertEqual(hashlib.sha256((prepared / name).read_bytes()).hexdigest(), value)
        provenance = (prepared / "PROVENANCE.txt").read_text(encoding="utf-8")
        self.assertIn(f"Source commit: {self.commit}", provenance)
        self.assertIn(f"godot-cpp: {'1' * 40}", provenance)

    def test_a_missing_compiler_stops_the_release(self):
        for job in ("logs-windows", "logs-linux", "logs-linux-clang"):
            with self.subTest(job):
                log = self.root / "logs" / job / "build-release.log"
                saved = log.read_text(encoding="utf-8")
                log.write_text("nothing\n", encoding="utf-8")
                with self.assertRaises(SystemExit) as caught:
                    self.prepare()
                self.assertIn("Provenance is incomplete", str(caught.exception))
                log.write_text(saved, encoding="utf-8")

    def test_more_than_one_package_per_os_is_refused(self):
        write(self.root, f"packages/dagon-{PRE_ALPHA}-linux-clang-x86_64.tar.gz")
        with self.assertRaises(SystemExit) as caught:
            self.prepare()
        self.assertIn("exactly one package per OS", str(caught.exception))


class FakeGitHub:
    """A local stand-in for GitHub's API, so real requests meet real failures."""

    REPOSITORY = "/repos/owner/name"
    TOKEN = "fake-token-that-must-never-be-printed"

    def __init__(self):
        self.routes = {self.REPOSITORY: (200, {})}
        self.requests = []
        outer = self

        class Handler(http.server.BaseHTTPRequestHandler):
            def answer(self):
                outer.requests.append((self.command, self.path, self.headers.get("Authorization")))
                status, body = outer.routes.get(self.path, (404, {"message": "Not Found"}))
                data = body if isinstance(body, bytes) else json.dumps(body).encode()
                self.send_response(status)
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            do_GET = do_DELETE = answer

            def log_message(self, *args):
                pass

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.url = f"http://127.0.0.1:{self.server.server_address[1]}"
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def close(self):
        self.server.shutdown()
        self.server.server_close()

    def client(self):
        return release_gate.GitHub(self.url, "owner/name", self.TOKEN)

    def release_route(self, version=PRE_ALPHA):
        return f"{self.REPOSITORY}/releases/tags/{version}"

    def list_route(self, page=1):
        return f"{self.REPOSITORY}/releases?per_page=100&page={page}"


class GitHubTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeGitHub()
        self.addCleanup(self.api.close)

    def test_a_published_release_is_found_with_the_token_sent(self):
        self.api.routes[self.api.release_route()] = (200, published())
        self.assertEqual(self.api.client().published_release(PRE_ALPHA)["tag_name"], PRE_ALPHA)
        self.assertEqual(self.api.requests[-1][2], f"Bearer {self.api.TOKEN}")

    def test_only_a_404_means_absent(self):
        self.assertIsNone(self.api.client().published_release(PRE_ALPHA))

    def test_every_other_answer_is_unknown_and_never_shows_the_token(self):
        for status in (401, 403, 429, 500, 502, 503):
            with self.subTest(status):
                self.api.routes[self.api.release_route()] = (status, {"message": "no"})
                with self.assertRaises(release_gate.StateUnknown) as caught:
                    self.api.client().published_release(PRE_ALPHA)
                self.assertIn(str(status), str(caught.exception))
                self.assertNotIn(self.api.TOKEN, str(caught.exception))

    def test_a_repository_it_cannot_see_is_unknown_and_not_absent(self):
        self.api.routes[self.api.REPOSITORY] = (404, {"message": "Not Found"})
        with self.assertRaises(release_gate.StateUnknown):
            self.api.client().published_release(PRE_ALPHA)

    def test_a_failed_login_is_unknown(self):
        self.api.routes[self.api.REPOSITORY] = (401, {"message": "Bad credentials"})
        with self.assertRaises(release_gate.StateUnknown):
            self.api.client().published_release(PRE_ALPHA)

    def test_a_refused_connection_is_unknown(self):
        with socket.socket() as closed:
            closed.bind(("127.0.0.1", 0))
            port = closed.getsockname()[1]
        with self.assertRaises(release_gate.StateUnknown):
            release_gate.GitHub(f"http://127.0.0.1:{port}", "owner/name", "t").published_release(PRE_ALPHA)

    def test_an_answer_it_cannot_read_is_unknown(self):
        self.api.routes[self.api.release_route()] = (200, b"<html>not json</html>")
        with self.assertRaises(release_gate.StateUnknown):
            self.api.client().published_release(PRE_ALPHA)

    def test_no_token_is_unknown(self):
        with self.assertRaises(release_gate.StateUnknown):
            release_gate.GitHub(self.api.url, "owner/name", "").published_release(PRE_ALPHA)

    def test_the_list_of_releases_reads_every_page(self):
        self.api.routes[self.api.list_route(1)] = (200, [published(f"other{i}") for i in range(100)])
        self.api.routes[self.api.list_route(2)] = (200, [published(draft=True, id=9)])
        found = self.api.client().all_releases()
        self.assertEqual(len(found), 101)
        self.assertEqual(found[-1]["id"], 9)

    def test_a_page_that_is_not_there_is_unknown_and_does_not_end_the_list(self):
        self.api.routes[self.api.list_route(1)] = (200, [published(f"other{i}") for i in range(100)])
        with self.assertRaises(release_gate.StateUnknown):
            self.api.client().all_releases()

    def test_a_failed_page_is_unknown(self):
        self.api.routes[self.api.list_route(1)] = (200, [published(f"other{i}") for i in range(100)])
        self.api.routes[self.api.list_route(2)] = (500, {})
        with self.assertRaises(release_gate.StateUnknown):
            self.api.client().all_releases()

    def test_a_draft_is_deleted_only_after_looking_again(self):
        route = f"{self.api.REPOSITORY}/releases/9"
        self.api.routes[route] = (200, published(draft=True, id=9))
        self.api.client().delete_draft(9)
        self.assertIn(("DELETE", route, f"Bearer {self.api.TOKEN}"), self.api.requests)

    def test_a_published_release_is_never_deleted(self):
        route = f"{self.api.REPOSITORY}/releases/9"
        self.api.routes[route] = (200, published(id=9))
        with self.assertRaises(release_gate.StateUnknown):
            self.api.client().delete_draft(9)
        self.assertFalse([request for request in self.api.requests if request[0] == "DELETE"])


class PublisherChecksTests(unittest.TestCase):
    """The publisher's own checks, inside the publication lock."""

    def setUp(self):
        self.deleted = []
        self.reports = []

    def preflight(self, tags, releases):
        return release_gate.preflight(PRE_ALPHA, tags, releases, self.deleted.append, self.reports.append)

    def test_nothing_there_creates(self):
        self.assertEqual(self.preflight({}, []), "create")
        self.assertEqual(self.deleted, [])

    def test_another_versions_release_changes_nothing(self):
        self.assertEqual(self.preflight({"v0.0.1": COMMIT}, [published("v0.0.1", draft=True, id=3)]), "create")
        self.assertEqual(self.deleted, [])

    def test_a_failed_attempts_draft_is_removed_and_retried(self):
        self.assertEqual(self.preflight({}, [published(draft=True, id=5), published(draft=True, id=6)]), "create")
        self.assertEqual(self.deleted, [5, 6])

    def test_a_complete_release_is_skipped(self):
        self.assertEqual(self.preflight({PRE_ALPHA: COMMIT}, [published()]), "skip")
        self.assertEqual(self.deleted, [])

    def test_a_tag_with_only_a_draft_is_a_blocker_and_nothing_is_removed(self):
        with self.assertRaises(release_gate.StateUnknown) as caught:
            self.preflight({PRE_ALPHA: COMMIT}, [published(draft=True, id=5)])
        self.assertIn("with no published release", str(caught.exception))
        self.assertEqual(self.deleted, [])

    def test_a_published_release_beside_a_draft_is_a_blocker_and_nothing_is_removed(self):
        with self.assertRaises(release_gate.StateUnknown):
            self.preflight({PRE_ALPHA: COMMIT}, [published(), published(draft=True, id=5)])
        self.assertEqual(self.deleted, [])

    def test_an_inconsistent_release_is_a_blocker(self):
        with self.assertRaises(release_gate.StateUnknown):
            self.preflight({PRE_ALPHA: LATER_COMMIT}, [published()])

    def test_a_release_that_does_not_say_whether_it_is_a_draft_is_a_blocker(self):
        release = published()
        del release["draft"]
        with self.assertRaises(release_gate.StateUnknown):
            self.preflight({}, [release])
        self.assertEqual(self.deleted, [])

    def test_verify_passes_only_at_the_tested_commit(self):
        self.assertEqual(release_gate.verify(PRE_ALPHA, COMMIT, {PRE_ALPHA: COMMIT}, published()), [])
        self.assertTrue(release_gate.verify(PRE_ALPHA, LATER_COMMIT, {PRE_ALPHA: COMMIT}, published()))
        self.assertTrue(release_gate.verify(PRE_ALPHA, COMMIT, {}, None))
        self.assertTrue(release_gate.verify(PRE_ALPHA, COMMIT, {PRE_ALPHA: COMMIT}, None))


class CommandLineTests(unittest.TestCase):
    """The commands as the workflow runs them: a real remote for the tags, and real requests to the fake API."""

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.remote = Path(self.temporary.name, "remote.git")
        self.root = Path(self.temporary.name, "work")
        self.root.mkdir()
        subprocess.run(["git", "init", "-q", "--bare", str(self.remote)], check=True)
        self.repo = Repo(str(self.root))
        git(self.root, "remote", "add", "origin", str(self.remote))
        self.repo.save(self.repo.good_record())
        self.repo.commit("record")
        self.commit = git(self.root, "rev-parse", "HEAD")
        self.api = FakeGitHub()
        self.addCleanup(self.api.close)
        self.output = Path(self.temporary.name, "output")

    def run_gate(self, *args):
        environment = dict(os.environ, GITHUB_API_URL=self.api.url, GITHUB_REPOSITORY="owner/name", GH_TOKEN=self.api.TOKEN, GITHUB_OUTPUT=str(self.output))
        environment.pop("GITHUB_STEP_SUMMARY", None)
        result = subprocess.run([sys.executable, str(GATE), *args], cwd=self.root, env=environment, capture_output=True, text=True, timeout=60)
        self.assertNotIn(self.api.TOKEN, result.stdout + result.stderr)
        return result

    def evaluate(self):
        result = self.run_gate("evaluate", "--ci-result", "success")
        outcome = dict(line.split("=", 1) for line in self.output.read_text().splitlines()) if self.output.exists() else {}
        return result, outcome

    def tag(self, commit=None):
        git(self.root, "tag", PRE_ALPHA, commit or self.commit)
        git(self.root, "push", "-q", "origin", f"refs/tags/{PRE_ALPHA}")

    def test_nothing_published_yet_goes_ahead(self):
        result, outcome = self.evaluate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((outcome["version"], outcome["publish"]), (PRE_ALPHA, "true"))

    def test_a_real_tag_with_no_release_fails_and_names_the_tag(self):
        self.tag()
        result, outcome = self.evaluate()
        self.assertEqual(result.returncode, 1)
        self.assertIn(f"the tag exists at {self.commit}, with no published release", result.stdout)
        self.assertEqual((outcome["version"], outcome["publish"]), ("", "false"))

    def test_a_complete_release_is_skipped_on_a_later_commit(self):
        self.tag()
        self.api.routes[self.api.release_route()] = (200, published(target=self.commit))
        write(self.root, "src/main.cpp", "main has moved on")
        self.repo.commit("later")
        result, outcome = self.evaluate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"already published, at {self.commit}", result.stdout)
        self.assertEqual((outcome["version"], outcome["publish"]), ("", "false"))

    def test_an_annotated_tag_is_compared_by_its_commit(self):
        git(self.root, "tag", "-a", PRE_ALPHA, "-m", "annotated", self.commit)
        git(self.root, "push", "-q", "origin", f"refs/tags/{PRE_ALPHA}")
        self.api.routes[self.api.release_route()] = (200, published(target=self.commit))
        result, _ = self.evaluate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_an_api_failure_stops_everything_and_says_so(self):
        for status in (401, 403, 500):
            with self.subTest(status):
                self.api.routes[self.api.release_route()] = (status, {})
                self.output.unlink(missing_ok=True)
                result, outcome = self.evaluate()
                self.assertEqual(result.returncode, 1)
                self.assertIn(f"GitHub answered {status}", result.stdout)
                self.assertIn("could not be determined", result.stdout)
                self.assertEqual((outcome["version"], outcome["publish"]), ("", "false"))

    def test_a_tag_listing_failure_stops_everything_and_says_so(self):
        git(self.root, "remote", "set-url", "origin", str(Path(self.temporary.name, "gone.git")))
        result, outcome = self.evaluate()
        self.assertEqual(result.returncode, 1)
        self.assertIn("could not list the remote tags", result.stdout)
        self.assertEqual((outcome["version"], outcome["publish"]), ("", "false"))

    def test_preflight_removes_a_failed_attempts_draft_then_says_create(self):
        self.api.routes[self.api.list_route()] = (200, [published(draft=True, id=9)])
        self.api.routes[f"{self.api.REPOSITORY}/releases/9"] = (200, published(draft=True, id=9))
        result = self.run_gate("preflight", "--version", PRE_ALPHA)
        self.assertEqual((result.returncode, result.stdout.strip()), (0, "create"), result.stderr)
        self.assertTrue([request for request in self.api.requests if request[0] == "DELETE"])

    def test_preflight_says_skip_for_a_complete_release(self):
        self.tag()
        self.api.routes[self.api.list_route()] = (200, [published(target=self.commit)])
        result = self.run_gate("preflight", "--version", PRE_ALPHA)
        self.assertEqual((result.returncode, result.stdout.strip()), (0, "skip"), result.stderr)
        self.assertFalse([request for request in self.api.requests if request[0] == "DELETE"])

    def test_preflight_fails_and_gives_no_decision_when_it_cannot_tell(self):
        self.api.routes[self.api.list_route()] = (500, {})
        result = self.run_gate("preflight", "--version", PRE_ALPHA)
        self.assertEqual((result.returncode, result.stdout.strip()), (1, ""))
        self.assertIn("GitHub answered 500", result.stderr)

    def test_preflight_leaves_a_tag_and_its_draft_alone(self):
        self.tag()
        self.api.routes[self.api.list_route()] = (200, [published(draft=True, id=9)])
        result = self.run_gate("preflight", "--version", PRE_ALPHA)
        self.assertEqual(result.returncode, 1)
        self.assertFalse([request for request in self.api.requests if request[0] == "DELETE"])
        self.assertTrue(git(self.root, "ls-remote", "--tags", "origin"))

    def test_verify_after_publishing(self):
        self.tag()
        self.api.routes[self.api.release_route()] = (200, published(target=self.commit))
        self.assertEqual(self.run_gate("verify", "--version", PRE_ALPHA, "--commit", self.commit).returncode, 0)
        self.assertEqual(self.run_gate("verify", "--version", PRE_ALPHA, "--commit", LATER_COMMIT).returncode, 1)
        self.api.routes[self.api.release_route()] = (500, {})
        failed = self.run_gate("verify", "--version", PRE_ALPHA, "--commit", self.commit)
        self.assertEqual(failed.returncode, 1)
        self.assertIn("GitHub answered 500", failed.stdout)


class WorkflowTests(unittest.TestCase):
    """The rules a YAML typo could silently drop. actionlint checks the syntax."""

    root = Path(__file__).parent.parent
    release = (root / ".github/workflows/release.yml").read_text(encoding="utf-8")
    ci = (root / ".github/workflows/ci.yml").read_text(encoding="utf-8")

    def job(self, name):
        return self.release.split(f"\n  {name}:\n", 1)[1]

    def test_only_the_publish_job_can_write_and_only_from_main(self):
        self.assertEqual(self.release.count("contents: write"), 1)
        publish = self.job("publish")
        self.assertIn("contents: write", publish)
        self.assertIn("github.ref == 'refs/heads/main'", publish)
        self.assertIn("github.event_name == 'push'", publish)
        self.assertIn("needs.gate.outputs.publish == 'true'", publish)

    def test_publication_is_serialized_and_never_cancelled(self):
        publish = self.job("publish")
        self.assertIn("group: release-publication", publish)
        self.assertIn("cancel-in-progress: false", publish)

    def test_no_secret_but_the_runs_own_token(self):
        for text in (self.release, self.ci):
            self.assertNotIn("secrets.", text)
        self.assertIn("github.token", self.job("publish"))

    def test_the_three_compilers_must_pass_and_clang_never_ships(self):
        self.assertIn("name: linux\n", self.ci)
        self.assertIn("name: windows\n", self.ci)
        self.assertIn("name: linux-clang\n", self.ci)
        clang = self.ci.split("- name: linux-clang\n", 1)[1].split("    env:", 1)[0]
        self.assertIn("ships: false", clang)
        self.assertIn("use_llvm=yes", clang)
        self.assertIn('if: ${{ matrix.ships }}\n        uses: actions/upload-artifact@v7\n        with:\n          name: dagon-', self.ci)
        self.assertIn("needs: [desktop, release-tools]", self.ci)
        self.assertIn("needs.desktop.result == 'success' && needs.release-tools.result == 'success'", self.ci)

    def test_the_publisher_never_forces_or_moves_anything(self):
        script = (self.root / "tools/publish_release.sh").read_text(encoding="utf-8")
        for forbidden in ("--force", "git push", "git tag", "--cleanup-tag", "gh release delete", "|| echo", "|| true", "2> /dev/null"):
            self.assertNotIn(forbidden, script)
        order = [script.index(step) for step in ("release_gate.py preflight", "--draft --prerelease", "sha256sum -c", "--draft=false", "release_gate.py verify")]
        self.assertEqual(order, sorted(order))

    def test_the_gate_asks_github_with_a_read_only_token(self):
        gate = self.job("gate").split("\n  package:", 1)[0]
        self.assertIn("GH_TOKEN: ${{ github.token }}", gate)
        self.assertNotIn("contents: write", gate)


if __name__ == "__main__":
    unittest.main(verbosity=1)
