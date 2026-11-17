"""Build and verify installer packages from finished application builds."""

import argparse
import contextlib
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile
import time
import zipfile

ROOT = Path(__file__).resolve().parents[2]
APP_NAME = 'QFLIDartWing'
APP_ID = 'com.azurekiln.qfli.dartwing'
BINARY_NAME = 'qfli_dart'
DEB_PACKAGE = 'qfli-dart-wing'
HOMEPAGE = 'https://github.com/azurekiln2333/qflistudio-dart'
DEFAULT_SOURCES = {
    'windows': 'build/windows/x64/runner/Release',
    'linux': 'build/linux/x64/release/bundle',
}
SIGNING_NOTES = {
    'windows': 'Unsigned test installer. Windows SmartScreen can warn before it starts.',
    'linux': 'Unsigned Debian package. Its dependencies come from the Ubuntu 24.04 build host.',
    'macos': 'Disk image with an ad hoc signed test application. Not notarized or signed for App Store distribution.',
    'ios': 'Unsigned IPA. It requires Apple signing before device installation.',
}


def run(command, **options):
    command = [str(part) for part in command]
    print('+ ' + ' '.join(command), flush=True)
    return subprocess.run(command, check=True, **options)


@contextlib.contextmanager
def workspace():
    directory = tempfile.mkdtemp(prefix='qfli-installer-', dir=os.environ.get('RUNNER_TEMP'))
    try:
        yield directory
    finally:
        shutil.rmtree(directory, ignore_errors=True)


def write_text(path, text):
    # Write bytes: text mode on Windows would store CRLF in the checksum file.
    Path(path).write_bytes(text.encode('utf-8'))


def read_version(pubspec):
    match = re.search(r'^version:\s*(\S+)\s*$', Path(pubspec).read_text(encoding='utf-8'), re.MULTILINE)
    if not match:
        raise SystemExit(f'No application version in {pubspec}')
    return match.group(1)


def windows_file_version(version):
    """Map a pubspec version such as 1.2.3+4 to the numeric form 1.2.3.4."""
    match = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?', version)
    if not match:
        raise SystemExit(f'Application version is not numeric: {version}')
    return '.'.join(part or '0' for part in match.groups())


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def require_files(root, relatives):
    for relative in relatives:
        if not (root / relative).is_file():
            raise SystemExit(f'Incomplete application build: {root / relative}')


def write_records(output, target, platform, version, application_provenance, details):
    """Write the checksum, signing note and provenance beside the installer."""
    digest = sha256(target)
    write_text(output / 'SHA256SUMS', f'{digest}  {target.name}\n')
    write_text(output / 'SIGNING.txt', SIGNING_NOTES[platform] + '\n')
    record = dict(json.loads(Path(application_provenance).read_text(encoding='utf-8')))
    record['installer'] = {
        'file': target.name,
        'sha256': digest,
        'applicationVersion': version,
        'applicationUiVerified': False,
        **details,
    }
    write_text(output / 'provenance.json', json.dumps(record, indent=2) + '\n')
    print(json.dumps(record['installer'], indent=2))


def find_iscc():
    candidates = [shutil.which('ISCC')]
    for variable in ['ProgramFiles(x86)', 'ProgramFiles']:
        if os.environ.get(variable):
            candidates.append(Path(os.environ[variable]) / 'Inno Setup 6' / 'ISCC.exe')
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return Path(candidate)
    raise SystemExit('Inno Setup 6 (ISCC.exe) is not installed on this runner')


def build_windows(source, output, name, version):
    require_files(source, [f'{BINARY_NAME}.exe', 'data/dart-sdk/bin/dart.exe'])
    target = output / f'qfli-dart-{name}-setup.exe'
    # Start ISCC from Python: Git Bash rewrites arguments such as /DName as paths.
    run([
        find_iscc(), '/Q',
        f'/DAppVersion={version}',
        f'/DFileVersion={windows_file_version(version)}',
        f'/DBundleDir={source}',
        f'/DOutputDir={output}',
        f'/DOutputBaseFilename={target.stem}',
        f'/DLicenseFile={ROOT / "LICENSE"}',
        ROOT / 'tool/ci/windows_installer.iss',
    ])
    if not target.is_file():
        raise SystemExit(f'Inno Setup did not write {target}')
    return target


def files_under(root):
    return {path.relative_to(root).as_posix() for path in root.rglob('*') if path.is_file()}


