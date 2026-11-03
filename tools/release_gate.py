#!/usr/bin/env python3
"""Decides whether a milestone prerelease may be published, and prepares its notes. Standard library only.

A release is requested by a record in release/, merged through a pull request. Reaching a milestone never
publishes anything. See docs/release.md.

  evaluate    What is due at this commit. Writes the outcome for the workflow, and names every blocker.
  validate    Checks that every record is well formed. Runs on every pull request.
  fingerprint Prints this commit's gameplay fingerprint, for an owner acceptance record.
  prepare     Writes the notes, checksums and provenance beside the packages.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

RECORDS_DIR = "release"
REHEARSAL_RECORD = "tools/release_rehearsal.json"

# What makes up the game a player receives. An owner's acceptance stays valid while this is unchanged, so
# documents, tests and CI changes do not need a new playthrough. docs/release.md states the exact scope.
GAMEPLAY_PATHS = (
    "src",
    "project",
    "SConstruct",
    "methods.py",
    "godot-cpp",
    "tools/install_godot.sh",
    "tools/install_export_templates.sh",
    "tools/extract_templates.py",
)
NOT_GAMEPLAY = ("project/tests/",)

# Each label has one base version, so a stable or 1.0 version cannot be expressed. A correction takes the next
# number, as a published version is never replaced. A rehearsal uses .0, which can never be published.
LABELS = {"pre-alpha": "0.1.0", "alpha": "0.2.0", "rc": "0.3.0"}
VERSION = re.compile(r"^v(?P<base>\d+\.\d+\.\d+)-(?P<label>[a-z-]+)\.(?P<number>[1-9]\d*)$")

# What each label promises. Each must be marked met, and must point at evidence in the repository.
CRITERIA = {
    "pre-alpha": {
        "playable_slice": "a usable playable slice",
        "working_controls": "working controls",
        "interactions": "working interactions",
        "checkpoint_persistence": "checkpoint persistence",
    },
    "alpha": {
        "playable_start_to_end": "the intended game is playable from beginning to end",
        "principal_gameplay_connected": "its principal gameplay is connected",
        "principal_audio_heard": "its principal audio is connected and has been heard in gameplay",
    },
    "rc": {
        "intended_scope_complete": "the intended scope is complete",
        "no_known_release_blockers": "there are no known release-blocking defects",
        "final_acceptance_checks_passed": "the final acceptance checks have passed",
    },
}
STATES = ("planned", "candidate", "publish")
LABEL_MEANING = {
    "pre-alpha": "A usable slice of the game, not the whole of it.",
    "alpha": "The intended game, playable from beginning to end, and still unfinished.",
    "rc": "A release candidate: the intended scope is complete, and it is still a prerelease.",
}


def version_problems(version):
    match = VERSION.match(version or "")
    if not match:
        return [f"'{version}' is not a prerelease version of the form vX.Y.Z-label.N"]
    label = match.group("label")
    if label not in LABELS:
        return [f"'{label}' is not an authorized label: {', '.join(LABELS)}"]
    if match.group("base") != LABELS[label]:
        return [f"a {label} build is version {LABELS[label]}, not {match.group('base')}"]
    return []


def label_of(version):
    """The label of any prerelease-shaped version, including a rehearsal's .0, which version_problems refuses."""
    match = re.match(r"^v\d+\.\d+\.\d+-([a-z-]+)\.\d+$", version or "")
    return match.group(1) if match and match.group(1) in LABELS else None


