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
  mkdir -p "$destination/$target"
  ditto "$source" "$destination/$target"
  # Helpers contains nested code. Store SDK data in Resources and preserve the
  # SDK's lookup paths with relative links (Apple TN2206, Nested Code / FAQ).
  python3 - "$source" "$destination/$target" "$contents/Resources/dart-sdk/$target" "$contents" <<'PY'
import os
from pathlib import Path
import subprocess
import sys

source, sdk, resources, contents = [Path(arg).resolve() for arg in sys.argv[1:]]
moved = 0
for path in sdk.rglob('*'):
    if path.is_symlink() or not path.is_file():
        continue
    description = subprocess.check_output(['/usr/bin/file', '-b', str(path)])
    if b'Mach-O' in description:
        continue
    resource = resources / path.relative_to(sdk)
    resource.parent.mkdir(parents=True, exist_ok=True)
    path.replace(resource)
    path.symlink_to(os.path.relpath(resource, path.parent))
    moved += 1

for original in source.rglob('*'):
    packaged = sdk / original.relative_to(source)
    if original.is_file() and not packaged.is_file():
        raise SystemExit(f'Missing packaged SDK file: {packaged}')
    if original.is_dir() and not packaged.is_dir():
        raise SystemExit(f'Missing packaged SDK directory: {packaged}')
for path in sdk.rglob('*'):
    if path.is_symlink():
        target = path.resolve(strict=True)
        if os.path.isabs(os.readlink(path)) or contents not in target.parents:
            raise SystemExit(f'SDK link must stay relative and inside the app: {path}')
print(f'Preserved SDK layout; moved {moved} data files to Resources.')
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
