# GitHub 构建与下载

默认分支是 `main`。
工作流分别导出原生依赖和完整应用。
每份产物附带来源记录和 SHA256。

## 构建状态

以下记录来自 2026 年 11 月 17 日的试构建。
六个平台均已完成。
八种平台与架构组合共导出 16 份产物。

| 平台 | 原生依赖 | 完整应用 | 状态 |
| --- | --- | --- | --- |
| Android ARM64 | [native-android-arm64-v8a](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43922631253/artifacts/14255300791) | [app-android-arm64-v8a](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14261922032) | 两项成功 |
| Android x86_64 | [native-android-x86_64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43922631253/artifacts/14253868977) | [app-android-x86_64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14262206372) | 两项成功 |
| Windows x64 | [native-windows-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14261461227) | [app-windows-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14261441637) | 两项成功 |
| Linux x64 | [native-linux-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14260781767) | [app-linux-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14262651489) | 两项成功 |
| macOS ARM64 | [native-macos-arm64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702/artifacts/14291671596) | [app-macos-arm64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702/artifacts/14290809979) | 两项成功 |
| macOS x64 | [native-macos-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702/artifacts/14291557777) | [app-macos-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702/artifacts/14291443933) | 两项成功 |
| iOS ARM64 | [native-ios-arm64-frameworks](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702/artifacts/14291273590) | [app-ios-arm64-unsigned-xcarchive](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702/artifacts/14291881728) | 两项成功 |
| OHOS ARM64 | [native-ohos-arm64-libraries](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43943142540/artifacts/14263248969) | [app-ohos-arm64-unsigned](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43943142540/artifacts/14264177854) | 两项成功 |

构建与下载入口：

- [Android 原生 SDK](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43922631253)
- [Android、Windows、Linux 应用](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780)
- [macOS 与 iOS 构建](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43999548702)
- [OHOS 构建](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43943142540)

## 下载方法

1. 登录 GitHub。
2. 打开上面的运行记录。
3. 滚动到 **Artifacts**。
4. 下载对应平台的 ZIP。

GitHub 下载的是外层 ZIP。
应用安装包或内层归档位于其中。
原生依赖、应用和安装包产物保留 30 天。
`intermediates-*` 中间归档保留 3 天。
中间归档用于排查构建问题。
运行摘要也提供下载链接。
过期后须重新运行构建。

## 产物内容

| 平台 | 原生依赖内容 | 应用内容与用法 |
| --- | --- | --- |
| Android | VM、SDK 程序、数据 ZIP、安装清单 | APK 使用测试密钥签名。按设备架构选择。 |
| Windows | 完整 Dart SDK ZIP | 解压应用 ZIP，再运行其中的 EXE。须保留同目录 DLL 和 data。 |
| Linux | 完整 Dart SDK tar.gz | 解压内层 tar.gz，再运行应用。须保留 lib 和 data。 |
| macOS | 对应架构的完整 Dart SDK tar.gz | tar.gz 内含完整 .app。采用临时签名，未公证。 |
| iOS | Flutter、应用和插件的 Framework | 未签名 .xcarchive。须通过 Xcode 签名后导出 IPA。 |
| OHOS | HAP 中的 ARM64 原生库 | 未签名 HAP 和 APP。安装前须签名。 |

桌面应用已经包含 Dart SDK。
只运行应用时，无须另下载原生依赖。
原生依赖包供开发和重新打包使用。
iOS 与 OHOS 的原生库包不是独立 Dart SDK。
这两个平台使用项目的便携解释器。

Linux 和 macOS 的内层归档保留 Unix 文件权限。
请解压内层 tar.gz 后运行。
Windows 应用 ZIP 是完整目录，不是安装程序。
Windows 安装程序见下文“安装包”。
iOS 归档不能直接安装到手机。
构建成功不代表通过真机验收。

Linux CI 的静态分析通过。
221 个主机测试通过。
标准 Flutter 跳过 3 个 OHOS 专用测试。
桌面 SDK 通过 Kernel 编译和文件读写验证。
验证时先删除源码，再运行 Kernel 文件。
两种 macOS 架构均通过应用签名校验。
归档解压后也通过签名和 SDK 链接校验。
应用沙盒内的 SDK 运行仍待验证。

## 安装包

安装包工作流随源码保存在仓库。
工作流先上传应用产物，再构建安装包。
每个安装包作为独立产物上传。
安装包失败不影响已上传的应用产物。
安装包版本取自 `pubspec.yaml`。

<!-- installer-run-links -->

