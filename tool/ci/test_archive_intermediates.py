"""Exercise archive boundaries in cloud fixtures without downloading a toolchain."""

import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import tarfile
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from archive_intermediates import GENERATED_ROOTS, archive_outputs


class IntermediateArchiveTest(unittest.TestCase):
    def symlink(self, link, target, **kwargs):
        try:
            link.symlink_to(target, **kwargs)
        except OSError as error:
            self.skipTest(f'Symbolic links are unavailable: {error}')

    def test_archive_preserves_payload_and_excludes_private_or_external_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'repo'
            root.mkdir()
            payloads = {
                'build/app/intermediates/native/object.o': b'native object',
                '.dart_tool/flutter_build/hash/app.dill': b'flutter intermediate',
                'native/build/android/libvm.so': b'native library',
                'build/linux/x64/release/CMakeFiles/check.bin': b'cmake configuration',
                'build/linux/x64/release/runner/CMakeFiles/app.dir/main.cc.o': b'runner object',
                'build/linux/x64/release/flutter/CMakeFiles/generated.o': b'flutter object',
                'ohos/build/intermediates/project.bin': b'ohos project intermediate',
                'ohos/entry/build/intermediates/data.bin': b'ohos intermediate',
            }
            for relative, content in payloads.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
            for relative in ('build/app/intermediates/private.p12',
                             'build/app/intermediates/.env',
                             'build/app/intermediates/signing/profile.json',
                             'build/app/intermediates/cache/sdk.bin',
                             'build/app/intermediates/nested/.git/config',
                             'build/linux/x64/release/bundle/data/dart-sdk/bin/dart',
                             'build/stock-core-fixture/signing.key'):
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('excluded')
            external = Path(directory) / 'outside'
            external.write_text('must not escape')
            (root / 'build/app/intermediates/native/object.o').chmod(0o755)
            internal_link = root / 'build/app/intermediates/internal-link'
            # Windows stores the target verbatim; use its native separators.
            self.symlink(internal_link, Path('native') / 'object.o')
            self.assertEqual(internal_link.resolve(strict=True),
                             (root / 'build/app/intermediates/native/object.o').resolve(strict=True))
            self.assertEqual(internal_link.read_bytes(), b'native object')
            self.symlink(root / 'build/app/intermediates/unsafe-link', external)
            self.symlink(root / 'build/app/intermediates/broken-link', 'missing')
            self.symlink(root / 'build/app/intermediates/private-link', 'private.p12')
            output = root / 'dist/intermediates'
            with patch.dict(os.environ, {'GITHUB_SHA': 'fixture-commit'}):
                record = archive_outputs(root, output, 'intermediates-fixture', 'failure')
            self.assertEqual(record['commit'], 'fixture-commit')
            self.assertEqual(record['jobStatusBeforeArchiving'], 'failure')
            with tarfile.open(output / 'intermediates-fixture.tar.gz') as archive:
                names = set(archive.getnames())
                for relative, expected in payloads.items():
                    self.assertEqual(archive.extractfile(relative).read(), expected)
                if os.name != 'nt':
                    self.assertEqual(archive.getmember('build/app/intermediates/native/object.o').mode, 0o755)
                self.assertTrue(archive.getmember('build/app/intermediates/internal-link').issym())
                self.assertEqual(archive.getmember('build/app/intermediates/internal-link').linkname, 'native/object.o')
                self.assertFalse(any('private' in name or 'unsafe' in name or 'broken' in name for name in names))
                self.assertNotIn('build/app/intermediates/.env', names)
                self.assertNotIn('build/app/intermediates/cache', names)
                self.assertNotIn('build/app/intermediates/nested/.git', names)
                self.assertFalse(any(name.startswith('dist/') for name in names))
                self.assertFalse(any(name.startswith('build/stock-core-') for name in names))
                self.assertFalse(any(name.startswith('build/linux/x64/release/bundle') for name in names))
                self.assertEqual(len(archive.getnames()), len(names))
            for line in (output / 'SHA256SUMS').read_text().splitlines():
                digest, name = line.split('  ')
                self.assertEqual(hashlib.sha256((output / name).read_bytes()).hexdigest(), digest)
            self.assertEqual(json.loads((output / 'provenance.json').read_text())['retentionDays'], 3)

    def test_native_relative_links_have_portable_tar_headers_and_keep_boundaries(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'repo'
            source = root / 'native/build/objects/object.o'
            source.parent.mkdir(parents=True)
            source.write_bytes(b'native object')
            link = root / 'native/build/internal-link'
            target = Path('objects') / 'object.o'
            # This cloud regression requires real links, without a skip fallback.
            link.symlink_to(target)
            self.assertEqual(os.readlink(link), str(target))
            self.assertEqual(link.resolve(strict=True), source.resolve(strict=True))
            self.assertEqual(link.read_bytes(), b'native object')
            # Even an included payload cannot make an absolute link portable.
            absolute_link = link.with_name('absolute-link')
            absolute_link.symlink_to(source.resolve(strict=True))
            self.assertEqual(absolute_link.read_bytes(), b'native object')
            external = Path(directory) / 'outside.o'
            external.write_bytes(b'outside payload')
            escaping_link = link.with_name('escaping-link')
            escaping_link.symlink_to(os.path.relpath(external, link.parent))
            self.assertEqual(escaping_link.read_bytes(), b'outside payload')
            output = root / 'dist/intermediates'
            archive_outputs(root, output, 'native-links', 'success')
            with tarfile.open(output / 'native-links.tar.gz') as archive:
                member = archive.getmember('native/build/internal-link')
                self.assertTrue(member.issym())
                self.assertEqual(member.linkname, 'objects/object.o')
                self.assertEqual(archive.extractfile(member).read(), b'native object')
                self.assertEqual(archive.extractfile('native/build/objects/object.o').read(),
                                 b'native object')
                names = set(archive.getnames())
                self.assertNotIn('native/build/absolute-link', names)
                self.assertNotIn('native/build/escaping-link', names)

    def test_empty_failed_source_warns_without_creating_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / 'dist/intermediates'
            summary = root / 'summary.md'
            with patch.dict(os.environ, {'GITHUB_STEP_SUMMARY': str(summary)}):
                with patch('builtins.print') as log:
                    self.assertIsNone(archive_outputs(root, output, 'empty', 'failure'))
            self.assertFalse(output.exists())
            self.assertIn('::warning::', log.call_args.args[0])
            self.assertIn('Job status before archiving: failure', summary.read_text())

    def test_success_without_intermediate_files_fails(self):
        for empty_directory in (None, 'build/linux/x64/release/CMakeFiles'):
            with self.subTest(empty_directory=empty_directory):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    if empty_directory:
                        (root / empty_directory).mkdir(parents=True)
                    output = root / 'dist/intermediates'
                    with self.assertRaisesRegex(RuntimeError, 'successful build must produce an archive'):
                        archive_outputs(root, output, 'empty-success', 'success')
                    self.assertFalse(output.exists())

    def test_success_without_outputs_still_fails_after_later_job_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(RuntimeError, 'successful build must produce an archive'):
                archive_outputs(root, root / 'dist', 'missing', 'failure', build_status='success')

    def test_linux_release_cmake_outputs_are_archived_without_flutter_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'build/linux/x64/release/runner/CMakeFiles/app.dir/main.cc.o'
            source.parent.mkdir(parents=True)
            source.write_bytes(b'linux object')
            output = root / 'dist/intermediates'
            record = archive_outputs(root, output, 'linux-release', 'failure', build_status='success')
            self.assertEqual(record['jobStatusBeforeArchiving'], 'failure')
            self.assertEqual(record['buildStepOutcome'], 'success')
            self.assertEqual(record['includedRoots'], ['build/linux/x64/release/runner/CMakeFiles'])
            with tarfile.open(output / 'linux-release.tar.gz') as archive:
                self.assertEqual(archive.extractfile(source.relative_to(root).as_posix()).read(), b'linux object')

    def test_reparse_directories_are_not_traversed(self):
        for relative in ('native', 'native/build', 'native/build/junction'):
            with self.subTest(relative=relative):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory).resolve()
                    redirected = root / relative
                    redirected.mkdir(parents=True)
                    leaked = redirected / ('build/outside.txt' if relative == 'native' else 'outside.txt')
                    leaked.parent.mkdir(parents=True, exist_ok=True)
                    leaked.write_text('must not follow')
                    original_lstat = Path.lstat
                    original_iterdir = Path.iterdir

                    def lstat(path, *args, **kwargs):
                        if path == redirected:
                            return SimpleNamespace(st_mode=stat.S_IFDIR | 0o755,
                                                   st_file_attributes=0x400)
                        return original_lstat(path, *args, **kwargs)

                    def iterdir(path):
                        if path == redirected:
                            self.fail('A Windows directory reparse point was traversed')
                        return original_iterdir(path)

                    output = root / 'dist/intermediates'
                    with patch.object(Path, 'lstat', lstat), patch.object(Path, 'iterdir', iterdir):
                        self.assertIsNone(archive_outputs(root, output, 'reparse', 'failure'))
                    self.assertFalse(output.exists())

    @unittest.skipUnless(os.name == 'nt', 'Real NTFS junction coverage runs on Windows')
    def test_real_windows_junctions_are_not_followed(self):
        for relative in ('native', 'native/build', 'native/build/junction'):
            with self.subTest(relative=relative):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory) / 'repo'
                    outside = Path(directory) / 'outside'
                    outside.mkdir()
                    source = outside / ('build/private.txt' if relative == 'native' else 'private.txt')
                    source.parent.mkdir(parents=True, exist_ok=True)
                    source.write_text('outside payload')
                    junction = root / relative
                    junction.parent.mkdir(parents=True)
                    subprocess.run(['cmd', '/c', 'mklink', '/J', str(junction), str(outside)],
                                   check=True, capture_output=True, text=True)
                    try:
                        output = root / 'dist/intermediates'
                        self.assertIsNone(archive_outputs(root, output, 'junction', 'failure'))
                        self.assertFalse(output.exists())
                        self.assertEqual(source.read_text(), 'outside payload')
                    finally:
                        junction.rmdir()

    def test_input_symlink_ancestors_are_not_followed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'repo'
            root.mkdir()
            outside = Path(directory) / 'outside'
            (outside / 'build').mkdir(parents=True)
            (outside / 'build/private.txt').write_text('outside payload')
            self.symlink(root / 'native', outside, target_is_directory=True)
            output = root / 'dist/intermediates'
            self.assertIsNone(archive_outputs(root, output, 'symlink-root', 'failure'))
            self.assertFalse(output.exists())

    def test_rejects_output_inside_input_and_unsafe_names(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for relative in GENERATED_ROOTS:
                with self.subTest(input=relative):
                    with self.assertRaisesRegex(ValueError, 'outside generated input directories'):
                        archive_outputs(root, root / relative / 'archive', 'valid')
            with self.assertRaises(ValueError):
                archive_outputs(root, root / 'dist', '../outside')


if __name__ == '__main__':
    unittest.main()
