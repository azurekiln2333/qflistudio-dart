"""Exercise archive boundaries in cloud fixtures without downloading a toolchain."""

import hashlib
import json
import os
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

from archive_intermediates import archive_outputs


class IntermediateArchiveTest(unittest.TestCase):
    def test_archive_preserves_payload_and_excludes_private_or_external_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'repo'
            root.mkdir()
            payloads = {
                'build/app/intermediates/native/object.o': b'native object',
                '.dart_tool/flutter_build/hash/app.dill': b'flutter intermediate',
                'native/build/android/libvm.so': b'native library',
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
                             'build/app/intermediates/nested/.git/config'):
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('excluded')
            external = Path(directory) / 'outside'
            external.write_text('must not escape')
            (root / 'build/app/intermediates/native/object.o').chmod(0o755)
            (root / 'build/app/intermediates/internal-link').symlink_to('native/object.o')
            (root / 'build/app/intermediates/unsafe-link').symlink_to(external)
            (root / 'build/app/intermediates/broken-link').symlink_to('missing')
            (root / 'build/app/intermediates/private-link').symlink_to('private.p12')
            output = root / 'dist/intermediates'
            with patch.dict(os.environ, {'GITHUB_SHA': 'fixture-commit'}):
                record = archive_outputs(root, output, 'intermediates-fixture', 'failure')
            self.assertEqual(record['commit'], 'fixture-commit')
            self.assertEqual(record['jobStatusBeforeArchiving'], 'failure')
            with tarfile.open(output / 'intermediates-fixture.tar.gz') as archive:
                names = set(archive.getnames())
                for relative, expected in payloads.items():
                    self.assertEqual(archive.extractfile(relative).read(), expected)
                self.assertEqual(archive.getmember('build/app/intermediates/native/object.o').mode, 0o755)
                self.assertTrue(archive.getmember('build/app/intermediates/internal-link').issym())
                self.assertEqual(archive.getmember('build/app/intermediates/internal-link').linkname, 'native/object.o')
                self.assertFalse(any('private' in name or 'unsafe' in name or 'broken' in name for name in names))
                self.assertNotIn('build/app/intermediates/.env', names)
                self.assertNotIn('build/app/intermediates/cache', names)
                self.assertNotIn('build/app/intermediates/nested/.git', names)
                self.assertFalse(any(name.startswith('dist/') for name in names))
                self.assertFalse(any(name.startswith('build/stock-core-') for name in names))
            for line in (output / 'SHA256SUMS').read_text().splitlines():
                digest, name = line.split('  ')
                self.assertEqual(hashlib.sha256((output / name).read_bytes()).hexdigest(), digest)
            self.assertEqual(json.loads((output / 'provenance.json').read_text())['retentionDays'], 3)

    def test_empty_source_does_not_create_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / 'dist/intermediates'
            self.assertIsNone(archive_outputs(root, output, 'empty'))
            self.assertFalse(output.exists())

    def test_rejects_output_inside_input_and_unsafe_names(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                archive_outputs(root, root / 'build/archive', 'valid')
            with self.assertRaises(ValueError):
                archive_outputs(root, root / 'dist', '../outside')


if __name__ == '__main__':
    unittest.main()
