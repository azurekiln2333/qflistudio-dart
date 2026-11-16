"""Verify and archive a host Dart SDK without requiring Flutter or pub packages."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', required=True, type=Path)
    parser.add_argument('--platform', required=True, choices=['windows', 'linux', 'macos'])
    parser.add_argument('--arch', required=True, choices=['x64', 'arm64'])
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    sdk = args.sdk.resolve(strict=True)
    dart = sdk / 'bin' / ('dart.exe' if args.platform == 'windows' else 'dart')
    for file in [dart, sdk / 'lib/core/core.dart', sdk / 'LICENSE', sdk / 'version']:
        if not file.is_file():
            raise SystemExit(f'Incomplete SDK: {file}')
    version = subprocess.check_output([str(dart), '--version'], text=True, stderr=subprocess.STDOUT).strip()
    if f'"{args.platform}_{args.arch}"' not in version:
        raise SystemExit(f'SDK target differs from {args.platform}_{args.arch}: {version}')
    with tempfile.TemporaryDirectory(prefix='qfli-native-ci-') as directory:
        work = Path(directory)
        source = work / 'probe.dart'
        source.write_text("import 'dart:io';\nvoid main() { final f = File('probe.txt'); "
                          "f.writeAsStringSync('native-ci-ok'); print(f.readAsStringSync()); }\n")
        subprocess.run([str(dart), 'compile', 'kernel', str(source), '-o', str(work / 'probe.dill')],
                       cwd=work, check=True, timeout=180)
        source.unlink()
        actual = subprocess.check_output([str(dart), str(work / 'probe.dill')], cwd=work,
                                         text=True, timeout=30)
        if actual.strip() != 'native-ci-ok':
            raise SystemExit(f'Source-free Kernel probe failed: {actual!r}')
    args.output.mkdir(parents=True, exist_ok=True)
    label = f'native-{args.platform}-{args.arch}'
    extension = '.zip' if args.platform == 'windows' else '.tar.gz'
    archive = args.output / (label + extension)
    if args.platform == 'windows':
        with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as zipped:
            for path in sorted(sdk.rglob('*')):
                if path.is_file():
                    zipped.write(path, 'dart-sdk/' + path.relative_to(sdk).as_posix())
    else:
        with tarfile.open(archive, 'w:gz') as tar:
            tar.add(sdk, arcname='dart-sdk')
    with archive.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    provenance = {
        'schemaVersion': 1,
        'platform': args.platform,
        'architecture': args.arch,
        'sdkVersion': (sdk / 'version').read_text().strip(),
        'versionOutput': version,
        'repository': os.environ.get('GITHUB_REPOSITORY'),
        'commit': os.environ.get('GITHUB_SHA'),
        'runId': os.environ.get('GITHUB_RUN_ID'),
        'flutterCommit': '00b0c91f06209d9e4a41f71b7a512d6eb3b9c694',
        'validation': ['host-vm-version', 'kernel-compilation', 'source-free-kernel-file-io'],
        'applicationUiVerified': False,
        'archive': archive.name,
        'sha256': digest,
    }
    (args.output / (label + '.json')).write_text(json.dumps(provenance, indent=2) + '\n')
    (args.output / (label + '.sha256')).write_text(f'{digest}  {archive.name}\n')
    print(json.dumps(provenance, indent=2))


if __name__ == '__main__':
    main()
