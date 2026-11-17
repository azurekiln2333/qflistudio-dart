#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
contents="${TARGET_BUILD_DIR:?}/${CONTENTS_FOLDER_PATH:?}"
destination="$contents/Helpers/dart-sdk"
identity="${EXPANDED_CODE_SIGN_IDENTITY:--}"
if [[ -z "$identity" ]]; then identity=-; fi
# Keep the array nonempty: macOS Bash 3.2 rejects empty arrays with nounset.
sign_options=(--force --sign "$identity")
if [[ "$identity" != - ]]; then sign_options+=(--timestamp --options runtime); fi
for arch in ${ARCHS:-$(uname -m)}; do
  case "$arch" in
    arm64) source="${QFLI_DART_SDK_ARM64:-}"; target=arm64 ;;
    x86_64) source="${QFLI_DART_SDK_X64:-}"; target=x64 ;;
    *) printf 'Unsupported Dart SDK architecture: %s\n' "$arch" >&2; exit 1 ;;
  esac
  if [[ -z "$source" && "$arch" == "$(uname -m)" ]]; then
    source="${QFLI_DART_SDK:-${FLUTTER_ROOT:?}/bin/cache/dart-sdk}"
  fi
  if [[ ! -x "$source/bin/dart" || ! -f "$source/lib/core/core.dart" ]]; then
    printf 'Provide the complete %s SDK using QFLI_DART_SDK_ARM64 or QFLI_DART_SDK_X64\n' "$arch" >&2
    exit 1
  fi
  lipo "$source/bin/dart" -verify_arch "$arch"
  # Helpers contains nested code. Store SDK data in Resources and preserve the
  # SDK's lookup paths with relative links (Apple TN2206, Nested Code / FAQ).
  python3 - "$source" "$destination/$target" "$contents/Resources/dart-sdk/$target" "$contents" <<'PY'
import os
from pathlib import Path
import shutil
import subprocess
import sys

source, sdk, resources, contents = [Path(arg).absolute() for arg in sys.argv[1:]]
source = source.resolve()
contents = contents.resolve()
for directory in (sdk, resources):
    if directory.is_symlink():
        raise SystemExit(f'SDK output root must not be a symlink: {directory}')
sdk = sdk.parent.resolve() / sdk.name
resources = resources.parent.resolve() / resources.name
if sdk.name not in ('arm64', 'x64') or resources.name != sdk.name:
    raise SystemExit('Unexpected SDK architecture destination')
if sdk != contents / 'Helpers' / 'dart-sdk' / sdk.name:
    raise SystemExit('SDK code destination must stay inside the app')
if resources != contents / 'Resources' / 'dart-sdk' / sdk.name:
    raise SystemExit('SDK data destination must stay inside the app')
for directory in (sdk, resources):
    if source == directory or source in directory.parents or directory in source.parents:
        raise SystemExit('Source SDK and packaged SDK must not overlap')
for directory in (sdk, resources):
    if directory.exists():
        shutil.rmtree(directory)
sdk.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(['ditto', str(source), str(sdk)], check=True)

paths = list(sdk.rglob('*'))
code = set()
code_directories = {sdk}
original_links = {}
for path in paths:
    if path.is_symlink():
        target = path.resolve(strict=True)
        if sdk not in target.parents:
            raise SystemExit(f'Source SDK link escapes its tree: {path}')
        original_links[path.relative_to(sdk)] = target.relative_to(sdk)
    elif path.is_file():
        description = subprocess.check_output(['/usr/bin/file', '-b', str(path)])
        if b'Mach-O' in description:
            code.add(path)
            code_directories.update(parent for parent in path.parents if parent == sdk or sdk in parent.parents)

# Move only the highest data-only directories. Dotted directory names in
# Helpers would otherwise be interpreted as nested code bundles by codesign.
moved = []
for path in paths:
    if path.is_symlink() or not path.is_dir():
        continue
    if path not in code_directories and path.parent in code_directories:
        relative = path.relative_to(sdk)
        resource = resources / relative
        resource.parent.mkdir(parents=True, exist_ok=True)
        path.replace(resource)
        path.symlink_to(os.path.relpath(resource, path.parent), target_is_directory=True)
        moved.append(relative)
for path in paths:
    if path.parent not in code_directories or not path.is_file() or path.is_symlink() or path in code:
        continue
    relative = path.relative_to(sdk)
    resource = resources / relative
    resource.parent.mkdir(parents=True, exist_ok=True)
    path.replace(resource)
    path.symlink_to(os.path.relpath(resource, path.parent))
    moved.append(relative)

# A link moved into Resources may still point to code kept in Helpers.
# Rebase original links against their original SDK targets after the move.
for relative, target_relative in original_links.items():
    in_resources = any(parent == relative or parent in relative.parents for parent in moved)
    link = (resources if in_resources else sdk) / relative
    target = sdk / target_relative
    link.unlink()
    link.symlink_to(os.path.relpath(target, link.parent), target_is_directory=target.is_dir())

for original in source.rglob('*'):
    packaged = sdk / original.relative_to(source)
    if original.is_file() and not packaged.is_file():
        raise SystemExit(f'Missing packaged SDK file: {packaged}')
    if original.is_dir() and not packaged.is_dir():
        raise SystemExit(f'Missing packaged SDK directory: {packaged}')
for tree in (sdk, resources):
    for path in tree.rglob('*'):
        if path.is_symlink():
            target = path.resolve(strict=True)
            if os.path.isabs(os.readlink(path)) or contents not in target.parents:
                raise SystemExit(f'SDK link must stay relative and inside the app: {path}')
        elif tree == sdk and path not in code and path not in code_directories:
            raise SystemExit(f'Non-code entry remains in Helpers: {path}')
print(f'Preserved SDK layout; moved {len(moved)} data entries to Resources.')
PY
  while IFS= read -r -d '' file; do
    if /usr/bin/file -b "$file" | /usr/bin/grep -q 'Mach-O'; then
      codesign_args=("${sign_options[@]}")
      if [[ "$file" == "$destination/$target/bin/dart" ||
            "$file" == "$destination/$target/bin/dartvm" ||
            "$file" == "$destination/$target/bin/dartaotruntime" ]]; then
        codesign_args+=(--entitlements "$root/native/dart-sdk/DartVM.entitlements")
      fi
      codesign "${codesign_args[@]}" "$file"
    fi
  done < <(find "$destination/$target" -type f -print0)
done
