# Dart 工作区迁移

## 工作区

原目录：

```text
D:\MyNewProjects\qfli_dart
```

目标目录：

```text
E:\MyNewProjects\QFLIProjects\qflistudio-dart
```

目标根目录使用复数 `QFLIProjects`。
本仓库只管理 Dart 产品。
其他产品由各自工作区负责。

## 克隆源码

新目录只绑定 GitHub。
共享 Core 与 Dart 仓库并列。
Core 目录名为 `qflistudio-core`。
Dart 包名仍为 `qfli_studio_core`。
Core 的 vendor 源码随 Git 提交。

```powershell
git clone https://github.com/azurekiln2333/qflistudio-core.git qflistudio-core
git clone https://github.com/azurekiln2333/qflistudio-dart.git qflistudio-dart
```

CI 使用工作流中锁定的 Core 提交。
本机不安装依赖。
本机不下载 SDK。

## 云端验证

所有构建和测试都在 GitHub Actions 运行。
所有静态分析都在 GitHub Actions 运行。
中文核对脚本也在云端运行。
禁止使用本机自托管 runner。
禁止通过 WSL 绕过限制。

请在 GitHub 查看运行日志。
请核对运行对应的提交。
请核对产物清单。
不要把产物下载到工作区。

```powershell
gh run list --branch main
gh run view <run-id>
gh api repos/azurekiln2333/qflistudio-dart/actions/runs/<run-id>/artifacts
```

原生依赖、应用和安装包分别上传。
中间产物单独归档。
云端产物有保留期限。
请查看工作流中的 `retention-days`。
保留原生 SDK 输入 release。
该 release 的标签如下：

```text
native-sdk-inputs-3.13.5
```

iOS 和 OHOS 安装前仍需签名。
构建成功不代表通过真机验收。
签名状态见产物中的来源记录。

## 同步与交接

请先保存 Trellis 任务和日志。
请先审查所有分支。
请把审查通过的提交合入 `main`。
请通过推送闸门推送到 GitHub。
请在目标目录快进拉取。

```powershell
git pull --ff-only origin main
git status --porcelain=v1
git rev-parse HEAD
git rev-parse 'HEAD^{tree}'
git ls-remote origin refs/heads/main
```

两份源码应具有相同的提交和树。
两份源码的 Git 状态应为空。
另行比对全部受控文件。
另行比对 Trellis 文件清单。
通过 herdr 发送交接结果。
目标 Codex 确认后接管收尾。

## 原目录保全顺序

本次迁移禁止任何删除。
不得注销 WSL 发行版。
先确认 GitHub 已保存全部源码。
先确认目标目录已通过比对。
先确认目标 Codex 已接收交接。
保留原目录直到交接完成。

请先列出忽略文件。

```powershell
git ls-files --others --ignored --exclude-standard --directory
```

忽略文件不等于可删除文件。
私有文件和生成文件须移入备份目录。
备份目录如下：

```text
D:/MyNewProjects/_migration-backup/qflistudio-dart-20261127
```

移动前确认绝对路径位于原目录内。
移动前核对受控文件清单。
保留受控源码、嵌套仓库和迁移证据。
移动时不要跟随重解析点。
不得覆盖备份中的现有文件。
移动后重新核对 Git 状态。

签名材料和手写补丁必须单独保留。
旧仓库的 Git 元数据中保存了原 OHOS 签名配置。
请将该配置移入备份目录的私有子目录。
历史提交含签名口令字段。
请由签名负责人核对凭据。
请由签名负责人轮换凭据。
嵌套 Git 仓库必须单独核对。
不要运行 `git clean`。

共享 WSL 镜像需要各产品共同确认。
本次只盘点发行版，不启动 WSL。
记录镜像内独有源码和配置的保全需求。
记录仍依赖镜像的工作区。
保留发行版和 VHDX。
本次 WSL 清单不是删除或注销授权。

## 审计记录

迁移证据保存在 Trellis 任务中：

```text
.trellis/tasks/11-26-github-workspace-migration/
```

记录应包含远端分支和提交。
记录应包含云端运行和产物。
记录应包含保全范围和交接状态。