def verify_windows(setup, source):
    """Install silently, compare the file list, run the SDK and uninstall."""
    silent = ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART']
    with workspace() as directory:
        install = Path(directory) / 'app'
        log = Path(directory) / 'install.log'
        try:
            run([setup, *silent, f'/DIR={install}', f'/LOG={log}'], timeout=1800)
        except subprocess.SubprocessError:
            if log.is_file():
                print('\n'.join(log.read_text(errors='replace').splitlines()[-60:]))
            raise
        expected = files_under(source)
        actual = files_under(install)
        added = {'LICENSE.txt', 'unins000.exe', 'unins000.dat'}
        if expected - actual or actual - expected - added:
            raise SystemExit(
                f'Installed files differ: missing {sorted(expected - actual)[:10]}, '
                f'unexpected {sorted(actual - expected - added)[:10]}')
        if not added <= actual:
            raise SystemExit(f'Installer files are missing: {sorted(added - actual)}')
        sdk_version = subprocess.check_output(
            [str(install / 'data/dart-sdk/bin/dart.exe'), '--version'],
            text=True, stderr=subprocess.STDOUT, timeout=120).strip()
        if '"windows_x64"' not in sdk_version:
            raise SystemExit(f'Installed SDK target differs from windows_x64: {sdk_version}')
        run([install / 'unins000.exe', *silent], timeout=1800)
        # The uninstaller continues in a temporary copy of itself.
        deadline = time.monotonic() + 300
        while install.exists() and files_under(install) and time.monotonic() < deadline:
            time.sleep(2)
        if install.exists() and files_under(install):
            raise SystemExit(f'Uninstall left files: {sorted(files_under(install))[:10]}')
    return {
        'format': 'inno-setup',
        'signing': 'unsigned',
        'installedFiles': len(actual),
        'installedSdkVersionOutput': sdk_version,
        'installVerified': True,
        'validation': ['silent-install', 'installed-file-list', 'installed-sdk-version', 'silent-uninstall'],
    }


def parse_shlib_depends(output):
    for line in output.splitlines():
        if line.startswith('shlibs:Depends='):
            depends = line.partition('=')[2].strip()
            if depends:
                return depends
    raise SystemExit(f'dpkg-shlibdeps reported no dependencies: {output!r}')


def shlib_depends(work, application):
    """Compute package dependencies from the ELF files that Flutter built."""
    (work / 'debian').mkdir()
    write_text(work / 'debian/control',
               f'Source: {DEB_PACKAGE}\n\nPackage: {DEB_PACKAGE}\nArchitecture: amd64\n')
    binaries = [application / BINARY_NAME, *sorted((application / 'lib').glob('*.so'))]
    output = subprocess.check_output(
        ['dpkg-shlibdeps', '-O', '--ignore-missing-info', f'-l{application / "lib"}',
         *[f'-e{binary}' for binary in binaries]],
        cwd=work, text=True)
    return parse_shlib_depends(output)


def debian_control(version, depends, installed_kib):
    return (
        f'Package: {DEB_PACKAGE}\n'
        f'Version: {version}\n'
        'Architecture: amd64\n'
        'Maintainer: AzureKiln <azurekiln2333@users.noreply.github.com>\n'
        f'Installed-Size: {installed_kib}\n'
        f'Depends: {depends}\n'
        'Section: devel\n'
        'Priority: optional\n'
        f'Homepage: {HOMEPAGE}\n'
        f'Description: {APP_NAME} offline Dart IDE\n'
        ' Dart editor, terminal and tutorials.\n'
        ' The package includes the Dart SDK that runs and compiles programs.\n'
    )


def desktop_entry():
    return (
        '[Desktop Entry]\n'
        'Type=Application\n'
        f'Name={APP_NAME}\n'
        'Comment=Offline Dart IDE\n'
        f'Exec={DEB_PACKAGE}\n'
        f'Icon={APP_ID}\n'
        'Terminal=false\n'
        'Categories=Development;IDE;\n'
    )


