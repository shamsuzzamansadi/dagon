#!/usr/bin/env python3
"""Decides whether a milestone prerelease may be published, and prepares its notes. Standard library only.

A release is requested by a record in release/, merged through a pull request. Reaching a milestone never
publishes anything. See docs/release.md.

  evaluate    What is due at this commit. Writes the outcome for the workflow, and names every blocker.
  validate    Checks that every record is well formed. Runs on every pull request.
  fingerprint Prints a commit's acceptance fingerprint, for an owner acceptance record.
  prepare     Writes the notes, checksums and provenance beside the packages.
  preflight   Inside the publication lock: says whether to create the release, and removes a failed attempt's draft.
  verify      After publishing: fails unless the release is complete and consistent, at the tested commit.

A question about tags or releases that goes unanswered stops the release. It is never read as "absent".
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

RECORDS_DIR = "release"
REHEARSAL_RECORD = "tools/release_rehearsal.json"

# What an owner's acceptance covers: the files that make up the game, and every file that decides how it is built,
# exported and packaged. Changing any of them voids the acceptance. This is deliberately conservative: a comment in a
# workflow voids it too, because nothing here tries to tell which changes matter. docs/release.md states the scope.
ACCEPTANCE_INPUTS = (
    "src",
    "project",
    "SConstruct",
    "methods.py",
    "godot-cpp",
    ".gitmodules",
    ".gitattributes",
    ".github/workflows",
    "tools/run_godot_checks.sh",
    "tools/export_check.sh",
    "tools/prepare_project.sh",
    "tools/test_storage.sh",
    "tools/package_release.py",
    "tools/install_godot.sh",
    "tools/install_export_templates.sh",
    "tools/extract_templates.py",
)
NOT_COVERED = ("project/tests/",)  # The export check fails if these reach a build.

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

# One package for each OS a release ships for, named for it. A record names its OSes in "platforms". One that names none
# is from before the Mac build (D129), and shipped Linux and Windows: that is how v0.1.0-pre-alpha.1 is still checked.
PACKAGES = {"linux": "linux-x86_64.tar.gz", "windows": "windows-x86_64.zip", "macos": "macos-arm64.zip"}
DEFAULT_PLATFORMS = ("linux", "windows")
# The runner each OS's package is made and smoke-tested on: its own OS, and for macOS, Apple Silicon.
RUNNERS = {"linux": "ubuntu-22.04", "windows": "windows-2022", "macos": "macos-15"}
# What each shipped OS's provenance reads from the logs of the job that built it.
BUILT_BY = {
    "windows": ("Windows package", "logs-windows", "MSVC"),
    "linux": ("Linux package", "logs-linux", "GCC"),
    "macos": ("macOS package", "logs-macos", "Apple Clang"),
}
# A record can ship an earlier commit on main instead of the one being tested, giving its "source": that commit and
# main's own push run that built and tested it (D128). The tag goes on that commit, and the packages are that run's own
# exports, so the release is what that commit's CI tested. These must have passed in that run, and it must still hold
# these files.
SOURCE_JOBS = ("linux", "linux-clang", "windows", "release-tools")
SOURCE_ARTIFACTS = ("dagon-linux", "dagon-windows", "logs-linux", "logs-windows", "logs-linux-clang")


def source_needs(platforms):
    """The jobs and files a source run needs for the OSes a record ships: a Mac build needs its own job and files."""
    jobs = SOURCE_JOBS + tuple(platform for platform in platforms if platform not in SOURCE_JOBS)
    artifacts = SOURCE_ARTIFACTS + tuple(f"{kind}-{platform}" for platform in platforms if platform not in DEFAULT_PLATFORMS for kind in ("dagon", "logs"))
    return jobs, artifacts
COMMIT_ID = re.compile(r"[0-9a-f]{40}")
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
    """A hash of ACCEPTANCE_INPUTS. It survives a squash merge, which changes the commit and not the files."""
    listing = subprocess.run(
        ["git", "ls-tree", "-r", commit, "--", *ACCEPTANCE_INPUTS],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    lines = [line for line in listing.splitlines() if not line.split("\t", 1)[1].startswith(NOT_COVERED)]
    return "sha256:" + hashlib.sha256("\n".join(sorted(lines)).encode()).hexdigest()


class StateUnknown(Exception):
    """A question about tags or releases went unanswered. It must never be read as "absent"."""


def remote_tags(root="."):
    """{tag: the commit it points at}. A failure raises, because an empty answer would mean no tags exist."""
    result = subprocess.run(["git", "ls-remote", "--tags", "origin"], cwd=root, capture_output=True, text=True)
    if result.returncode != 0:
        raise StateUnknown(f"could not list the remote tags: git ls-remote exited with {result.returncode}")
    tags = {}
    for line in result.stdout.splitlines():
        commit, reference = line.split("\t", 1)
        # An annotated tag has a second line, straight after its first, ending ^{}. It gives the commit itself.
        tags[reference.removeprefix("refs/tags/").removesuffix("^{}")] = commit
    return tags


class GitHub:
    """Reads releases through the API. Only a 404 for something in a repository we can see means "absent"."""

    def __init__(self, api=None, repository=None, token=None):
        self.api = (api or os.environ.get("GITHUB_API_URL") or "https://api.github.com").rstrip("/")
        self.repository = repository or os.environ.get("GITHUB_REPOSITORY")
        self.token = token if token is not None else os.environ.get("GH_TOKEN")
        self.confirmed = False

    def _request(self, path, method="GET"):
        if not self.repository or not self.token:
            raise StateUnknown("GITHUB_REPOSITORY and GH_TOKEN are needed to ask GitHub about releases")
        return urllib.request.Request(
            f"{self.api}/repos/{self.repository}{path}",
            method=method,
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {self.token}",
                "User-Agent": "dagon-release-gate",
                "X-GitHub-Api-Version": "2022-11-28",
            },
        )

    def _send(self, path, method="GET"):
        try:
            with urllib.request.urlopen(self._request(path, method), timeout=30) as response:
                body = response.read()
            return json.loads(body) if body else {}
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            raise StateUnknown(f"GitHub answered {error.code} for {method} {path or '/'}") from None
        except (OSError, ValueError) as error:
            raise StateUnknown(f"no usable answer from GitHub for {method} {path or '/'}: {type(error).__name__}") from None

    def get(self, path):
        # A token that cannot see a private repository gets a 404 for everything in it. Seeing the repository first
        # is what makes a later 404 mean "absent", and not "not allowed".
        if not self.confirmed:
            if self._send("") is None:
                raise StateUnknown(f"GitHub says the repository {self.repository} does not exist for this token")
            self.confirmed = True
        return self._send(path)

    def published_release(self, version):
        """The published release for this tag, or None. GitHub never returns a draft from this endpoint."""
        return self.get(f"/releases/tags/{urllib.parse.quote(version, safe='')}")

    def all_releases(self):
        """Every release this token can see. Drafts are visible only with write access."""
        found = []
        for page in range(1, 1000):
            batch = self.get(f"/releases?per_page=100&page={page}")
            if batch is None:
                raise StateUnknown("GitHub answered 404 for the list of releases")
            found += batch
            if len(batch) < 100:
                return found
        raise StateUnknown("the list of releases did not end")

    def run(self, run_id):
        """A workflow run, or None if this repository has no such run."""
        return self.get(f"/actions/runs/{int(run_id)}")

    def _all(self, path, key):
        found = []
        for page in range(1, 1000):
            batch = self.get(f"{path}?per_page=100&page={page}")
            if batch is None:
                raise StateUnknown(f"GitHub answered 404 for {path}")
            found += batch.get(key, [])
            if len(batch.get(key, [])) < 100:
                return found
        raise StateUnknown(f"the list at {path} did not end")

    def run_jobs(self, run_id):
        return self._all(f"/actions/runs/{int(run_id)}/jobs", "jobs")

    def run_artifacts(self, run_id):
        return self._all(f"/actions/runs/{int(run_id)}/artifacts", "artifacts")

    def delete_draft(self, release_id):
        """Removes an unpublished draft. It looks again first, and refuses anything else."""
        release = self.get(f"/releases/{int(release_id)}")
        if release is None or release.get("draft") is not True:
            raise StateUnknown(f"release {release_id} is not an unpublished draft, so it was left alone")
        if self._send(f"/releases/{int(release_id)}", method="DELETE") is None:
            raise StateUnknown(f"draft {release_id} had gone by the time it was removed")


def platforms_of(record):
    return tuple(record.get("platforms") or DEFAULT_PLATFORMS)


def package_matrix(platforms):
    """The package jobs a release needs, one per OS on its own runner, as the workflow's matrix reads them."""
    return json.dumps([{"platform": platform, "os": RUNNERS[platform]} for platform in platforms], separators=(",", ":"))


