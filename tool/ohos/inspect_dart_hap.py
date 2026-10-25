"""Inspect an actual Dart HAP: product identity, ABI/ELF, permissions, exact
curriculum assets, provenance fingerprints and artifact immutability.

This tool never signs, installs or starts anything, and never writes outside the
report path. It reports `ok: false` plus every failure it found instead of
stopping at the first one, so a rejected package still leaves evidence.

Exit code is 0 only when every check passed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import zipfile

ELF_MACHINE = {"x86_64": 62, "arm64-v8a": 183}

# Offline product: these must never appear in a packaged manifest.
FORBIDDEN_PERMISSIONS = {
    "ohos.permission.INTERNET",
    "ohos.permission.GET_NETWORK_INFO",
    "ohos.permission.SET_NETWORK_INFO",
    "ohos.permission.LOCATION",
    "ohos.permission.APPROXIMATELY_LOCATION",
    "ohos.permission.CAMERA",
    "ohos.permission.MICROPHONE",
    "ohos.permission.READ_CONTACTS",
    "ohos.permission.READ_CALL_LOG",
    "ohos.permission.READ_MESSAGES",
    "ohos.permission.READ_MEDIA",
    "ohos.permission.WRITE_MEDIA",
    "ohos.permission.MANAGE_DISTRIBUTED_ACCOUNTS",
}

CONTENT_KINDS = ("tutorials", "examples")

# Product-identity configs this report was checked against. Pinning their bytes
# makes the identity claims self-contained: a later config edit cannot silently
# reuse an older report.
IDENTITY_SOURCES = (
    "ohos/AppScope/app.json5",
    "ohos/entry/src/main/module.json5",
    "pubspec.yaml",
)


def load_json5(path: Path) -> dict:
    """Parse the DevEco json5 configs strictly enough for our assertions."""
    text = Path(path).read_text(encoding="utf-8")
    out = []
    index = 0
    limit = len(text)
    quote = None
    while index < limit:
        char = text[index]
        if quote is not None:
            if char == "\\" and index + 1 < limit:
                out.append(text[index:index + 2])
                index += 2
                continue
            if char == quote:
                out.append('"')
                quote = None
            else:
                out.append(char)
            index += 1
            continue
        if char in ('"', "'"):
            quote = char
            out.append('"')
            index += 1
            continue
        if char == "/" and index + 1 < limit and text[index + 1] == "/":
            while index < limit and text[index] != "\n":
                index += 1
            continue
        if char == "/" and index + 1 < limit and text[index + 1] == "*":
            index += 2
            while index + 1 < limit and not (text[index] == "*" and text[index + 1] == "/"):
                index += 1
            index += 2
            continue
        out.append(char)
        index += 1
    stripped = re.sub(r",(\s*[}\]])", r"\1", "".join(out))
    return json.loads(stripped)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def product_identity(project: Path) -> dict:
    """Everything the packaged HAP must agree with, read from this product."""
    app_scope = load_json5(project / "ohos/AppScope/app.json5")["app"]
    module_config = load_json5(project / "ohos/entry/src/main/module.json5")["module"]
    pubspec_text = (project / "pubspec.yaml").read_text(encoding="utf-8")
    version_line = re.search(r"^version:\s*(\S+)\s*$", pubspec_text, re.MULTILINE)
    version_name, _, build_number = version_line.group(1).partition("+")
    return {
        "bundleName": app_scope["bundleName"],
        "vendor": app_scope.get("vendor", ""),
        "appScopeVersionCode": app_scope.get("versionCode"),
        "versionName": version_name,
        "buildNumber": int(build_number) if build_number.isdigit() else None,
        "moduleName": module_config.get("name"),
        "mainElement": module_config.get("mainElement"),
        "deviceTypes": sorted(module_config.get("deviceTypes", [])),
        "permissions": sorted(
            item["name"]
            for item in module_config.get("requestPermissions", [])
            if item.get("name")
        ),
    }


def identity_fingerprints(project: Path) -> dict:
    """SHA-256 of every config that defines the product identity."""
    return {
        relative: sha256_file(project / relative)
        for relative in IDENTITY_SOURCES
    }


def source_assets(project: Path) -> dict:
    """Authored build assets: the only authoritative denominator."""
    result = {}
    for kind in CONTENT_KINDS:
        path = project / f"assets/content/dart_{kind}.json"
        payload = path.read_bytes()
        document = json.loads(payload)
        entries = document["entries"]
        result[kind] = {
            "path": path.relative_to(project).as_posix(),
            "bytes": len(payload),
            "sha256": sha256_bytes(payload),
            "topics": len(entries),
            "schemaVersion": document.get("schemaVersion"),
            "kind": document.get("kind"),
            "ids": [entry.get("id") for entry in entries],
            "entries": entries,
        }
    return result


def _check_elf(archive: zipfile.ZipFile, name: str, machine: int) -> str | None:
    with archive.open(name) as handle:
        header = handle.read(64)
    if len(header) < 64 or header[:4] != b"\x7fELF":
        return f"Not an ELF file: {name}"
    elf_class, elf_data, elf_version = header[4], header[5], header[6]
    if (elf_class, elf_data, elf_version) != (2, 1, 1):
        return f"Not a 64-bit little-endian ELF: {name}"
    elf_type = struct.unpack_from("<H", header, 16)[0]
    if elf_type not in (2, 3):
        return f"ELF is neither executable nor shared object: {name}"
    found = struct.unpack_from("<H", header, 18)[0]
    if found != machine:
        return f"Wrong ELF architecture in {name}: e_machine={found}, expected {machine}"
    return None


def inspect_hap(hap: Path, project: Path, abi: str, topics=None,
                expect_sha256: str | None = None,
                require_release: bool = True) -> dict:
    failures: list[str] = []
    notes: list[str] = []
    machine = ELF_MACHINE[abi]
    hap = Path(hap).resolve()
    project = Path(project).resolve()

    if not hap.is_file():
        raise FileNotFoundError(f"Audit HAP does not exist: {hap}")
    raw = hap.read_bytes()
    digest = sha256_bytes(raw)
    size = hap.stat().st_size

    expected_topics = topics if isinstance(topics, int) else None

    identity = product_identity(project)
    identity_sources = identity_fingerprints(project)
    sources = source_assets(project)

    if expected_topics is not None:
        disagreeing = [kind for kind, asset in sources.items() if asset["topics"] != expected_topics]
        if disagreeing:
            failures.append(
                "Authored asset denominator differs from the requested count: "
                + ", ".join(f"{kind}={sources[kind]['topics']}" for kind in disagreeing)
                + f" (requested {expected_topics})")

    libraries: list[str] = []
    assets: list[dict] = []
    manifest: dict = {}
    permissions: list[dict] = []

    with zipfile.ZipFile(hap) as archive:
        names = archive.namelist()

        # --- ABI / native payload -------------------------------------------
        shared_objects = [name for name in names if name.lower().endswith(".so")]
        libraries = [name for name in shared_objects if name.startswith("libs/")]
        stray = [name for name in shared_objects if not name.startswith("libs/")]
        if stray:
            failures.append(f"Native library outside libs/: {stray}")
        required = {f"libs/{abi}/libapp.so", f"libs/{abi}/libflutter.so"}
        missing = required.difference(libraries)
        if missing:
            failures.append(f"Missing required native library: {sorted(missing)}")
        for name in libraries:
            if not name.startswith(f"libs/{abi}/"):
                failures.append(f"Unexpected ABI payload: {name}")
                continue
            problem = _check_elf(archive, name, machine)
            if problem:
                failures.append(problem)
        abi_directories = sorted({name.split("/")[1] for name in libraries if name.count("/") > 1})
        if abi_directories and abi_directories != [abi]:
            failures.append(f"Package advertises multiple ABIs: {abi_directories}")

        # --- packaged manifest ---------------------------------------------
        if "module.json" not in names:
            failures.append("HAP has no module.json")
        else:
            manifest = json.loads(archive.read("module.json"))
            app = manifest.get("app", {})
            module = manifest.get("module", {})
            if app.get("bundleName") != identity["bundleName"]:
                failures.append(
                    f"Packaged bundle {app.get('bundleName')!r} differs from "
                    f"{identity['bundleName']!r}")
            if app.get("versionName") != identity["versionName"]:
                failures.append(
                    f"Packaged versionName {app.get('versionName')!r} differs from pubspec "
                    f"{identity['versionName']!r}")
            if identity["buildNumber"] is not None and app.get("versionCode") != identity["buildNumber"]:
                failures.append(
                    f"Packaged versionCode {app.get('versionCode')!r} differs from pubspec build "
                    f"number {identity['buildNumber']!r}")
            if identity["vendor"] and app.get("vendor") != identity["vendor"]:
                failures.append(
                    f"Packaged vendor {app.get('vendor')!r} differs from "
                    f"{identity['vendor']!r}")
            if module.get("name") != identity["moduleName"]:
                failures.append(
                    f"Packaged module {module.get('name')!r} differs from "
                    f"{identity['moduleName']!r}")
            if module.get("mainElement") != identity["mainElement"]:
                failures.append(
                    f"Packaged mainElement {module.get('mainElement')!r} differs from "
                    f"{identity['mainElement']!r}")
            packaged_devices = sorted(module.get("deviceTypes", []))
            if packaged_devices != identity["deviceTypes"]:
                failures.append(
                    f"Packaged deviceTypes {packaged_devices} differ from "
                    f"{identity['deviceTypes']}")
            if require_release:
                if app.get("debug") is not False:
                    failures.append(f"Packaged app.debug is {app.get('debug')!r}, expected false")
                if app.get("buildMode") != "release":
                    failures.append(
                        f"Packaged app.buildMode is {app.get('buildMode')!r}, expected release")
            notes.append(f"packaged minAPIVersion={app.get('minAPIVersion')} "
                         f"targetAPIVersion={app.get('targetAPIVersion')}")
            if identity["appScopeVersionCode"] not in (None, app.get("versionCode")):
                notes.append(
                    "AppScope app.json5 versionCode "
                    f"{identity['appScopeVersionCode']} is overridden by the Flutter build "
                    f"(packaged {app.get('versionCode')})")

            # --- permissions ------------------------------------------------
            permissions = module.get("requestPermissions", []) or []
            names_present = sorted(
                item.get("name") for item in permissions if isinstance(item, dict) and item.get("name"))
            forbidden = sorted(FORBIDDEN_PERMISSIONS.intersection(names_present))
            if forbidden:
                failures.append(f"Offline product requests network or sensitive permission: {forbidden}")
            if names_present != identity["permissions"]:
                failures.append(
                    f"Packaged permissions {names_present} differ from declared "
                    f"{identity['permissions']}")

        # --- pack.info agreement -------------------------------------------
        if "pack.info" in names:
            try:
                summary = json.loads(archive.read("pack.info")).get("summary", {})
                packed_app = summary.get("app", {})
                if packed_app.get("bundleName") not in (None, identity["bundleName"]):
                    failures.append("pack.info bundle differs from this product")
                version = packed_app.get("version", {})
                if version.get("name") not in (None, identity["versionName"]):
                    failures.append("pack.info versionName differs from pubspec")
            except (ValueError, KeyError) as error:
                failures.append(f"pack.info is not readable: {error}")

        # --- exact curriculum assets ---------------------------------------
        for kind in CONTENT_KINDS:
            source = sources[kind]
            matches = [name for name in names if name.endswith(f"/assets/content/dart_{kind}.json")]
            if len(matches) != 1:
                failures.append(
                    f"Expected exactly one packaged Dart {kind} asset, found {len(matches)}")
                continue
            packed = archive.read(matches[0])
            packed_count = 0
            if packed != (project / source["path"]).read_bytes():
                failures.append(f"Packaged {kind} differs from the authored build asset")
            try:
                document = json.loads(packed)
            except ValueError as error:
                failures.append(f"Packaged {kind} is not valid JSON: {error}")
                document = {}
            entries = document.get("entries") if isinstance(document, dict) else None
            if not isinstance(entries, list):
                failures.append(f"Packaged {kind} has no entries list")
                entries = []
            packed_count = len(entries)
            if packed_count != source["topics"]:
                failures.append(
                    f"Packaged {kind} denominator {packed_count} differs from authored "
                    f"{source['topics']}")
            if expected_topics is not None and packed_count != expected_topics:
                failures.append(
                    f"Packaged {kind} denominator {packed_count} differs from the requested "
                    f"{expected_topics}")
            if document.get("kind") not in (None, kind):
                failures.append(f"Packaged {kind} declares kind {document.get('kind')!r}")
            if document.get("schemaVersion") != source["schemaVersion"]:
                failures.append(f"Packaged {kind} schemaVersion differs from the authored asset")
            identifiers = [entry.get("id") if isinstance(entry, dict) else None for entry in entries]
            if any(not identifier for identifier in identifiers):
                failures.append(f"Packaged {kind} has entries without an id")
            if len(set(identifiers)) != len(identifiers):
                failures.append(f"Packaged {kind} reuses an id")
            languages = {entry.get("language") for entry in entries if isinstance(entry, dict)}
            if languages != {"dart"}:
                failures.append(f"Packaged {kind} language set is {sorted(map(str, languages))}")
            if kind == "tutorials":
                empty = [entry.get("id") for entry in entries
                         if isinstance(entry, dict) and not entry.get("lessons")]
                if empty:
                    failures.append(f"Packaged tutorials without lessons: {empty[:5]}")
            else:
                empty = [entry.get("id") for entry in entries
                         if isinstance(entry, dict) and not str(entry.get("code") or "").strip()]
                if empty:
                    failures.append(f"Packaged examples without code: {empty[:5]}")
            assets.append({
                "kind": kind,
                "path": matches[0],
                "bytes": len(packed),
                "topics": packed_count,
                "sha256": sha256_bytes(packed),
                "authoredPath": source["path"],
                "authoredTopics": source["topics"],
                "authoredSha256": source["sha256"],
            })

    # --- immutability ------------------------------------------------------
    if expect_sha256 and digest != expect_sha256.lower():
        failures.append(
            f"Artifact fingerprint differs from the pinned value: {digest} != {expect_sha256.lower()}")
    after = sha256_file(hap)
    if after != digest:
        failures.append("Artifact changed while it was inspected")

    release_verified = (require_release
                        and manifest.get("app", {}).get("debug") is False
                        and manifest.get("app", {}).get("buildMode") == "release")

    return {
        "ok": not failures,
        "path": str(hap),
        "bytes": size,
        "sha256": digest,
        "sha256AfterInspection": after,
        "immutableVerified": after == digest,
        "expectedSha256": expect_sha256.lower() if expect_sha256 else None,
        "abi": abi,
        "elfMachine": machine,
        "elfLibraries": libraries,
        "bundle": manifest.get("app", {}).get("bundleName"),
        "versionName": manifest.get("app", {}).get("versionName"),
        "versionCode": manifest.get("app", {}).get("versionCode"),
        "debug": manifest.get("app", {}).get("debug"),
        "buildMode": manifest.get("app", {}).get("buildMode"),
        "releaseModeVerified": release_verified,
        "requiredTopics": expected_topics,
        "identity": identity,
        "permissions": permissions,
        "assets": assets,
        "fingerprints": {
            "hap": digest,
            "assets": {kind: sources[kind]["sha256"] for kind in CONTENT_KINDS},
            "assetEntries": {kind: sources[kind]["topics"] for kind in CONTENT_KINDS},
            "identitySources": identity_sources,
        },
        "notes": notes,
        "failures": failures,
        "signatureVerified": False,
        "deviceVerified": False,
        # Package inspection never reads EntryAbility bytes or behavior, so it
        # cannot prove the native URL guard. That evidence is a separate test.
        "nativeGuardVerified": False,
        "gates": {
            "packageInspected": True,
            "releaseModeVerified": release_verified,
            "signatureVerified": False,
            "deviceVerified": False,
            "nativeGuardVerified": False,
            "pending": [
                "verify_dart_hap.ps1 signature/profile",
                "native offline guard (test/native_entry_ability_test.cjs)",
                "installed device execution",
            ],
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("hap", type=Path)
    parser.add_argument("--abi", choices=sorted(ELF_MACHINE), required=True)
    parser.add_argument("--topics", type=int, default=None,
                        help="Optional expected denominator; must match the authored assets")
    parser.add_argument("--project", type=Path, default=None,
                        help="Product root; defaults to two levels above this script")
    parser.add_argument("--report", type=Path, default=None)
    parser.add_argument("--expect-sha256", default=None,
                        help="Pin the artifact fingerprint so a rebuild cannot be substituted")
    parser.add_argument("--allow-non-release", action="store_true",
                        help="Accept a debug/profile build (not valid release evidence)")
    args = parser.parse_args()

    project = args.project or Path(__file__).resolve().parents[2]
    report_path = args.report
    try:
        result = inspect_hap(
            args.hap,
            project,
            args.abi,
            args.topics,
            args.expect_sha256,
            require_release=not args.allow_non_release,
        )
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        result = {
            "ok": False,
            "path": str(Path(args.hap).resolve()),
            "abi": args.abi,
            "failures": [f"{type(error).__name__}: {error}"],
            "signatureVerified": False,
            "deviceVerified": False,
            "releaseModeVerified": False,
            "nativeGuardVerified": False,
        }
    result["toolSha256"] = sha256_file(Path(__file__).resolve())

    if report_path:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))
    if not result.get("ok"):
        print("HAP inspection failed:", file=sys.stderr)
        for failure in result.get("failures", []):
            print(f"  - {failure}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