def fingerprint(root=".", commit="HEAD"):
    """A hash of exactly what ships. It survives a squash merge, which changes the commit and not the files."""
    listing = subprocess.run(
        ["git", "ls-tree", "-r", commit, "--", *GAMEPLAY_PATHS],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    lines = [line for line in listing.splitlines() if not line.split("\t", 1)[1].startswith(NOT_GAMEPLAY)]
    return "sha256:" + hashlib.sha256("\n".join(sorted(lines)).encode()).hexdigest()


def existing_tags(root="."):
    listing = subprocess.run(
        ["git", "ls-remote", "--tags", "origin"], cwd=root, check=True, capture_output=True, text=True
    ).stdout
    return {line.split("refs/tags/", 1)[1].removesuffix("^{}") for line in listing.splitlines()}


def load_records(root="."):
    records = []
    for path in sorted(Path(root, RECORDS_DIR).glob("*.json")):
        try:
            records.append((path, json.loads(path.read_text(encoding="utf-8"))))
        except json.JSONDecodeError as error:
            raise SystemExit(f"::error::{path.name} is not valid JSON: {error}") from error
    return records


def format_problems(path, record):
    """Whether a record is well formed, whatever its state."""
    problems = version_problems(record.get("version"))
    if Path(path).stem != record.get("version"):
        problems.append(f"the file should be named {record.get('version')}.json")
    if record.get("state") not in STATES:
        problems.append(f"state must be one of {', '.join(STATES)}, not '{record.get('state')}'")
    label = label_of(record.get("version") or "")
    for key in record.get("criteria", {}):
        if label in CRITERIA and key not in CRITERIA[label]:
            problems.append(f"'{key}' is not a {label} criterion")
    return problems


def gate_blockers(record, root, gameplay, ci_result):
    """Everything standing between this record and publication. An empty list means it may be published."""
    blockers = []
    if ci_result != "success":
        blockers.append(f"CI on this commit did not succeed on GCC, Clang and MSVC: {ci_result}")

    acceptance = record.get("owner_acceptance", {})
    if acceptance.get("status") != "accepted":
        blockers.append(f"owner gameplay acceptance is {acceptance.get('status', 'missing')}, and must be accepted")
    else:
        evidence = acceptance.get("record", "")
        if not evidence or not Path(root, evidence).is_file():
            blockers.append(f"the owner acceptance record does not exist: '{evidence}'")
        for field, what in (("build", "which build the owner tested"), ("scope", "what the acceptance covers")):
            if not str(acceptance.get(field, "")).strip():
                blockers.append(f"the owner acceptance does not state {what}")
        accepted = acceptance.get("gameplay_fingerprint", "")
        if accepted != gameplay:
            blockers.append(
                f"gameplay has changed since the owner accepted it, so that acceptance does not cover this build: "
                f"accepted {accepted or 'nothing'}, this commit {gameplay}"
            )

    label = label_of(record.get("version") or "")
    criteria = record.get("criteria", {})
    for key, meaning in CRITERIA.get(label, {}).items():
        entry = criteria.get(key, {})
        if entry.get("status") != "met":
            blockers.append(f"{label} criterion not met: {meaning} ({key} is {entry.get('status', 'missing')})")
        elif not entry.get("evidence") or not Path(root, entry["evidence"]).is_file():
            blockers.append(f"{label} criterion has no evidence in the repository: {key}: '{entry.get('evidence', '')}'")

    if not str(record.get("summary", "")).strip():
        blockers.append("the release notes have no summary")
    if not record.get("known_limitations"):
        blockers.append("known limitations are not documented")
    if label == "rc" and record.get("deferred"):
        blockers.append("a release candidate cannot leave checks deferred: " + "; ".join(record["deferred"]))
    return blockers


def evaluate(root, gameplay, ci_result, tags, rehearse=False):
    """Returns (outcome, messages, failed). Outcome is what the workflow needs: version, record and publish."""
    outcome = {"version": "", "record": "", "publish": "false"}
    messages = []
    failed = False

    if rehearse:
        record = json.loads(Path(root, REHEARSAL_RECORD).read_text(encoding="utf-8"))
        outcome.update(version=record["version"], record=REHEARSAL_RECORD)
        messages.append(f"notice::Rehearsal: packaging {record['version']}, which can never be published.")
        return outcome, messages, False

    active = []
    for path, record in load_records(root):
        problems = format_problems(path, record)
        if problems:
            failed = True
            messages += [f"error::{path.name}: {problem}" for problem in problems]
        elif record["version"] in tags:
            messages.append(f"notice::{record['version']} is already published. A release is never replaced.")
        else:
            active.append((path, record))

    wanted = [(path, record) for path, record in active if record["state"] in ("candidate", "publish")]
    for path, record in active:
        if record["state"] == "planned":
            remaining = gate_blockers(record, root, gameplay, ci_result)
            messages.append(f"notice::{record['version']} is planned, with {len(remaining)} gates open: " + "; ".join(remaining))

    if len(wanted) > 1:
        names = ", ".join(record["version"] for _, record in wanted)
        messages.append(f"error::Only one release can be prepared at a time, and these are all requested: {names}")
        return outcome, messages, True
    if not wanted or failed:
        return outcome, messages, failed

    path, record = wanted[0]
    blockers = gate_blockers(record, root, gameplay, ci_result)
    if ci_result == "success":
        outcome.update(version=record["version"], record=f"{RECORDS_DIR}/{path.name}")
    if record["state"] == "candidate":
        messages.append(f"notice::{record['version']} is a candidate. Packages are prepared, and nothing is published.")
        messages += [f"notice::Remaining for {record['version']}: {blocker}" for blocker in blockers]
    elif blockers:
        failed = True
        messages += [f"error::{record['version']} is blocked: {blocker}" for blocker in blockers]
    else:
        outcome["publish"] = "true"
        messages.append(f"notice::{record['version']} has passed every gate, and will be published from this commit.")
    return outcome, messages, failed


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def first_line_with(path, prefix):
    with open(path, encoding="utf-8", errors="replace") as log:
        for line in log:
            if line.startswith(prefix):
                return line[len(prefix) :].strip()
    return None


def build_facts(logs):
    """Read from the logs of the jobs that built and tested this commit. A missing fact stops the release."""
    facts = {}
    for name, job, what in (
        ("Windows package", "logs-windows", "MSVC"),
        ("Linux package", "logs-linux", "GCC"),
        ("Validation only, not shipped", "logs-linux-clang", "Clang"),
    ):
        path = Path(logs, job, "build-release.log")
        compiler = first_line_with(path, "dagon: compiler: ") if path.is_file() else None
        if not compiler:
            raise SystemExit(f"::error::Provenance is incomplete: no {what} compiler line in {path}")
        facts[name] = compiler
    version_file = Path(logs, "logs-linux", "godot", "godot-version.txt")
    if not version_file.is_file():
        raise SystemExit(f"::error::Provenance is incomplete: no {version_file}")
    facts["Godot"] = version_file.read_text(encoding="utf-8").strip()
    return facts


def prepare(args):
    record = json.loads(Path(args.record).read_text(encoding="utf-8"))
    version = record["version"]
    packages = sorted(path for path in Path(args.packages).iterdir() if path.is_file())
    expected = [f"dagon-{version}-linux-x86_64.tar.gz", f"dagon-{version}-windows-x86_64.zip"]
    if [path.name for path in packages] != expected:
        raise SystemExit(f"::error::Expected exactly one package per OS, {expected}, and found {[path.name for path in packages]}")

    facts = build_facts(args.logs)
    sums = {path.name: sha256_of(path) for path in packages}
    godot_cpp = subprocess.run(
        ["git", "rev-parse", f"{args.commit}:godot-cpp"], check=True, capture_output=True, text=True
    ).stdout.strip()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "SHA256SUMS.txt").write_text("".join(f"{value}  {name}\n" for name, value in sums.items()), encoding="utf-8")
    provenance = [
        f"Version: {version}",
        f"Source commit: {args.commit}",
        f"Built and tested by CI run: {args.run_url}",
        f"Gameplay fingerprint: {fingerprint('.', args.commit)}",
        *[f"{name}: {value}" for name, value in facts.items()],
        f"godot-cpp: {godot_cpp}",
        "",
        "Each package holds the exact files exported, smoke-tested and uploaded by that run. Nothing was rebuilt to package it.",
    ]
    (out / "PROVENANCE.txt").write_text("\n".join(provenance) + "\n", encoding="utf-8")

    label = label_of(version)
    acceptance = record.get("owner_acceptance", {})
    deferred = record.get("deferred", [])
    notes = [
        f"**{label} prerelease{' for ' + record['milestone'] if record.get('milestone') else ''}.** {LABEL_MEANING[label]} "
        "This is not a stable release and not a jam submission.",
        "",
        record.get("summary", "").strip(),
        "",
        "## Known limitations",
        *[f"- {item}" for item in record.get("known_limitations", [])],
        "",
    ]
    if deferred:
        notes += ["## Not tested", "These checks are deferred, and have not passed.", *[f"- {item}" for item in deferred], ""]
    gameplay = fingerprint(".", args.commit)
    if acceptance.get("status") == "accepted" and acceptance.get("gameplay_fingerprint") == gameplay:
        notes += [
            "## Owner acceptance",
            str(acceptance.get("scope", "")),
            "",
            f"- Build tested: {acceptance.get('build', '')}",
            f"- Record: `{acceptance.get('record', '')}` in this version's source",
            "- This build's gameplay fingerprint matches the one accepted, so the acceptance applies to it.",
            "",
        ]
    else:
        notes += [
            "## Owner acceptance",
            "**No owner acceptance covers this build, so it cannot be published as it stands.**",
            "",
        ]
    notes += [
        "## Downloads",
        "| Package | SHA-256 |",
        "|---|---|",
        *[f"| `{name}` | `{value}` |" for name, value in sums.items()],
        "",
        "Check them with `sha256sum -c SHA256SUMS.txt`. The Windows build is not code-signed, so SmartScreen may warn you.",
        "",
        "## Source and provenance",
        f"- Source commit: `{args.commit}`",
        f"- Built and tested by: {args.run_url}",
        *[f"- {name}: {value}" for name, value in facts.items()],
        f"- godot-cpp: `{godot_cpp}`",
    ]
    (out / "RELEASE_NOTES.md").write_text("\n".join(notes) + "\n", encoding="utf-8")
    for path in packages:
        (out / path.name).write_bytes(path.read_bytes())
    (out / "TITLE.txt").write_text(f"DAGON: Beneath the Black Tide {version}\n", encoding="utf-8")
    print(f"prepared {version} in {out}")


