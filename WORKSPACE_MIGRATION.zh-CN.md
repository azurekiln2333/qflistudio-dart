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

所有构建和测试都在 GitHub Actions 执行。
所有静态分析都在 GitHub Actions 执行。
中文检查器也在云端执行。
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
请把 `main` 推送到 GitHub。
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

## 原目录清理顺序

先确认 GitHub 已保存全部源码。
先确认目标目录已通过比对。
先确认目标 Codex 已接收交接。
保留原目录直到交接完成。

请先列出忽略文件。

```powershell
git ls-files --others --ignored --exclude-standard --directory
git clean -ndX
```

第二条命令只预览，不删除文件。
忽略文件不等于可删除文件。
签名材料和手写补丁必须单独保留。
嵌套 Git 仓库必须单独核对。
不要执行全目录 `git clean -fdx`。

请按审计清单逐项删除构建目录。
删除前确认绝对路径位于原目录内。
删除前确认目录不含受控文件。
删除前排除重解析点。
清理后重新检查 Git 状态。

共享 WSL 镜像需要各产品共同确认。
先保存镜像内的独有源码和配置。
再确认没有工作区依赖该镜像。
最后按发行版名称注销。
不要直接删除注册中的 VHDX。
本次 WSL 清单不代表允许立即删除。

## 审计记录

迁移证据保存在 Trellis 任务中：

```text
.trellis/tasks/11-26-github-workspace-migration/
```

记录应包含远端分支和提交。
记录应包含云端运行和产物。
记录应包含清理范围和交接状态。