def package_names(version, platforms=DEFAULT_PLATFORMS):
    return sorted(f"dagon-{version}-{PACKAGES[platform]}" for platform in platforms)


def expected_assets(version, platforms=DEFAULT_PLATFORMS):
    return set(package_names(version, platforms)) | {"SHA256SUMS.txt", "PROVENANCE.txt"}


def platforms_for(version, root="."):
    """The OSes the record for this version names, the rehearsal's included. A version with no record shipped the
    default two, as only records made before the Mac build lack the field."""
    for path in [*sorted(Path(root, RECORDS_DIR).glob("*.json")), Path(root, REHEARSAL_RECORD)]:
        if path.is_file():
            record = json.loads(path.read_text(encoding="utf-8"))
            if record.get("version") == version:
                return platforms_of(record)
    return DEFAULT_PLATFORMS


def publication_problems(version, tag_commit, release, platforms=DEFAULT_PLATFORMS):
    """Why what exists for this version is not a complete, consistent release. Nothing here looks at HEAD: a release
    stays correct when main moves on, so the tag is checked against the target the release itself recorded."""
    if release is None:
        return [f"the tag exists at {tag_commit}, with no published release. This workflow never moves or deletes a tag: resolve it by hand, or use a new version"]
    problems = []
    if release.get("draft") is not False:
        problems.append("the release is not published")
    if release.get("tag_name") != version:
        problems.append(f"the release is named for the tag '{release.get('tag_name')}'")
    if release.get("prerelease") is not True:
        problems.append("the release is not marked as a prerelease")
    target = str(release.get("target_commitish", ""))
    if tag_commit is None:
        problems.append(f"the release has no tag, and recorded the target {target or 'none'}")
    elif not re.fullmatch(r"[0-9a-f]{40}", target):
        problems.append(f"the release recorded the target '{target}', which is not a commit, so the tag at {tag_commit} cannot be checked against it")
    elif target != tag_commit:
        problems.append(f"the tag points at {tag_commit}, and the release recorded the target {target}")
    uploaded = {asset.get("name") for asset in release.get("assets", []) if asset.get("state") == "uploaded"}
    missing = sorted(expected_assets(version, platforms) - uploaded)
    if missing:
        problems.append("the release is missing: " + ", ".join(missing))
    return problems


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
    if "platforms" in record:
        platforms = record["platforms"]
        if not isinstance(platforms, list) or not platforms or len(set(platforms)) != len(platforms) or not set(platforms) <= set(PACKAGES):
            problems.append(f"platforms must list each of {', '.join(PACKAGES)} at most once, and at least one: {platforms}")
    return problems + source_format_problems(record)


