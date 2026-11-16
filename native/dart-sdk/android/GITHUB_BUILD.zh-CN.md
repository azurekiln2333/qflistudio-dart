# GitHub 原生构建

## 构建范围

工作流名称是 `Android native SDK`。
工作流使用 GitHub 的 Ubuntu 服务器。
工作流分别打包 ARM64 和 x86_64。

本流程下载锁定版本的原生 SDK。
本流程不从 C++ 源码编译虚拟机。
本流程不生成 APK、HAP 或桌面安装包。
本流程不验证真机运行。

## 下载产物

1. 打开仓库的 **Actions** 页面。
2. 选择 **Android native SDK**。
3. 打开成功的运行记录。
4. 在 **Artifacts** 中下载产物。

下载时须登录 GitHub。
运行摘要也提供下载链接。
工作流将产物保留 30 天。

| 产物名称 | 用途 |
| --- | --- |
| `native-android-arm64-v8a` | ARM64 安卓设备 |
| `native-android-x86_64` | x86_64 安卓设备或模拟器 |

每份 ZIP 包含以下文件。

| 路径 | 内容 |
| --- | --- |
| `jniLibs/<ABI>/` | 虚拟机和原生 SDK 程序 |
| `assets/dart-sdk-<ABI>.zip` | SDK 数据、库和许可证 |
| `assets/dart-sdk-<ABI>.json` | 安装路径清单 |
| `provenance-<ABI>.json` | 版本、提交和来源记录 |
| `SHA256SUMS-<ABI>` | 文件校验值 |

将 ZIP 解压到 `native/build/android/`。
双 ABI 构建须解压两份 ZIP。
只构建 ARM64 时，只下载 ARM64 产物。
本地 APK 构建仍需 Flutter 和安卓工具链。

## 再次构建

推送 SDK 脚本改动可触发工作流。
推送工作流改动也可触发构建。
工作流进入默认分支后，可手动启动。
手动入口是 **Actions → Run workflow**。
试验分支是 `ci/native-android-sdk`。

## 原始包归档

SDK 版本固定为 `3.13.5`。
原镜像已删除这两个版本包。
归档工作流从 Termux 官方构建恢复原始包。
归档工作流校验大小和 SHA256。

原始包保存在仓库的预发布附件中。
标签是 `native-sdk-inputs-3.13.5`。
这些 `.deb` 文件是构建输入。
安卓应用不能直接安装这些文件。
清理旧产物时，请保留这份归档。

## 本地空间

以下数据测量于 2026 年 11 月 17 日。

| 目录 | 占用 | 用途 |
| --- | --- | --- |
| `build/` | 约 5.93 GiB | APK 和构建中间文件 |
| `.dart_tool/` | 约 1.02 GiB | Dart 与 Flutter 缓存 |
| `native/build/android/` | 约 0.54 GiB | 已打包的原生 SDK |

这三项合计约 7.49 GiB。
Git 不跟踪这些生成物。
源码目录 `native/dart-sdk/` 应保留。

云端构建不会自动清理本地文件。
清理构建缓存可以释放空间。
下次本地构建会重新生成缓存。
本地构建 APK 仍需保存对应 ABI 的 SDK。
只迁移原生构建，不能消除 APK 构建缓存。
本次没有删除已有构建产物。
