import json
import os
from pathlib import Path
import plistlib
import tempfile
import unittest
import zipfile

import package_installer


class PackageInstallerTest(unittest.TestCase):
    def test_reads_the_application_version(self):
        with tempfile.TemporaryDirectory() as directory:
            pubspec = Path(directory) / 'pubspec.yaml'
            pubspec.write_text('name: qfli_dart\nversion: 1.2.3+45\nenvironment:\n  sdk: ^3.0.0\n')
            self.assertEqual(package_installer.read_version(pubspec), '1.2.3+45')
            pubspec.write_text('name: qfli_dart\n')
            with self.assertRaises(SystemExit):
                package_installer.read_version(pubspec)

    def test_reads_the_repository_version(self):
        version = package_installer.read_version(package_installer.ROOT / 'pubspec.yaml')
        package_installer.windows_file_version(version)

    def test_maps_the_version_to_a_windows_file_version(self):
        self.assertEqual(package_installer.windows_file_version('1.2.3+45'), '1.2.3.45')
        self.assertEqual(package_installer.windows_file_version('1.2.3'), '1.2.3.0')
        with self.assertRaises(SystemExit):
            package_installer.windows_file_version('1.2.3-beta')

    def test_parses_shared_library_dependencies(self):
        output = 'shlibs:Depends=libc6 (>= 2.34), libgtk-3-0t64 (>= 3.24)\n'
        self.assertEqual(package_installer.parse_shlib_depends(output),
                         'libc6 (>= 2.34), libgtk-3-0t64 (>= 3.24)')
        with self.assertRaises(SystemExit):
            package_installer.parse_shlib_depends('shlibs:Depends=\n')

    def test_writes_debian_control_fields(self):
        control = package_installer.debian_control('1.0.0+1', 'libc6 (>= 2.34)', 2048)
        fields = dict(line.split(': ', 1) for line in control.splitlines() if not line.startswith(' '))
        self.assertEqual(fields['Package'], 'qfli-dart-wing')
        self.assertEqual(fields['Version'], '1.0.0+1')
        self.assertEqual(fields['Architecture'], 'amd64')
        self.assertEqual(fields['Installed-Size'], '2048')
        self.assertEqual(fields['Depends'], 'libc6 (>= 2.34)')
        self.assertTrue(control.endswith('\n'))

    def test_desktop_entry_starts_the_launcher(self):
        entry = package_installer.desktop_entry()
        self.assertIn('Exec=qfli-dart-wing\n', entry)
        self.assertIn('Icon=com.azurekiln.qfli.dartwing\n', entry)

    def test_writes_checksum_signing_note_and_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            target = output / 'package.deb'
            target.write_bytes(b'installer')
            application = output / 'application.json'
            application.write_text(json.dumps({'commit': 'abc', 'signing': 'unsigned'}))
            package_installer.write_records(
                output, target, 'linux', '1.0.0+1', application,
                {'format': 'deb', 'installVerified': True})
            digest = package_installer.sha256(target)
            self.assertEqual((output / 'SHA256SUMS').read_bytes(),
                             f'{digest}  package.deb\n'.encode())
            self.assertIn(b'Unsigned Debian package', (output / 'SIGNING.txt').read_bytes())
            record = json.loads((output / 'provenance.json').read_text())
            self.assertEqual(record['commit'], 'abc')
            self.assertEqual(record['installer']['file'], 'package.deb')
            self.assertEqual(record['installer']['sha256'], digest)
            self.assertEqual(record['installer']['applicationVersion'], '1.0.0+1')
            self.assertFalse(record['installer']['applicationUiVerified'])
            self.assertTrue(record['installer']['installVerified'])

    def write_ipa(self, directory, extra=()):
        package = Path(directory) / 'app.ipa'
        info = plistlib.dumps({'CFBundleIdentifier': 'com.example.app',
                               'CFBundleShortVersionString': '1.0.0'}, fmt=plistlib.FMT_BINARY)
        with zipfile.ZipFile(package, 'w') as archive:
            archive.writestr('Payload/Runner.app/Info.plist', info)
            for name in ['Runner', 'Frameworks/App.framework/App',
                         'Frameworks/Flutter.framework/Flutter']:
                archive.writestr('Payload/Runner.app/' + name, b'binary')
            for name in extra:
                archive.writestr(name, b'extra')
        return package

    def test_accepts_an_unsigned_ipa(self):
        with tempfile.TemporaryDirectory() as directory:
            details = package_installer.verify_ios(self.write_ipa(directory))
        self.assertEqual(details['bundleIdentifier'], 'com.example.app')
        self.assertEqual(details['bundleVersion'], '1.0.0')
        self.assertEqual(details['signing'], 'unsigned')
        self.assertFalse(details['installVerified'])

    def test_rejects_an_ipa_with_a_profile_or_stray_entries(self):
        with tempfile.TemporaryDirectory() as directory:
            for extra in ['Payload/Runner.app/embedded.mobileprovision',
                          'Payload/Runner.app/_CodeSignature/CodeResources',
                          'Symbols/Runner.symbols']:
                with self.assertRaises(SystemExit):
                    package_installer.verify_ios(self.write_ipa(directory, [extra]))

    def test_rejects_an_ipa_without_the_flutter_framework(self):
        with tempfile.TemporaryDirectory() as directory:
            package = Path(directory) / 'app.ipa'
            with zipfile.ZipFile(package, 'w') as archive:
                archive.writestr('Payload/Runner.app/Info.plist', plistlib.dumps({}))
                archive.writestr('Payload/Runner.app/Runner', b'binary')
            with self.assertRaises(SystemExit):
                package_installer.verify_ios(package)

    def make_macos_app(self, directory):
        app = Path(directory) / 'QFLIDartWing.app'
        sdk = app / 'Contents/Helpers/dart-sdk/arm64'
        resources = app / 'Contents/Resources/dart-sdk/arm64'
        for relative in ['LICENSE', 'lib/core/core.dart',
                         'bin/snapshots/analysis_server.dart.snapshot']:
            (resources / relative).parent.mkdir(parents=True, exist_ok=True)
            (resources / relative).write_text('resource')
        (sdk / 'bin').mkdir(parents=True)
        for relative in ['LICENSE', 'lib', 'bin/snapshots']:
            self.link(resources / relative, sdk / relative)
        return app, sdk

    def link(self, target, link):
        try:
            os.symlink(os.path.relpath(target, link.parent), link, target_is_directory=target.is_dir())
        except OSError as error:
            self.skipTest(f'Symbolic links are unavailable: {error}')

    def test_accepts_sdk_links_inside_the_application(self):
        with tempfile.TemporaryDirectory() as directory:
            app, _ = self.make_macos_app(directory)
            self.assertEqual(package_installer.check_macos_sdk_links(app, 'arm64'), 3)

    def test_rejects_an_sdk_link_that_leaves_the_application(self):
        with tempfile.TemporaryDirectory() as directory:
            app, sdk = self.make_macos_app(directory)
            outside = Path(directory) / 'outside.txt'
            outside.write_text('outside')
            self.link(outside, sdk / 'escape')
            with self.assertRaises(SystemExit):
                package_installer.check_macos_sdk_links(app, 'arm64')

    def test_rejects_an_sdk_without_resource_links(self):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / 'QFLIDartWing.app'
            (app / 'Contents/Helpers/dart-sdk/arm64').mkdir(parents=True)
            (app / 'Contents/Resources/dart-sdk/arm64').mkdir(parents=True)
            with self.assertRaises(SystemExit):
                package_installer.check_macos_sdk_links(app, 'arm64')


if __name__ == '__main__':
    unittest.main()
