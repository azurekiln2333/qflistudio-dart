#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
destination="${TARGET_BUILD_DIR:?}/${CONTENTS_FOLDER_PATH:?}/Helpers/dart-sdk"
identity="${EXPANDED_CODE_SIGN_IDENTITY:--}"
if [[ -z "$identity" ]]; then identity=-; fi
sign_options=()
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
  lipo -verify_arch "$arch" "$source/bin/dart"
  mkdir -p "$destination/$target"
  ditto "$source" "$destination/$target"
  while IFS= read -r -d '' file; do
    if /usr/bin/file -b "$file" | /usr/bin/grep -q 'Mach-O'; then
      entitlements=()
      if [[ "$file" == "$destination/$target/bin/dart" ||
            "$file" == "$destination/$target/bin/dartvm" ||
            "$file" == "$destination/$target/bin/dartaotruntime" ]]; then
        entitlements=(--entitlements "$root/native/dart-sdk/DartVM.entitlements")
      fi
      codesign --force --sign "$identity" "${sign_options[@]}" "${entitlements[@]}" "$file"
    fi
  done < <(find "$destination/$target" -type f -print0)
done
