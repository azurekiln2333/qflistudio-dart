# GitHub 构建与下载

工作分支是 `ci/native-android-sdk`。
工作流分别导出原生依赖和完整应用。
每份产物附带来源记录和 SHA256。

## 构建状态

以下记录来自 2026 年 11 月 17 日的试构建。

| 平台 | 原生依赖 | 完整应用 | 状态 |
| --- | --- | --- | --- |
| Android ARM64 | [native-android-arm64-v8a](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43922631253/artifacts/14255300791) | [app-android-arm64-v8a](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14261922032) | 两项成功 |
| Android x86_64 | [native-android-x86_64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43922631253/artifacts/14253868977) | [app-android-x86_64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14262206372) | 两项成功 |
| Windows x64 | [native-windows-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14261461227) | [app-windows-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14261441637) | 两项成功 |
| Linux x64 | [native-linux-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14260781767) | [app-linux-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780/artifacts/14262651489) | 两项成功 |
| macOS ARM64 | `native-macos-arm64` | `app-macos-arm64` | 构建中 |
| macOS x64 | [native-macos-x64](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43940734490/artifacts/14264831464) | `app-macos-x64` | SDK 成功，应用重新构建中 |
| iOS ARM64 | [native-ios-arm64-frameworks](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43940734490/artifacts/14264106077) | [app-ios-arm64-unsigned-xcarchive](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43940734490/artifacts/14264670782) | 两项成功 |
| OHOS ARM64 | [native-ohos-arm64-libraries](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43943142540/artifacts/14263248969) | [app-ohos-arm64-unsigned](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43943142540/artifacts/14264177854) | 两项成功 |

构建与下载入口：

- [Android 原生 SDK](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43922631253)
- [Android、Windows、Linux 应用](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43937445780)
- [iOS 归档与 Apple 构建](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43940734490)
- [OHOS 构建](https://github.com/azurekiln2333/qflistudio-dart/actions/runs/43943142540)

## 下载方法

1. 登录 GitHub。
2. 打开上面的运行记录。
3. 滚动到 **Artifacts**。
4. 下载对应平台的 ZIP。

GitHub 下载的是外层 ZIP。
应用安装包或内层归档位于其中。
工作流将产物保留 30 天。
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
Windows 包是完整目录，不是安装向导。
iOS 归档不能直接安装到手机。
构建成功不代表通过真机验收。

Linux CI 的静态分析通过。
221 个主机测试通过。
标准 Flutter 跳过 3 个 OHOS 专用测试。
桌面 SDK 通过 Kernel 编译和文件读写验证。
验证时先删除源码，再运行 Kernel 文件。

## 工作流

| 工作流 | 作用 |
| --- | --- |
| `Android native SDK` | 打包锁定的 Android SDK |
| `Android Windows Linux applications` | 构建三个平台的应用，导出桌面 SDK |
| `Apple applications and native dependencies` | 构建 macOS、iOS 应用，导出原生依赖 |
| `OHOS application and native libraries` | 构建 OHOS HAP、APP，导出原生库 |

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

以下数据来自首次测量。

| 目录 | 占用 | 内容 |
| --- | --- | --- |
| `build/` | 约 5.93 GiB | 应用产物和构建中间文件 |
| `.dart_tool/` | 约 1.02 GiB | Dart 与 Flutter 缓存 |
| `native/build/android/` | 约 0.54 GiB | 已打包的 Android SDK |

这三项合计约 7.49 GiB。
它们都是 Git 忽略的生成物。
`ohos/` 还占约 0.42 GiB。
其中混有源码和构建缓存。
不要删除整个 `ohos/` 目录。

云端构建不会自动清理本地文件。
只下载最终应用可减少本地构建需求。
继续本地构建会重新生成缓存。
只迁移原生构建，仍会产生应用构建缓存。
本次保留了已有的本地构建产物。

Android SDK 的恢复路径和输入归档见：
[Android 原生构建说明](native/dart-sdk/android/GITHUB_BUILD.zh-CN.md)。
