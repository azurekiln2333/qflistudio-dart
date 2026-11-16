#!/usr/bin/env python3
"""Bootstrap a hosted OHOS build and package its unsigned outputs.

Run only in the disposable GitHub Actions checkout. The command line tools URL
and SHA-256 come from the lock file or a complete workflow/repository override. No signing key,
password, certificate, or local SDK is copied from a developer workstation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.parse
import urllib.request
import zipfile


PROJECT = Path(__file__).resolve().parents[2]


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def require_ci() -> Path:
    if os.environ.get("GITHUB_ACTIONS") != "true":
        raise RuntimeError("Use this helper only in the disposable GitHub Actions checkout.")
    workspace = Path(os.environ["GITHUB_WORKSPACE"]).resolve()
    if not PROJECT.is_relative_to(workspace):
        raise RuntimeError("Project is outside GITHUB_WORKSPACE.")
    return Path(os.environ["RUNNER_TEMP"])


def sanitize_profile(profile: Path) -> None:
    document = json.loads(profile.read_text(encoding="utf-8"))
    document["app"]["signingConfigs"] = []
    for product in document["app"]["products"]:
        product.pop("signingConfig", None)
    profile.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")


def sanitize() -> None:
    require_ci()
    sanitize_profile(PROJECT / "ohos/build-profile.json5")
    print("Removed signing configuration from the disposable CI project copy.")


def unpack(archive: Path, output: Path) -> None:
    output.mkdir()
    if zipfile.is_zipfile(archive):
        links = []
        with zipfile.ZipFile(archive) as package:
            for member in package.infolist():
                relative = PurePosixPath(member.filename)
                if relative.is_absolute() or ".." in relative.parts or "\\" in member.filename:
                    raise RuntimeError("Tool archive contains an unsafe path.")
                target = output.joinpath(*relative.parts)
                mode = member.external_attr >> 16
                if member.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                elif mode & 0o170000 == 0o120000:
                    link = package.read(member).decode("utf-8")
                    if Path(link).is_absolute() or not (target.parent / link).resolve().is_relative_to(output.resolve()):
                        raise RuntimeError("Tool archive contains an unsafe symbolic link.")
                    links.append((target, link))
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with package.open(member) as source, target.open("wb") as sink:
                        shutil.copyfileobj(source, sink)
                    if mode & 0o777:
                        target.chmod(mode & 0o777)
        for target, link in links:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(link)
    elif tarfile.is_tarfile(archive):
        with tarfile.open(archive) as package:
            package.extractall(output, filter="data")
    else:
        raise RuntimeError("Command Line Tools must be a ZIP or TAR archive.")


def find_toolchain(root: Path) -> tuple[Path, dict[str, Path], dict]:
    candidates = []
    for metadata in root.rglob("sdk-pkg.json"):
        if len(metadata.relative_to(root).parts) > 6:
            continue
        sdk = metadata.parent
        if not (sdk / "openharmony/toolchains/hdc").is_file():
            continue
        data = json.loads(metadata.read_text(encoding="utf-8"))["data"]
        if int(str(data["apiVersion"]).split(".")[0]) < 24:
            continue
        sdk_root = sdk.parent
        tools_root = sdk_root.parent
        for name in ("tool", "tools"):
            tools = tools_root / name
            for commands in (tools_root, tools):
                executables = {
                    "node": tools / "node/bin/node",
                    "ohpm": commands / "ohpm/bin/ohpm",
                    "hvigor": commands / "hvigor/bin/hvigorw",
                }
                if all(path.is_file() for path in executables.values()):
                    if commands == tools_root:
                        wrappers = {"ohpm": tools_root / "bin/ohpm", "hvigor": tools_root / "bin/hvigorw"}
                        if all(path.is_file() for path in wrappers.values()):
                            executables.update(wrappers)
                    candidates.append((sdk_root, executables, data))
    if len(candidates) != 1:
        raise RuntimeError(
            "Expected one HarmonyOS SDK with API >= 24, tool/node or tools/node, "
            "and ohpm/bin/ohpm plus hvigor/bin/hvigorw in the archive root or tools directory. "
            "Use the complete official Linux x64 Command Line Tools archive."
        )
    return candidates[0]


def toolchain_source() -> dict:
    url = os.environ.get("OHOS_COMMAND_LINE_TOOLS_URL", "").strip()
    expected = os.environ.get("OHOS_COMMAND_LINE_TOOLS_SHA256", "").strip().lower()
    if bool(url) != bool(expected):
        raise RuntimeError(
            "Supply both OHOS_COMMAND_LINE_TOOLS_URL and OHOS_COMMAND_LINE_TOOLS_SHA256 "
            "to override the locked HarmonyOS toolchain."
        )
    source = {"url": url, "sha256": expected} if url else json.loads(
        (PROJECT / "tool/ci/ohos-command-line-tools.lock.json").read_text(encoding="utf-8")
    )
    url, expected = source["url"], source["sha256"]
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise RuntimeError("Command Line Tools URL must use HTTPS without embedded credentials.")
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise RuntimeError("Command Line Tools SHA-256 must contain exactly 64 hexadecimal digits.")
    return source


def bootstrap() -> None:
    temporary = require_ci()
    source_config = toolchain_source()
    url, expected = source_config["url"], source_config["sha256"]
    parsed = urllib.parse.urlsplit(url)
    archive = temporary / "ohos-command-line-tools.archive"
    print("Downloading the official HarmonyOS command line tools.")
    request = urllib.request.Request(url, headers={"User-Agent": "qfli-dart-github-actions"})
    try:
        with urllib.request.urlopen(request, timeout=120) as source, archive.open("wb") as target:
            shutil.copyfileobj(source, target)
    except OSError as error:
        raise RuntimeError("Cannot download the Command Line Tools archive. Check the supplied URL and its expiry.") from error
    if sha256(archive) != expected:
        raise RuntimeError("Command Line Tools SHA-256 differs from the supplied digest.")
    unpack(archive, temporary / "ohos-command-line-tools")
    sdk, executables, metadata = find_toolchain(temporary / "ohos-command-line-tools")
    if "expectedApiVersion" in source_config and int(metadata["apiVersion"]) != source_config["expectedApiVersion"]:
        raise RuntimeError("HarmonyOS SDK API differs from the locked API version.")
    # The pinned Flutter OHOS release looks for tool/node on Linux. The official
    # setup guide also documents tools/node. Keep the extracted SDK untouched
    # except for this directory alias when the archive uses the latter layout.
    tools = executables["node"].parents[2]
    linux_tools = sdk.parent / "tool"
    if tools.name == "tools" and not linux_tools.exists():
        linux_tools.symlink_to(tools, target_is_directory=True)
    with Path(os.environ["GITHUB_ENV"]).open("a", encoding="utf-8") as env:
        env.write(f"DEVECO_SDK_HOME={sdk}\n")
        env.write(f"HOS_SDK_HOME={sdk}\n")
        env.write(f"DEVECO_NODE_HOME={executables['node'].parents[1]}\n")
    with Path(os.environ["GITHUB_PATH"]).open("a", encoding="utf-8") as paths:
        for directory in dict.fromkeys(path.parent for path in executables.values()):
            paths.write(f"{directory}\n")
    (temporary / "ohos-toolchain.json").write_text(json.dumps({
        "archiveSha256": expected,
        "archiveSize": archive.stat().st_size,
        "archiveSource": urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, parsed.path, "", "")),
        "archiveVersion": source_config.get("version"),
        "sourceReference": source_config.get("sourceReference"),
        "sdk": metadata,
    }, indent=2) + "\n", encoding="utf-8")
    print(f"Verified HarmonyOS SDK {metadata.get('version')} (API {metadata['apiVersion']}).")


def checksum_directory(directory: Path) -> None:
    lines = [f"{sha256(path)}  {path.relative_to(directory).as_posix()}"
             for path in sorted(directory.rglob("*")) if path.is_file() and path.name != "SHA256SUMS"]
    (directory / "SHA256SUMS").write_text("\n".join(lines) + "\n", encoding="utf-8")


def package() -> None:
    temporary = require_ci()
    app = PROJECT / "dist/ohos/app"
    native = PROJECT / "dist/ohos/native"
    app.mkdir(parents=True)
    native.mkdir(parents=True)
    hap = PROJECT / "build/ohos/hap/entry-default-unsigned.hap"
    app_archive = PROJECT / "build/ohos/app/ohos-default-unsigned.app"
    for source in (hap, app_archive):
        if not source.is_file():
            raise RuntimeError(f"Missing expected unsigned application output: {source.relative_to(PROJECT)}")
        shutil.copy2(source, app / source.name)
    inspect = PROJECT / "tool/ohos/inspect_dart_hap.py"
    subprocess.run([sys.executable, str(inspect), str(hap), "--abi", "arm64-v8a",
                    "--project", str(PROJECT), "--report", str(app / "hap-inspection.json")], check=True)
    with zipfile.ZipFile(app_archive) as archive:
        haps = [entry for entry in archive.infolist() if entry.filename.endswith(".hap")]
        if not haps:
            raise RuntimeError("APP contains no nested HAP.")
        for index, entry in enumerate(haps):
            nested = temporary / f"ohos-app-entry-{index}.hap"
            with archive.open(entry) as source, nested.open("wb") as target:
                shutil.copyfileobj(source, target)
            subprocess.run([sys.executable, str(inspect), str(nested), "--abi", "arm64-v8a",
                            "--project", str(PROJECT), "--report", str(app / f"app-hap-{index}-inspection.json")], check=True)
    with zipfile.ZipFile(hap) as archive:
        for entry in archive.infolist():
            if not entry.filename.startswith("libs/arm64-v8a/") or not entry.filename.endswith(".so"):
                continue
            relative = PurePosixPath(entry.filename)
            if ".." in relative.parts:
                raise RuntimeError("HAP contains an unsafe native library path.")
            target = native.joinpath(*relative.parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(entry) as source, target.open("wb") as output:
                shutil.copyfileobj(source, output)
    evidence = {
        "applicationCommit": os.environ["GITHUB_SHA"],
        "coreCommit": os.environ["CORE_REVISION"],
        "flutterCommit": os.environ["FLUTTER_OHOS_REVISION"],
        "flutterTag": os.environ["FLUTTER_OHOS_TAG"],
        "runUrl": f'{os.environ["GITHUB_SERVER_URL"]}/{os.environ["GITHUB_REPOSITORY"]}/actions/runs/{os.environ["GITHUB_RUN_ID"]}',
        "platform": "HarmonyOS", "architecture": "arm64-v8a", "signing": "unsigned",
        "nativeLibrarySourceHapSha256": sha256(hap),
        "independentDartSdk": False, "deviceRuntimeVerified": False,
        "toolchain": json.loads((temporary / "ohos-toolchain.json").read_text(encoding="utf-8")),
        "flutter": json.loads((temporary / "ohos-flutter-version.json").read_text(encoding="utf-8")),
    }
    for directory in (app, native):
        (directory / "provenance.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    (native / "README.txt").write_text(
        "Native libraries extracted from the matching unsigned ARM64 HAP.\n"
        "Contains Flutter engine, application AOT code and plugin libraries.\n"
        "This is not an independent Dart SDK. The app uses the portable Dart runtime on OHOS.\n",
        encoding="utf-8")
    checksum_directory(app)
    checksum_directory(native)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("sanitize", "bootstrap", "package"))
    args = parser.parse_args()
    try:
        {"sanitize": sanitize, "bootstrap": bootstrap, "package": package}[args.command]()
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.CalledProcessError, tarfile.TarError, zipfile.BadZipFile) as error:
        print(f"OHOS {args.command} failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
