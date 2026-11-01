# qfli_dart

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

本仓库是一个独立的 Flutter 应用。
产品名是 QFLIDartWing。
它把 Dart 编辑器、工具页、终端和课程装进一个应用。
应用离线工作。
它不打开外部网页。
Android 主清单不申请联网权限。
调试清单和性能清单申请联网权限。
OHOS 清单只申请读取剪贴板权限。
编辑器、终端和文件树来自同级包 qfli_studio_core。

## 运行后端

Android 和桌面用官方 Dart SDK。
Android 打包官方 SDK 的 arm64-v8a 与 x86_64 版本。
OHOS 的 HAP 不带官方 SDK。
OHOS 用内置的便携解释器。
便携解释器是 vendor/tom_d4rt。
版本是 1.229.0+qfli.1。
它保留上游 MIT 许可证。
dart_eval 0.8.5 只保留给旧的 EVC 编译动作。
便携解释器不是完整的 Dart VM。
它支持一部分语言和库。
它拒绝联网、原生进程、标准输入和符号链接遍历。
它只读预加载的项目源码。
它允许项目和临时目录的文件读写。

## 课程内容

已发布资产含 120 课和 120 个配对示例。
课程分 14 章，编号 001 到 120。
每课有讲解、目标、代码、输出和练习。
另有 180 组草稿，编号 121 到 300。
草稿放在 16 个章节文件里。
草稿尚未进入发布资产。
发布聚合与资产保持 120/120。
原有 OHOS 验收是草稿提升的必经门槛。
草稿只在主机上验证过。
主机验证含官方 SDK 运行和便携运行。
编号 181 到 238 的 58 项练习已在主机复跑。
官方 SDK 和便携运行均通过。
草稿没有 OHOS 设备证据。

## 证据边界

主机 SDK 运行、主机便携运行、OHOS 打包和真机运行是四道独立门槛。
主机测试通过，不代表设备运行通过。
Windows AOT 结果只证明主机。
它不证明 OHOS。
当前没有 Dart 的 OHOS 设备验收。
共享 x64 模拟器已存在。
Dart 尚未获得 OHOS 设备时段。
Dart 未安装 OHOS 应用。
Dart 未启动 OHOS 应用。
Dart 未停止 OHOS 应用。
Android 原生 SDK 在 API 37 x86_64 模拟器上通过九项验证。
该验证使用 16 KiB 页。
ARM64 应用运行仍需真机。
发布 HAP 和 APP 时指定 arm64-v8a。
另有一份 x86_64 审计 HAP。
它由 `tool/ohos/build_dart_audit.ps1` 生成。
它只供主机打包检查。
它不是发布包。
它不算设备证据。
原生离线守卫只在主机通道测试中验证。
现有审计包早于原生离线守卫。
没有 HDC 目标时，设备证据为空。

## 支持范围与限制

工具页提供格式化、语法诊断、运行、编译和源码结构。
格式化用 dart_style。
工具页和终端 `dart analyze` 都只做语法诊断。
语法诊断只做扫描与解析。
它不做类型、lint 或依赖分析。
干净结果不代表类型正确。
缺少输入时它返回不可用原因。
它不返回虚假的干净结果。
OHOS 便携目标没有官方 SDK。
终端 `dart compile kernel` 返回不可用原因。
编译在 Android 和桌面产出 Kernel `.dill`。
旧的 EVC 动作产出 dart_eval 字节码。
终端支持 dart run、format、analyze 和 compile kernel。
终端拒绝 pub get 和全局安装。
应用没有断点调试。
它没有单步和变量查看 API。
打印日志不等于断点调试。
应用不支持联网和端口功能。
不支持的能力会明确失败。

## 同级仓库与依赖

本仓库依赖同级包 qfli_studio_core。
先把它检出到本仓库旁边。

```text
checkout-parent/
  qfli_studio_core/
  qfli_dart/
```

然后在本仓库运行 flutter pub get。
编辑器补丁来自 ../qfli_studio_core/vendor/re_editor。
pubspec.yaml 用路径覆盖指向它。

## 开发与测试

生成内容资产。

```powershell
dart run tool/build_dart_content.dart
```

用官方 SDK 验证全部课程。

```powershell
dart run tool/verify_dart_content.dart
```

验证引擎说明是否齐全。

```powershell
dart run tool/audit_compat.dart
```

用便携解释器验证全部课程。

```powershell
dart run tool/verify_portable_content.dart --report portable-report.json
```

跑静态分析和测试。

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

跑原生离线通道测试。
它覆盖离线拒绝和本地能力两组。

```powershell
node --max-old-space-size=128 --test test/native_entry_ability_test.cjs
```

自查中文文档。

```powershell
python scripts/ste-lint-zh.py README.md README.zh-Hant.md
```

## 构建

Android 构建前先铺 SDK。
替换两个 SDK 目录。

```powershell
./native/dart-sdk/android/stage.ps1 -Abi arm64-v8a -Sdk '<SDK_ARM64_DIR>'
./native/dart-sdk/android/stage.ps1 -Abi x86_64 -Sdk '<SDK_X64_DIR>'
```

构建 arm64 APK。

```powershell
flutter build apk --release --target-platform android-arm64 --no-pub
```

Android release 目前用调试密钥签名。
发布前请配置商店签名密钥。

构建 OHOS HAP。

```powershell
flutter build hap --release --target-platform ohos-arm64 --no-pub
```

构建 OHOS APP。

```powershell
flutter build app --release --target-platform ohos-arm64 --no-pub
```

签名 HAP 在 `build/ohos/hap/entry-default-signed.hap`。
签名 APP 在 `build/ohos/app/ohos-default-signed.app`。
没有签名材料时加 `--no-codesign`。

## 签名与隐私

私钥、证书和口令只留在本机。
不要把它们提交到仓库。
在本机配置 OHOS 发布签名。
将本机发布签名配置命名为 `releaseKey`。
从 `ohos/AppScope/app.json5` 读取 bundle 名。
签名配置必须授权该 bundle。
证书必须与签名者一致。
打包、签名和真机运行分开验收。
文件名带 signed 不代表商店签名。
用 hap-sign-tool 验证签名和 profile。

```powershell
tool/ohos/verify_dart_hap.ps1 -HapPath <hap>
```

## 待办证据

原有 OHOS 打包与真机验收仍开放。
180 组草稿的提升仍开放。
全量 300 组内容验证仍开放。
共享核心的最终修订仍待评审。

## 第三方许可证

内置 tom_d4rt 用 MIT。
许可证保留在 `vendor/tom_d4rt/LICENSE`。
