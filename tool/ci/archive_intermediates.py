"""Archive allowlisted CI outputs without following links or collecting SDK caches."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import tarfile


GENERATED_ROOTS = (
    "native/build", ".dart_tool/flutter_build",
    "build/app/intermediates", "build/linux/x64/CMakeFiles",
    "build/windows/x64/CMakeFiles",
    "build/macos/Build/Intermediates.noindex",
    "build/ios/Build/Intermediates.noindex",
    "android/app/.cxx", "ohos/build", "ohos/entry/build",
)
EXCLUDED_PARTS = {
    ".git", ".cache", "cache", "caches", ".pub-cache", ".gradle",
    ".ohpm", ".hvigor", "node_modules", "oh_modules", "__pycache__",
    "signing", "secrets", "credentials", "_codesignature",
}
EXCLUDED_NAMES = {
    "key.properties", "local.properties", "gradle.properties",
    "build-profile.json5", "exportoptions.plist", "id_rsa", "id_ed25519",
}
EXCLUDED_SUFFIXES = {
    ".jks", ".keystore", ".p12", ".pfx", ".pem", ".key", ".cer", ".csr",
    ".p7b", ".mobileprovision", ".provisionprofile",
}


def excluded(relative):
    parts = [part.casefold() for part in relative.parts]
    return (
        any(part in EXCLUDED_PARTS for part in parts)
        or any(part == ".env" or part.startswith(".env.") for part in parts)
        or relative.name.casefold() in EXCLUDED_NAMES
        or relative.suffix.casefold() in EXCLUDED_SUFFIXES
        or any(re.search(r"(^|[._-])(secret|secrets|credential|credentials|keystore|signing)([._-]|$)", part)
               for part in parts)
    )


def collect(root):
    """Select real generated roots once; never traverse a directory symlink."""
    members = {}
    roots = []
    skipped = 0

    def visit(path):
        nonlocal skipped
        relative = path.relative_to(root)
        if excluded(relative):
            skipped += 1
            return
        mode = path.lstat().st_mode
        if not (stat.S_ISREG(mode) or stat.S_ISDIR(mode) or stat.S_ISLNK(mode)):
            skipped += 1
            return
        members[relative.as_posix()] = path
        if stat.S_ISDIR(mode):
            for child in sorted(path.iterdir()):
                visit(child)

    for name in GENERATED_ROOTS:
        path = root / name
        # A symlinked root/ancestor could reach a sibling SDK or a signing tree.
        if any(parent.is_symlink() for parent in (path, *path.parents) if parent != root):
            skipped += 1
            continue
        if not path.is_dir():
            continue
        relative = path.relative_to(root)
        if any(relative.is_relative_to(previous) for previous in roots):
            continue
        roots.append(relative)
        visit(path)

    for name, path in list(members.items()):
        if not path.is_symlink():
            continue
        try:
            target = os.readlink(path)
            resolved = path.resolve(strict=True).relative_to(root).as_posix()
            safe = not os.path.isabs(target) and resolved in members
        except (OSError, RuntimeError, ValueError):
            safe = False
        if not safe:
            del members[name]
            skipped += 1
    return roots, members, skipped


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def archive_outputs(root, output, name, job_status="unknown"):
    root = Path(root).resolve()
    output = Path(output).resolve()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name):
        raise ValueError("Archive name must be a plain artifact name")
    for relative in GENERATED_ROOTS:
        if output.is_relative_to(root / relative):
            raise ValueError("Archive output must be outside generated input directories")
    roots, members, skipped = collect(root)
    if not members:
        print("No allowlisted intermediate outputs exist; nothing to upload.")
        return None
    output.mkdir(parents=True, exist_ok=True)
    target = output / f"{name}.tar.gz"
    source_bytes = 0
    with tarfile.open(target, "w:gz", compresslevel=1, dereference=False) as package:
        for member, path in sorted(members.items()):
            info = package.gettarinfo(str(path), arcname=member)
            info.uid = info.gid = 0
            info.uname = info.gname = ""
            if info.isfile():
                source_bytes += info.size
                with path.open("rb") as stream:
                    package.addfile(info, stream)
            else:
                package.addfile(info)
    record = {
        "schemaVersion": 1,
        "repository": os.environ.get("GITHUB_REPOSITORY"),
        "commit": os.environ.get("GITHUB_SHA"),
        "runId": os.environ.get("GITHUB_RUN_ID"),
        "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
        "job": os.environ.get("GITHUB_JOB"),
        "jobStatusBeforeArchiving": job_status,
        "name": name,
        "allowlistedRoots": list(GENERATED_ROOTS),
        "includedRoots": [path.as_posix() for path in roots],
        "members": len(members),
        "excludedEntries": skipped,
        "uncompressedFileBytes": source_bytes,
        "archiveBytes": target.stat().st_size,
        "sha256": sha256(target),
        "retentionDays": 3,
        "scope": "Generated intermediates only; not a release or runtime validation.",
        "deviceRuntimeVerified": False,
    }
    provenance = output / "provenance.json"
    provenance.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    (output / "SHA256SUMS").write_text(
        "".join(f"{sha256(path)}  {path.name}\n" for path in (target, provenance)),
        encoding="utf-8",
    )
    summary = (
        f"### Intermediate archive: {name}\n\n"
        f"{record['archiveBytes']:,} compressed bytes; {source_bytes:,} source bytes; "
        f"{len(members)} entries. Retention: 3 days.\n\n"
        f"Roots: {', '.join(record['includedRoots'])}. "
        f"Excluded entries: {skipped}. Build status before archiving: {job_status}.\n\n"
        "SDK caches, signing material and links outside the selected payload are excluded. "
        "Extract the inner tar.gz to preserve modes and links. This is not device evidence.\n\n"
    )
    print(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a", encoding="utf-8") as stream:
            stream.write(summary)
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--job-status", default="unknown")
    arguments = parser.parse_args()
    record = archive_outputs(arguments.root, arguments.output, arguments.name, arguments.job_status)
    if os.environ.get("GITHUB_OUTPUT"):
        with Path(os.environ["GITHUB_OUTPUT"]).open("a", encoding="utf-8") as stream:
            stream.write(f"created={'true' if record else 'false'}\n")


if __name__ == "__main__":
    main()
