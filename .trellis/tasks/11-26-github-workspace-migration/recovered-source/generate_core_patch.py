from pathlib import Path
import subprocess
import difflib

repo = Path(r'D:/MyNewProjects/qfli_studio_core')
out = Path(r'D:/MyNewProjects/qfli_dart/build/stock-core-patch-validation')
out.mkdir(exist_ok=True)
revision = '573d1b6eecf1c2b392ad753264a5a09f62f8335e'
files = [
    'lib/config/client_platform.dart',
    'lib/interop/interop_transport.dart',
    'lib/pages/auth/agreement_page.dart',
    'lib/pages/auth/huawei_quick_login_view.dart',
    'lib/pages/auth/login_page.dart',
    'lib/services/app_private_roots.dart',
    'lib/terminal/shell/local_shell_io.dart',
    'lib/terminal/widgets/terminal_input.dart',
    'vendor/re_editor/lib/src/_consts.dart',
]
original = {}
for name in files:
    source = subprocess.check_output(['git', '-C', str(repo), 'show', f'{revision}:{name}']).decode('utf-8')
    original[name] = source
    path = out / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(source, encoding='utf-8', newline='')

def replace(name, old, new):
    path = out / name
    source = path.read_text(encoding='utf-8')
    assert source.count(old) == 1, (name, old, source.count(old))
    path.write_text(source.replace(old, new), encoding='utf-8', newline='')

replace(files[0], '''  /// 运行时平台映射。[TargetPlatform.ohos] 是 Flutter 鸿蒙分支的枚举值。
  static String fromTargetPlatform(TargetPlatform target) => switch (target) {
    TargetPlatform.ohos => 'harmonyos',
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.windows => 'windows',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'linux',
  };''', '''  /// Map platform names without depending on the OHOS-only enum member.
  static String fromTargetPlatform(TargetPlatform target) => switch (target.name) {
    'ohos' => 'harmonyos',
    'android' => 'android',
    'iOS' => 'ios',
    'windows' => 'windows',
    'macOS' => 'macos',
    'linux' || 'fuchsia' => 'linux',
    _ => 'linux',
  };''')
replace(files[1], '''  static const Set<TargetPlatform> _supported = <TargetPlatform>{
    TargetPlatform.ohos,
  };''', "  static const Set<String> _supported = <String>{'ohos'};")
replace(files[1], '_supported.contains(defaultTargetPlatform)', '_supported.contains(defaultTargetPlatform.name)')
replace(files[2], 'defaultTargetPlatform != TargetPlatform.ohos', "defaultTargetPlatform.name != 'ohos'")
replace(files[4], 'defaultTargetPlatform == TargetPlatform.ohos', "defaultTargetPlatform.name == 'ohos'")
replace(files[5], '''    final mobile = switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.ohos ||
      TargetPlatform.iOS => true,
      _ => false,
    };''', '''    final mobile = switch (defaultTargetPlatform.name) {
      'android' || 'ohos' || 'iOS' => true,
      _ => false,
    };''')
replace(files[6], '''  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {''', '''  if (kIsWeb || defaultTargetPlatform.name == 'ohos') return false;
  switch (defaultTargetPlatform) {''')
replace(files[6], '''    // HarmonyOS: the shell at /bin/sh or /system/bin/sh usually exists but the
    // app is not permitted to exec it, so this is a no as well.
    case TargetPlatform.ohos:
''', '')
replace(files[7], 'defaultTargetPlatform == TargetPlatform.ohos', "defaultTargetPlatform.name == 'ohos'")
replace(files[8], 'defaultTargetPlatform == TargetPlatform.ohos', "defaultTargetPlatform.name == 'ohos'")
(out / files[3]).write_text('''import 'package:flutter/material.dart';

/// Standard Flutter has no HarmonyOS platform view implementation.
/// The login page hides this view outside OHOS. The OHOS build uses the
/// original core source and must never apply this CI compatibility patch.
class HuaweiQuickLoginView extends StatelessWidget {
  const HuaweiQuickLoginView({
    super.key,
    required this.agreementAccepted,
    required this.onAuthorizationCode,
    required this.onError,
  });

  final bool agreementAccepted;
  final ValueChanged<String> onAuthorizationCode;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) =>
      const Text('当前平台不支持华为一键登录');
}
''', encoding='utf-8', newline='')
parts = []
for name in files:
    updated = (out / name).read_text(encoding='utf-8')
    previous = original[name].replace('\r\n', '\n')
    if previous == updated:
        continue
    parts.append(f'diff --git a/{name} b/{name}\n')
    parts.extend(difflib.unified_diff(previous.splitlines(keepends=True), updated.splitlines(keepends=True), fromfile=f'a/{name}', tofile=f'b/{name}'))
Path(r'D:/MyNewProjects/qfli_dart/tool/ci/stock-flutter-core.patch').write_text(''.join(parts), encoding='utf-8', newline='')
print(out)