def build_linux(source, output, name, version):
    require_files(source, [BINARY_NAME, 'data/dart-sdk/bin/dart'])
    target = output / f'qfli-dart-{name}.deb'
    with workspace() as directory:
        work = Path(directory)
        root = work / 'root'
        # The application finds data/dart-sdk beside its resolved executable.
        application = root / 'opt' / DEB_PACKAGE
        shutil.copytree(source, application, symlinks=True)
        launcher = root / 'usr/bin' / DEB_PACKAGE
        launcher.parent.mkdir(parents=True)
        launcher.symlink_to(f'../../opt/{DEB_PACKAGE}/{BINARY_NAME}')
        entry = root / 'usr/share/applications' / f'{APP_ID}.desktop'
        entry.parent.mkdir(parents=True)
        write_text(entry, desktop_entry())
        icon = root / 'usr/share/pixmaps' / f'{APP_ID}.png'
        icon.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / 'assets/app_icon.png', icon)
        copyright_file = root / 'usr/share/doc' / DEB_PACKAGE / 'copyright'
        copyright_file.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / 'LICENSE', copyright_file)
        depends = shlib_depends(work, application)
        size = sum(path.lstat().st_size for path in root.rglob('*') if not path.is_dir())
        for path in [root, *root.rglob('*')]:
            if path.is_dir() and not path.is_symlink():
                path.chmod(0o755)
        (root / 'DEBIAN').mkdir(mode=0o755)
        write_text(root / 'DEBIAN/control', debian_control(version, depends, -(-size // 1024)))
        run(['dpkg-deb', '--root-owner-group', '-Zxz', '--build', root, target])
    return target, depends


def verify_linux(package, version, depends):
    """Install through apt, run the installed SDK and remove the package."""
    fields = subprocess.check_output(
        ['dpkg-deb', '--field', str(package), 'Package', 'Version', 'Architecture'], text=True)
    if fields.split() != ['Package:', DEB_PACKAGE, 'Version:', version, 'Architecture:', 'amd64']:
        raise SystemExit(f'Unexpected package fields: {fields!r}')
    application = Path('/opt') / DEB_PACKAGE
    run(['sudo', 'apt-get', 'install', '-y', '--no-install-recommends', package.resolve()])
    try:
        launcher = Path('/usr/bin') / DEB_PACKAGE
        if launcher.resolve(strict=True) != application / BINARY_NAME:
            raise SystemExit(f'Launcher resolves to {launcher.resolve()}')
        for installed in [f'/usr/share/applications/{APP_ID}.desktop', f'/usr/share/pixmaps/{APP_ID}.png']:
            if not Path(installed).is_file():
                raise SystemExit(f'Package did not install {installed}')
        libraries = subprocess.check_output(['ldd', str(application / BINARY_NAME)], text=True)
        if 'not found' in libraries:
            raise SystemExit(f'Installed application has unresolved libraries:\n{libraries}')
        sdk_version = subprocess.check_output(
            [str(application / 'data/dart-sdk/bin/dart'), '--version'],
            text=True, stderr=subprocess.STDOUT, timeout=120).strip()
        if '"linux_x64"' not in sdk_version:
            raise SystemExit(f'Installed SDK target differs from linux_x64: {sdk_version}')
    finally:
        run(['sudo', 'apt-get', 'remove', '-y', DEB_PACKAGE])
    if application.exists():
        raise SystemExit(f'Package removal left {application}')
    return {
        'format': 'deb',
        'signing': 'unsigned',
        'depends': depends,
        'installedSdkVersionOutput': sdk_version,
        'installVerified': True,
        'validation': ['package-fields', 'apt-install', 'launcher-link', 'shared-library-resolution',
                       'installed-sdk-version', 'apt-remove'],
    }


def check_macos_sdk_links(app, arch):
    """Check that SDK resource links resolve inside a relocated application."""
    app = Path(app).resolve(strict=True)
    sdk = app / 'Contents/Helpers/dart-sdk' / arch
    resources = app / 'Contents/Resources/dart-sdk' / arch
    links = [path for root in (sdk, resources) for path in root.rglob('*') if path.is_symlink()]
    if not links:
        raise SystemExit('The relocated SDK has no resource links')
    for link in links:
        if os.path.isabs(os.readlink(link)) or not link.resolve(strict=True).is_relative_to(app):
            raise SystemExit(f'SDK link escapes the relocated application: {link}')
    for relative in ['LICENSE', 'lib/core/core.dart', 'bin/snapshots/analysis_server.dart.snapshot']:
        entry = sdk / relative
        if not entry.is_file() or entry.resolve() != (resources / relative).resolve():
            raise SystemExit(f'SDK resource lookup failed after relocation: {relative}')
    print(f'Validated {len(links)} SDK links in {app}')
    return len(links)


def build_macos(app, output, arch):
    if not (app / 'Contents/MacOS' / APP_NAME).is_file():
        raise SystemExit(f'Incomplete application build: {app}')
    target = output / f'{APP_NAME}-macos-{arch}.dmg'
    with workspace() as directory:
        staging = Path(directory) / 'image'
        staging.mkdir()
        run(['ditto', app, staging / app.name])
        (staging / 'Applications').symlink_to('/Applications')
        # Hosted runners intermittently report "Resource busy" during creation.
        for attempt in range(1, 4):
            try:
                run(['hdiutil', 'create', '-volname', APP_NAME, '-srcfolder', staging,
                     '-fs', 'HFS+', '-format', 'UDZO', '-ov', target])
                break
            except subprocess.CalledProcessError:
                if attempt == 3:
                    raise
                time.sleep(15 * attempt)
    return target


def verify_macos(image, arch):
    """Mount the image read-only and verify the application inside it."""
    run(['hdiutil', 'verify', image])
    with workspace() as directory:
        mount = Path(directory) / 'mount'
        mount.mkdir()
        run(['hdiutil', 'attach', image, '-readonly', '-nobrowse', '-mountpoint', mount])
        try:
            app = mount / f'{APP_NAME}.app'
            if os.readlink(mount / 'Applications') != '/Applications':
                raise SystemExit('The image has no /Applications link')
            run(['lipo', app / 'Contents/MacOS' / APP_NAME, '-verify_arch',
                 {'arm64': 'arm64', 'x64': 'x86_64'}[arch]])
            run(['codesign', '--verify', '--deep', '--strict', '--verbose=2', app])
            links = check_macos_sdk_links(app, arch)
        finally:
            for attempt in range(1, 4):
                try:
                    run(['hdiutil', 'detach', mount, *(['-force'] if attempt == 3 else [])])
                    break
                except subprocess.CalledProcessError:
                    if attempt == 3:
                        raise
                    time.sleep(5)
    return {
        'format': 'dmg',
        'signing': 'ad hoc',
        'notarized': False,
        'sdkLinks': links,
        'installVerified': False,
        'validation': ['image-checksum', 'mounted-application-architecture',
                       'mounted-codesign-verification', 'mounted-sdk-resource-links'],
    }


def build_ios(archive, output):
    app = archive / 'Products/Applications/Runner.app'
    require_files(app, ['Info.plist', 'Runner'])
    target = output / f'{APP_NAME}-ios-arm64-unsigned.ipa'
    with workspace() as directory:
        payload = Path(directory) / 'Payload'
        payload.mkdir()
        run(['ditto', app, payload / app.name])
        target.unlink(missing_ok=True)
        run(['zip', '-qry', target, 'Payload'], cwd=directory)
    return target


def verify_ios(package):
    """Read the IPA back and confirm its layout and unsigned state."""
    prefix = 'Payload/Runner.app/'
    with zipfile.ZipFile(package) as archive:
        names = set(archive.namelist())
        if {name.split('/')[0] for name in names} != {'Payload'}:
            raise SystemExit('The IPA has entries outside Payload')
        for required in ['Info.plist', 'Runner', 'Frameworks/App.framework/App',
                         'Frameworks/Flutter.framework/Flutter']:
            if prefix + required not in names:
                raise SystemExit(f'The IPA lacks {required}')
        for signed in ['embedded.mobileprovision', '_CodeSignature/CodeResources']:
            if prefix + signed in names:
                raise SystemExit(f'The IPA is labelled unsigned but contains {signed}')
        info = plistlib.loads(archive.read(prefix + 'Info.plist'))
    return {
        'format': 'ipa',
        'signing': 'unsigned',
        'bundleIdentifier': info.get('CFBundleIdentifier'),
        'bundleVersion': info.get('CFBundleShortVersionString'),
        'installVerified': False,
        'deviceRuntimeVerified': False,
        'validation': ['payload-layout', 'application-executable', 'app-framework',
                       'flutter-framework', 'no-signature-or-profile'],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    for platform in ['windows', 'linux']:
        command = commands.add_parser(platform)
        command.add_argument('--source', type=Path, default=Path(DEFAULT_SOURCES[platform]))
        command.add_argument('--name', required=True)
    macos = commands.add_parser('macos')
    macos.add_argument('--app', required=True, type=Path)
    macos.add_argument('--arch', required=True, choices=['arm64', 'x64'])
    ios = commands.add_parser('ios')
    ios.add_argument('--archive', required=True, type=Path)
    for command in [commands.choices[name] for name in ['windows', 'linux', 'macos', 'ios']]:
        command.add_argument('--output', required=True, type=Path)
        command.add_argument('--provenance', type=Path, default=Path('dist/app/provenance.json'))
    links = commands.add_parser('check-macos-sdk-links')
    links.add_argument('--app', required=True, type=Path)
    links.add_argument('--arch', required=True, choices=['arm64', 'x64'])
    args = parser.parse_args()
    if args.command == 'check-macos-sdk-links':
        check_macos_sdk_links(args.app, args.arch)
        return
    if not args.provenance.is_file():
        raise SystemExit(f'Application provenance is missing: {args.provenance}')
    version = read_version(ROOT / 'pubspec.yaml')
    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output.resolve()
    if args.command == 'windows':
        source = args.source.resolve(strict=True)
        target = build_windows(source, output, args.name, version)
        details = verify_windows(target, source)
    elif args.command == 'linux':
        target, depends = build_linux(args.source.resolve(strict=True), output, args.name, version)
        details = verify_linux(target, version, depends)
    elif args.command == 'macos':
        target = build_macos(args.app.resolve(strict=True), output, args.arch)
        details = verify_macos(target, args.arch)
    else:
        target = build_ios(args.archive.resolve(strict=True), output)
        details = verify_ios(target)
    write_records(output, target, args.command, version, args.provenance, details)


if __name__ == '__main__':
    main()