def write_outcome(outcome, messages):
    for message in messages:
        print(f"::{message}")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            for key, value in outcome.items():
                output.write(f"{key}={value}\n")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as summary:
            summary.write("### Release gate\n\n")
            summary.writelines(f"- **{message.split('::', 1)[0]}:** {message.split('::', 1)[1]}\n" for message in messages)
            summary.write(f"\nversion: `{outcome['version'] or 'none'}`, publish: `{outcome['publish']}`\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    evaluate_parser = commands.add_parser("evaluate")
    evaluate_parser.add_argument("--ci-result", required=True)
    evaluate_parser.add_argument("--rehearse", action="store_true")
    commands.add_parser("validate")
    fingerprint_parser = commands.add_parser("fingerprint")
    fingerprint_parser.add_argument("--commit", default="HEAD", help="the commit the owner tested")
    prepare_parser = commands.add_parser("prepare")
    for name in ("--record", "--packages", "--logs", "--out", "--commit", "--run-url"):
        prepare_parser.add_argument(name, required=True)
    args = parser.parse_args()

    if args.command == "fingerprint":
        print(fingerprint(".", args.commit))
    elif args.command == "validate":
        problems = [f"{path.name}: {problem}" for path, record in load_records() for problem in format_problems(path, record)]
        for problem in problems:
            print(f"::error::{problem}")
        print(f"release records: {len(load_records())}, problems: {len(problems)}")
        sys.exit(1 if problems else 0)
    elif args.command == "evaluate":
        outcome, messages, failed = evaluate(".", fingerprint(), args.ci_result, existing_tags(), args.rehearse)
        write_outcome(outcome, messages)
        sys.exit(1 if failed else 0)
    elif args.command == "prepare":
        prepare(args)


if __name__ == "__main__":
    main()
