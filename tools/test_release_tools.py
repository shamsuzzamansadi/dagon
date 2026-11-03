#!/usr/bin/env python3
"""Tests of the release gate and packaging. Standard library only. Run: python tools/test_release_tools.py"""
import contextlib
import hashlib
import io
import json
import os
import subprocess
import sys
import tarfile
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).parent))
import package_release  # noqa: E402
import release_gate  # noqa: E402

PRE_ALPHA = "v0.1.0-pre-alpha.1"


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
                "gameplay_fingerprint": self.gameplay(),
                "scope": "Keyboard on Windows.",
            },
            "criteria": {key: {"status": "met", "evidence": self.evidence} for key in release_gate.CRITERIA[label]},
            "known_limitations": ["Short."],
            "deferred": ["All physical PlayStation hardware"],
        }

    def save(self, record):
        write(self.root, f"release/{record['version']}.json", json.dumps(record))
        return record

    def evaluate(self, ci_result="success", tags=()):
        return release_gate.evaluate(self.root, self.gameplay(), ci_result, set(tags))


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
        self.blocked("gameplay has changed since the owner accepted it")

    def test_acceptance_survives_documents_tests_and_the_record_itself(self):
        before = self.repo.gameplay()
        write(self.repo.root, "docs/readme.md", "changed")
        write(self.repo.root, "project/tests/test_a.gd", "changed")
        write(self.repo.root, ".github/workflows/ci.yml", "changed")
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

    def test_the_build_inputs_count_as_gameplay(self):
        for name in ("project/assets/art.png", "SConstruct", "tools/install_godot.sh"):
            before = self.repo.gameplay()
            write(self.repo.root, name, "changed")
            self.repo.commit()
            self.assertNotEqual(self.repo.gameplay(), before, name)

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

    def test_an_existing_tag_is_never_published_again(self):
        self.repo.save(self.repo.good_record())
        outcome, messages, failed = self.repo.evaluate(tags=[PRE_ALPHA])
        self.assertEqual((outcome["version"], outcome["publish"], failed), ("", "false", False))
        self.assertTrue(any("already published" in message for message in messages), messages)

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
        outcome, _, failed = release_gate.evaluate(self.repo.root, self.repo.gameplay(), "success", set(), rehearse=True)
        self.assertEqual((outcome["publish"], failed), ("false", False))
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
        record = self.repo.good_record()
        self.record = write(self.root, "record.json", json.dumps(record))
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
        for forbidden in ("--force", "git push", "git tag", "--cleanup-tag"):
            self.assertNotIn(forbidden, script)
        self.assertLess(script.index("--draft --prerelease"), script.index("--draft=false"))
        self.assertLess(script.index("sha256sum -c"), script.index("--draft=false"))


if __name__ == "__main__":
    unittest.main(verbosity=1)