以下安装包来自 2026 年 11 月 26 日的云端构建。
分支为 `ci/installer-packages`。
应用提交为：

```text
70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe
```

- [应用运行 45807875409](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875409)：第 2 次尝试成功。
- [Apple 运行 45807875426](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875426)：第 1 次尝试成功。

五份安装包产物均已上传。
API 记录的到期日均为 2026 年 12 月 26 日（UTC）。
以下链接对应上述提交，不代表后续源码已通过验证。

| 平台 | 安装包下载 | 产物 ID |
| --- | --- | --- |
| Windows x64 | [installer-windows-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875409/artifacts/15109934015) | `15109934015` |
| Linux x64 | [installer-linux-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875409/artifacts/15110409280) | `15110409280` |
| macOS ARM64 | [installer-macos-arm64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875426/artifacts/15109934492) | `15109934492` |
| macOS x64 | [installer-macos-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875426/artifacts/15112630861) | `15112630861` |
| iOS ARM64 | [installer-ios-arm64-unsigned](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/45807875426/artifacts/15110258334) | `15110258334` |

这两次运行尚未包含新版云端校验和中间归档步骤。

| 平台 | 产物 | 文件 | 格式 |
| --- | --- | --- | --- |
| Windows x64 | `installer-windows-x64` | `qfli-dart-windows-x64-setup.exe` | Inno Setup 安装程序 |
| Linux x64 | `installer-linux-x64` | `qfli-dart-linux-x64.deb` | Debian 软件包 |
| macOS ARM64 | `installer-macos-arm64` | `QFLIDartWing-macos-arm64.dmg` | UDZO 磁盘映像 |
| macOS x64 | `installer-macos-x64` | `QFLIDartWing-macos-x64.dmg` | UDZO 磁盘映像 |
| iOS ARM64 | `installer-ios-arm64-unsigned` | `QFLIDartWing-ios-arm64-unsigned.ipa` | 未签名 IPA |
| Android | `app-android-<abi>` | `qfli-dart-android-<abi>-test-signed.apk` | 测试签名 APK |
| OHOS ARM64 | `app-ohos-arm64-unsigned` | HAP 和 APP | 未签名 HAP 和 APP |

Android 和 OHOS 沿用现有应用产物。
这两个平台没有新增产物。

每份 `installer-` 产物还包含三个文件：

- `SHA256SUMS` 记录安装包的 SHA256。
- `SIGNING.txt` 说明签名状态。
- `provenance.json` 是来源记录。

`provenance.json` 保留应用产物的来源字段。
它新增 `installer` 对象。
该对象包含以下字段：

```text
file
sha256
applicationVersion
format
signing
installVerified
validation
```

### 安装包验证

工作流在上传前验证每个安装包。

| 平台 | 验证步骤 |
| --- | --- |
| Windows x64 | 静默安装。比对已安装的文件清单。运行已安装的 `dart.exe --version`。静默卸载。 |
| Linux x64 | 用 apt 安装。校验启动链接和共享库。运行已安装的 SDK。删除软件包。 |
| macOS | 校验磁盘映像。只读挂载磁盘映像。校验应用架构、签名和 SDK 链接。 |
| iOS ARM64 | 校验 Payload 结构。确认应用主程序和 Framework 文件存在。确认包内没有签名资源和描述文件。 |

这些验证不启动应用窗口。
`installVerified` 仅在 Windows 和 Linux 为 `true`。
工作流不运行磁盘映像内的应用。
iOS 步骤仅确认包内没有签名资源和描述文件。
该步骤未校验 Mach-O 内嵌签名。
工作流不做 iOS 真机测试。

### 安装方法

Windows：

1. 运行 `qfli-dart-windows-x64-setup.exe`。
2. 按安装程序的提示完成安装。

安装程序未签名。
SmartScreen 可能在启动前显示警告。
安装程序默认为当前用户安装。
此方式无须管理员权限。
在系统的应用列表中卸载。

Linux：

```bash
sudo apt install ./qfli-dart-linux-x64.deb
sudo apt remove qfli-dart-wing
```

第一条命令安装软件包。
第二条命令删除软件包。
软件包名是 `qfli-dart-wing`。
应用位于 `/opt/qfli-dart-wing`。
启动命令是 `/usr/bin/qfli-dart-wing`。
软件包附带桌面入口和图标。
`dpkg-shlibdeps` 在 Ubuntu 24.04 上计算依赖。
工作流只在 Ubuntu 24.04 上验证安装。

macOS：

1. 按处理器架构选择磁盘映像。
2. 打开磁盘映像。
3. 把 QFLIDartWing 拖到 Applications。

