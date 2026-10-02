#!/usr/bin/env bash
set -euo pipefail

abi=${1:?Usage: prepare_sdk.sh arm64-v8a\|x86_64 OUTPUT_DIRECTORY}
output=${2:?Missing output directory}
case "$abi" in arm64-v8a|x86_64) ;; *) exit 2 ;; esac
script_dir=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output"
output=$(cd "$output" && pwd)
mapfile -t package < <(python3 - "$script_dir/packages.lock.json" "$abi" <<'PY'
import json
import sys
with open(sys.argv[1], encoding='utf-8') as source:
    package = json.load(source)['packages'][sys.argv[2]]
for field in ('filename', 'size', 'sha256'):
    print(package[field])
PY
)
test "${#package[@]}" -eq 3
archive="$output/package.deb"
curl --fail --location --retry 2 --output "$archive" \
  "https://mirrors.ustc.edu.cn/termux/apt/termux-main/${package[0]}"
test "$(stat -c %s "$archive")" = "${package[1]}"
printf '%s  %s\n' "${package[2]}" "$archive" | sha256sum --check
dpkg-deb --extract "$archive" "$output/package"
sdk="$output/package/data/data/com.termux/files/usr/lib/dart-sdk"
# The package's absolute Termux alias would be dangling outside its original prefix.
ln -sfn vm_platform.dill "$sdk/lib/_internal/vm_platform_strong.dill"
tar --dereference -cf "$output/sdk.tar" -C "$sdk" .
printf 'Verified SDK export: %s/sdk.tar\n' "$output"