def source_format_problems(record):
    if "source" not in record:
        return []
    source = record["source"]
    run_id = source.get("run") if isinstance(source, dict) else None
    if not isinstance(source, dict) or not COMMIT_ID.fullmatch(str(source.get("commit", ""))) or type(run_id) is not int or run_id <= 0:
        return ["source must give the full commit, and the id of main's push run that built and tested it"]
    return []


def source_problems(source, root, github, platforms=DEFAULT_PLATFORMS):
    """Why an earlier commit cannot be shipped from main's own CI run of it. Raises StateUnknown if it cannot tell."""
    commit, run_id = source["commit"], source["run"]
    needed_jobs, needed_artifacts = source_needs(platforms)
    problems = []
    ancestry = subprocess.run(["git", "merge-base", "--is-ancestor", commit, "HEAD"], cwd=root, capture_output=True, text=True)
    if ancestry.returncode == 1:
        problems.append(f"the source commit {commit} is not in this commit's history, so it is not on main")
    elif ancestry.returncode != 0:
        raise StateUnknown(f"could not tell whether {commit} is in this commit's history: {ancestry.stderr.strip()}")
    run = github.run(run_id)
    if run is None:
        return problems + [f"CI run {run_id} does not exist"]
    if run.get("head_sha") != commit:
        problems.append(f"CI run {run_id} tested {run.get('head_sha')}, not the source commit {commit}")
    if run.get("event") != "push" or run.get("head_branch") != "main":
        problems.append(f"CI run {run_id} is a {run.get('event')} run of {run.get('head_branch')}, not main's own push run")
    if run.get("status") != "completed" or run.get("conclusion") != "success":
        problems.append(f"CI run {run_id} did not succeed: {run.get('status')}, {run.get('conclusion')}")
    jobs = {job.get("name"): job.get("conclusion") for job in github.run_jobs(run_id)}
    for name in needed_jobs:
        if jobs.get(name) != "success":
            problems.append(f"{name} did not succeed in CI run {run_id}: {jobs.get(name, 'missing')}")
    artifacts = {artifact.get("name"): artifact for artifact in github.run_artifacts(run_id)}
    for name in needed_artifacts:
        if name not in artifacts or artifacts[name].get("expired") is not False:
            problems.append(f"CI run {run_id} no longer holds {name}")
    return problems