磁盘映像内含 `/Applications` 链接。
应用采用临时签名，未公证。
Gatekeeper 可能阻止首次打开。

iOS：

1. 用 Apple 证书和描述文件给 IPA 签名。
2. 把已签名的 IPA 安装到设备。

未签名 IPA 不能直接安装到手机。

Android：

1. 按设备架构选择 APK。
2. 在设备上安装 APK。

APK 使用测试密钥签名。

OHOS：

1. 用华为证书和 Profile 给 HAP 或 APP 签名。
2. 把已签名的包安装到设备。

### 签名限制

本仓库没有签名凭据。
以下安装包需要仓库机密中的签名凭据：

- 已签名的 Windows 安装程序需要代码签名证书。
- 已公证的 macOS 磁盘映像需要 Developer ID 证书和公证凭据。
- 可安装的 iOS IPA 需要 Apple 证书和描述文件。
- 可安装的 OHOS 包需要华为证书和 Profile。

工作流不上传本地签名材料。
添加签名凭据须由仓库所有者决定。

## 工作流

本机禁止构建、测试和静态分析。
本机禁止安装依赖和下载构建产物。
所有验证都在 GitHub Actions 执行。
迁移步骤见 `WORKSPACE_MIGRATION.zh-CN.md`。

| 工作流 | 作用 |
| --- | --- |
| `Android native SDK` | 打包锁定的 Android SDK |
| `Android Windows Linux applications` | 构建三个平台的应用，导出桌面 SDK 和桌面安装包 |
| `Apple applications and native dependencies` | 构建 macOS、iOS 应用，导出原生依赖和安装包 |
| `OHOS application and native libraries` | 构建 OHOS HAP、APP，导出原生库 |
| `Cloud source and tooling checks` | 校验语法、跟踪文件和 Trellis 清单。运行 Python 测试。校验受控中文规则。 |

推送对应源码或工作流改动可触发构建。
工作流进入默认分支后，可在网页手动启动。
入口是 **Actions → Run workflow**。

OHOS 工作流校验工具包的 SHA256。
它从 CI 副本中删除本地签名配置。
它使用锁定版本的 Flutter OHOS。
默认工具包版本为 `26.0.0.821`。
下载地址来自华为官方 CDN。
工具包包含 API 26 SDK。
项目的目标 API 保持为 24。
此组合已通过 GitHub 构建和包结构校验。
锁文件位于 `tool/ci/ohos-command-line-tools.lock.json`。
下载或校验失败时，工作流会明确失败。
可用以下配置覆盖默认工具包：

```text
OHOS_COMMAND_LINE_TOOLS_URL
OHOS_COMMAND_LINE_TOOLS_SHA256
```

它们接受仓库变量或手动运行输入。
覆盖时须同时提供地址和 SHA256。
下载地址须指向完整 Linux x64 工具包。
官网介绍页面不能作为下载地址。

标准平台固定 Flutter 3.41.9。
共享核心固定到同一提交。
CI 仅在临时核心副本中应用兼容补丁。
补丁适配标准 Flutter 的平台定义。
OHOS 构建使用未经此补丁修改的核心。

## 本地空间

2026-11-26 盘点了 26 个候选目录。
文件逻辑长度合计 8,602,909,272 字节（约 8.012 GiB）。
该数值不代表磁盘实际占用或可回收空间。

| 目录 | 逻辑字节 | 处理说明 |
| --- | ---: | --- |
| `build/` | 6,465,525,036 | 保留嵌套仓库、审计和发布证据 |
| `.dart_tool/` | 1,091,755,810 | 依赖缓存，交接后再清理 |
| `native/build/` | 584,434,321 | 先保留 SDK 输入和原生文件 |
| `ohos/entry/build/` | 249,678,423 | 构建中间文件 |
| `ohos/build/` | 94,216,372 | 构建中间文件 |
| `ohos/oh_modules/` | 80,363,408 | 依赖缓存，不跟随目录链接清理 |

`build/` 混有源码、审计、发布和签名证据。
不要删除整个 `build/` 目录。

Core 临时克隆的九文件修改已与补丁核对。
两份克隆当前仍保留在原目录。
原生 SDK 输入和签名材料也继续保留。
完整清理清单见 Trellis 迁移任务中的 `cleanup-audit.md`。

云端构建不会自动清理本地文件。
请勿下载中间产物到工作区。

Android SDK 的恢复路径和输入归档见：
[Android 原生构建说明](native/dart-sdk/android/GITHUB_BUILD.zh-CN.md)。