def gate_blockers(record, root, current, ci_result):
    """Everything standing between this record and publication. An empty list means it may be published."""
    blockers = []
    if ci_result != "success":
        blockers.append(f"CI on this commit did not succeed on GCC, Clang, MSVC and Apple Clang: {ci_result}")

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
        accepted = acceptance.get("fingerprint", "")
        if accepted != current:
            shipped = "the source commit" if record.get("source") else "this commit"
            blockers.append(
                f"the game, or how it is built, exported or packaged, has changed since the owner accepted it, so that "
                f"acceptance does not cover this build: accepted {accepted or 'nothing'}, {shipped} {current}"
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


def evaluate(root, current, ci_result, tags, find_release, rehearse=False, check_source=None):
    """Returns (outcome, messages, failed). Outcome is what the workflow needs: version, record, publish, and for a
    record with a source, the commit to ship and tag (target) and the run whose exports to package (source_run).
    tags is {tag: commit}. find_release(version) gives the published release or None, and raises StateUnknown.
    check_source(source) gives a source's problems, and raises StateUnknown."""
    outcome = {"version": "", "record": "", "publish": "false", "target": "", "source_run": "", "matrix": package_matrix(DEFAULT_PLATFORMS)}
    if check_source is None:

        def check_source(source, platforms):
            raise StateUnknown("a record ships an earlier commit, and nothing was given to check its CI run")

    def blockers_for(record):
        # A record that ships an earlier commit is judged on that commit: its files, and its own CI run.
        source = record.get("source")
        if not source:
            return gate_blockers(record, root, current, ci_result)
        return gate_blockers(record, root, fingerprint(root, source["commit"]), ci_result) + check_source(source, platforms_of(record))

    def ship(record):
        outcome["matrix"] = package_matrix(platforms_of(record))
        if record.get("source"):
            outcome.update(target=record["source"]["commit"], source_run=str(record["source"]["run"]))
    messages = []
    failed = False

    active = []
    for path, record in load_records(root):
        problems = format_problems(path, record)
        if problems:
            failed = True
            messages += [f"error::{path.name}: {problem}" for problem in problems]
            continue
        version = record["version"]
        release = find_release(version)
        if version not in tags and release is None:
            active.append((path, record))
            continue
        problems = publication_problems(version, tags.get(version), release, platforms_of(record))
        if problems:
            failed = True
            messages += [f"error::{version} is not a complete release: {problem}" for problem in problems]
        else:
            messages.append(f"notice::{version} is already published, at {release['target_commitish']}. A release is never replaced.")

    wanted = [(path, record) for path, record in active if record["state"] in ("candidate", "publish")]
    for path, record in active:
        if record["state"] == "planned":
            remaining = blockers_for(record)
            messages.append(f"notice::{record['version']} is planned, with {len(remaining)} gates open: " + "; ".join(remaining))

    if rehearse:
        if not failed:
            record = json.loads(Path(root, REHEARSAL_RECORD).read_text(encoding="utf-8"))
            problems = source_format_problems(record)
            if not problems and record.get("source"):
                problems += check_source(record["source"], platforms_of(record))
            if problems:
                return outcome, messages + [f"error::The rehearsal record: {problem}" for problem in problems], True
            outcome.update(version=record["version"], record=REHEARSAL_RECORD)
            ship(record)
            shipped = f", from {record['source']['commit']} as built by CI run {record['source']['run']}" if record.get("source") else ""
            messages.append(f"notice::Rehearsal: packaging {record['version']}{shipped}, which can never be published.")
        return outcome, messages, failed
    if len(wanted) > 1:
        names = ", ".join(record["version"] for _, record in wanted)
        messages.append(f"error::Only one release can be prepared at a time, and these are all requested: {names}")
        return outcome, messages, True
    if not wanted or failed:
        return outcome, messages, failed

    path, record = wanted[0]
    blockers = blockers_for(record)
    if ci_result == "success":
        outcome.update(version=record["version"], record=f"{RECORDS_DIR}/{path.name}")
        ship(record)
    if record["state"] == "candidate":
        messages.append(f"notice::{record['version']} is a candidate. Packages are prepared, and nothing is published.")
        messages += [f"notice::Remaining for {record['version']}: {blocker}" for blocker in blockers]
    elif blockers:
        failed = True
        messages += [f"error::{record['version']} is blocked: {blocker}" for blocker in blockers]
    else:
        outcome["publish"] = "true"
        source = record.get("source")
        where = f"from {source['commit']}, as built by CI run {source['run']}, and tagged there" if source else "from this commit"
        messages.append(f"notice::{record['version']} has passed every gate, and will be published {where}.")
    return outcome, messages, failed


def preflight(version, tags, releases, delete_draft, report, platforms=DEFAULT_PLATFORMS):
    """Inside the publication lock. Returns "create" or "skip", and raises StateUnknown if anything is wrong.
    A draft is removed only when nothing was published and no tag exists, so a failed attempt is all it can be."""
    matching = [release for release in releases if release.get("tag_name") == version]
    published = [release for release in matching if release.get("draft") is False]
    drafts = [release for release in matching if release.get("draft") is True]
    if len(published) + len(drafts) != len(matching):
        raise StateUnknown(f"{version}: a release does not say whether it is a draft")
    tag = tags.get(version)

    if tag is None and not published:
        for draft in drafts:
            report(f"notice::Removing draft {draft['id']} of {version}, left by a failed attempt. It was never published, and has no tag.")
            delete_draft(draft["id"])
        return "create"
    if len(published) > 1:
        raise StateUnknown(f"{version}: {len(published)} published releases claim this version")
    problems = publication_problems(version, tag, published[0] if published else None, platforms)
    if drafts:
        problems.append(f"{len(drafts)} unpublished draft(s) also claim this version, and were left alone")
    if problems:
        raise StateUnknown(f"{version} is not a complete release: " + "; ".join(problems))
    report(f"notice::{version} is already published, at {published[0]['target_commitish']}. A release is never replaced.")
    return "skip"


def verify(version, commit, tags, release, platforms=DEFAULT_PLATFORMS):
    """After publishing. Unlike the later checks, this one does compare with the commit just tested."""
    problems = publication_problems(version, tags.get(version), release, platforms) if (release or tags.get(version)) else ["neither a tag nor a published release exists"]
    if tags.get(version) != commit:
        problems.append(f"the tag points at {tags.get(version) or 'nothing'}, not the tested commit {commit}")
    return problems


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


def build_facts(logs, platforms=DEFAULT_PLATFORMS):
    """Read from the logs of the jobs that built and tested this commit. A missing fact stops the release."""
    facts = {}
    for name, job, what in (
        *[BUILT_BY[platform] for platform in ("windows", "linux", "macos") if platform in platforms],
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
    if "macos" in platforms:
        facts.update(macos_facts(Path(logs, "logs-macos", "macos-facts.txt")))
    return facts


# What the release says about the Mac build: read from the app CI built (tools/macos_facts.sh), never assumed.
MACOS_FACTS = (
    "Architectures, game",
    "Minimum macOS, Info.plist",
    "Minimum macOS, game executable",
    "Minimum macOS, extension",
    "Built on",
    "Xcode",
    "Signature",
    "Signature check",
    "Gatekeeper",
    "Notarization",
)


def macos_facts(path):
    found = {}
    if path.is_file():
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("MACOS_FACT ") and ": " in line:
                name, value = line.removeprefix("MACOS_FACT ").split(": ", 1)
                found[name] = value.strip()
    missing = [name for name in MACOS_FACTS if not found.get(name)]
    if missing:
        raise SystemExit(f"::error::Provenance is incomplete: {path} does not state {', '.join(missing)}")
    return {f"macOS, {name.lower()}" if not name.startswith("Minimum") else name: found[name] for name in MACOS_FACTS}


def smoke_facts(folder):
    """Where each package's own smoke test ran: the system each was actually tested on."""
    found = {}
    for path in sorted(Path(folder).glob("smoke-*.txt")) if folder and Path(folder).is_dir() else []:
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("SMOKE_FACT ") and ": " in line:
                name, value = line.removeprefix("SMOKE_FACT ").split(": ", 1)
                found[name] = value.strip()
    return found


def prepare(args):
    record = json.loads(Path(args.record).read_text(encoding="utf-8"))
    version = record["version"]
    packages = sorted(path for path in Path(args.packages).iterdir() if path.is_file())
    platforms = platforms_of(record)
    expected = package_names(version, platforms)
    if [path.name for path in packages] != expected:
        raise SystemExit(f"::error::Expected exactly one package per OS, {expected}, and found {[path.name for path in packages]}")

    facts = build_facts(args.logs, platforms)
    tested = smoke_facts(getattr(args, "smoke", None))
    if "macos" in platforms and not tested.get("macOS package smoke-tested on"):
        raise SystemExit("::error::Provenance is incomplete: no record of the macOS version the Mac package was smoke-tested on")
    sums = {path.name: sha256_of(path) for path in packages}
    godot_cpp = subprocess.run(
        ["git", "rev-parse", f"{args.commit}:godot-cpp"], check=True, capture_output=True, text=True
    ).stdout.strip()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "SHA256SUMS.txt").write_text("".join(f"{value}  {name}\n" for name, value in sums.items()), encoding="utf-8")
    # Three separate facts (D132): the game's commit, the run that built and tested it, and the run preparing this,
    # which is that same run unless the record ships an earlier commit. Nothing here can know of a publication.
    prepared_by = getattr(args, "packaged_by", None) or f"{args.run_url} at {args.commit}"
    provenance = [
        f"Version: {version}",
        f"Game source commit: {args.commit}",
        f"Source build run, which built and tested that commit: {args.run_url}",
        f"Packaged, smoke-tested and prepared by CI run: {prepared_by}",
        f"Acceptance fingerprint: {fingerprint('.', args.commit)}",
        *[f"{name}: {value}" for name, value in facts.items()],
        f"godot-cpp: {godot_cpp}",
        *[f"{name}: {value}" for name, value in tested.items()],
        "",
        "Each package holds the exact files the source build run exported and tested. The preparing run packaged them, "
        "smoke-tested each on its own system and wrote these checksums; nothing was rebuilt.",
        "This file records no publication. The run that publishes a release is named in its notes, and only once GitHub "
        "reports the release published.",
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
    if acceptance.get("status") == "accepted" and acceptance.get("fingerprint") == fingerprint(".", args.commit):
        notes += [
            "## Owner acceptance",
            str(acceptance.get("scope", "")),
            "",
            f"- Build tested: {acceptance.get('build', '')}",
            f"- Record: `{acceptance.get('record', '')}` in this version's source",
            "- This build's fingerprint matches the one accepted, so the acceptance applies to it.",
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
        *(
            [
                f"**macOS, Apple Silicon only (M1 and later, Pro, Max and Ultra included).** Needs macOS "
                f"{facts['Minimum macOS, game executable']} or later; tested on {tested['macOS package smoke-tested on']}. "
                f"It is signed ad hoc, with no Apple developer identity, and is not notarized "
                f"({facts['macOS, notarization']}), so macOS blocks the first launch: see the README's first-launch "
                "steps. There is no Intel Mac build.",
                "",
            ]
            if "macos" in platforms
            else []
        ),
        "## Source and provenance",
        f"- Game source commit: `{args.commit}`",
        f"- Source build run, which built and tested that commit: {args.run_url}",
        f"- Packaged, smoke-tested and prepared by CI run: {prepared_by}",
        *[f"- {name}: {value}" for name, value in facts.items()],
        f"- godot-cpp: `{godot_cpp}`",
        *[f"- {name}: {value}" for name, value in tested.items()],
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
    prepare_parser.add_argument("--smoke", help="the folder of the packages' smoke-test records (smoke-<os>.txt)")
    prepare_parser.add_argument("--packaged-by", help="for a record with a source: the run that packaged it, and its commit")
    preflight_parser = commands.add_parser("preflight")
    preflight_parser.add_argument("--version", required=True)
    verify_parser = commands.add_parser("verify")
    verify_parser.add_argument("--version", required=True)
    verify_parser.add_argument("--commit", required=True)
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
        github = GitHub()
        try:
            outcome, messages, failed = evaluate(".", fingerprint(), args.ci_result, remote_tags(), github.published_release, args.rehearse, lambda source, platforms: source_problems(source, ".", github, platforms))
        except StateUnknown as error:
            outcome = {"version": "", "record": "", "publish": "false", "target": "", "source_run": "", "matrix": package_matrix(DEFAULT_PLATFORMS)}
            messages, failed = [f"error::The release state could not be determined, so nothing was prepared or published: {error}"], True
        write_outcome(outcome, messages)
        sys.exit(1 if failed else 0)
    elif args.command == "prepare":
        prepare(args)
    elif args.command == "preflight":
        github = GitHub()
        try:
            # Reports go to the log. The decision on stdout is all the publisher reads.
            print(preflight(args.version, remote_tags(), github.all_releases(), github.delete_draft, lambda line: print(f"::{line}", file=sys.stderr), platforms_for(args.version)))
        except StateUnknown as error:
            print(f"::error::{args.version} was not published: {error}", file=sys.stderr)
            sys.exit(1)
    elif args.command == "verify":
        github = GitHub()
        try:
            problems = verify(args.version, args.commit, remote_tags(), github.published_release(args.version), platforms_for(args.version))
        except StateUnknown as error:
            problems = [str(error)]
        for problem in problems:
            print(f"::error::{args.version} was published, and needs checking by hand: {problem}")
        if problems:
            sys.exit(1)
        print(f"verified {args.version}: complete, consistent and at {args.commit}")


if __name__ == "__main__":
    main()
