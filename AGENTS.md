<!-- TRELLIS:START -->
# Trellis Instructions

These instructions are for AI assistants working in this project.

This project is managed by Trellis. The working knowledge you need lives under `.trellis/`:

- `.trellis/workflow.md` — development phases, when to create tasks, skill routing
- `.trellis/spec/` — package- and layer-scoped coding guidelines (read before writing code in a given layer)
- `.trellis/workspace/` — per-developer journals and session traces
- `.trellis/tasks/` — active and archived tasks (PRDs, research, jsonl context)

If a Trellis command is available on your platform (e.g. `/trellis:finish-work`, `/trellis:continue`), prefer it over manual steps. Not every platform exposes every command.

If you're using Codex or another agent-capable tool, additional project-scoped helpers may live in:
- `.agents/skills/` — reusable Trellis skills
- `.codex/agents/` — optional custom subagents

Managed by Trellis. Edits outside this block are preserved; edits inside may be overwritten by a future `trellis update`.

<!-- TRELLIS:END -->

## Cloud-only development

This policy applies to every agent and every local clone. It overrides older
instructions that request local validation.

- Run builds, tests, analyzers, format checks and dependency installation only
  in GitHub Actions on hosted runners. Do not use local or self-hosted runners.
- Do not run Flutter/Dart bootstrap, pub get, pub upgrade, analyze, test or build
  locally. Do not run Gradle, CMake, Ninja, compiler, CocoaPods, hvigor, npm
  install, pytest or equivalent build/test commands locally.
- Do not start WSL, containers or virtual machines to bypass this restriction.
- Do not download SDKs, Actions artifacts, installers or test fixtures into
  this workspace. Inspect cloud run logs and artifact metadata through gh.
- Local source edits, Git operations, read-only inventory/hash comparison and
  Herdr coordination are allowed. Trellis administrative scripts may run with
  PYTHONDONTWRITEBYTECODE=1. Run the Chinese linter in GitHub Actions.
- Use GitHub as the only remote in a new clone. Keep reviewed work on main.
  Audit branch ancestry before merging or deleting a branch. Never force-push
  or discard another agent's work to obtain a clean status.
- Commit the complete .trellis task/spec/journal/config history. Exclude only
  generated caches and build/test outputs. Keep credentials out of Git.
- The portable sibling checkout is ../qflistudio-core. The Dart package name
  remains qfli_studio_core. CI must use the matching checkout directory.
- Record exact commit SHAs, GitHub run IDs, artifact inventories and unresolved
  signing/device gates in the active Trellis task before a Herdr handoff.
- Retain the old source clone until the new coordinator verifies the handoff.
  Shared WSL images and caches require cross-product cleanup coordination.

改写中文技术文本时套用受控中文规则：一句一动作、主动语态、一词一义（同一概念全篇同一个词）、不用分号连接动作、句长（指令 ≤ 25 字、说明 ≤ 40 字）、去掉虚动词（进行 / 加以 + 名词）、套话（需要注意的是、在一定程度上）、营销形容词（无缝、强大、赋能、闭环）与含糊词（若干、一些、相关）； 不得改动情态（可能 / 也许）：置信度是内容。机械首查用 python <repo>/scripts/ste-lint-zh.py <文件>。

## Versioned parent workspace policy - 2026-11-27

Verbatim source: `E:/MyNewProjects/QFLIProjects/AGENTS.md`.
The repository's stricter cloud-only rules above remain in force.

<!-- QFLI-PARENT-POLICY:2026-11-27:START -->
# QFLI product workspace rules

These rules apply to every agent and every repository under this directory.
The user requires all builds and tests to run on GitHub-hosted runners.

- Do not run local builds, tests, benchmarks, emulators, or native compilation.
- Do not run dependency installation, SDK installation, or dependency restore.
- Do not download build artifacts, installers, SDKs, or build caches to this workspace.
- Do not run Flutter, Dart, Gradle, CMake, Ninja, Xcode, Hvigor, or package-manager commands that generate output.
- Read and edit source locally. Inspect Git metadata and text without creating build or test outputs.
- Run validation through the repository's GitHub Actions workflows. Read results through GitHub API or log output.
- Keep artifacts on GitHub. Record immutable source revisions, run IDs, job conclusions, checksums, and signing limitations in Trellis.
- Keep durable Trellis tasks, specs, research, journals, and project instructions in version control. Keep local runtime/session state and secrets ignored.
- Use GitHub as the sole remote for migrated clones. Check both fetch and push URLs.
- Preserve another agent's work. Coordinate repository ownership and handoff through Herdr.
- Do not delete shared WSL distributions or old source workspaces without the owning coordinators' preservation decision.
- Folder names follow GitHub repository names. Shared core is `qflistudio-core`; its Dart package name remains `qfli_studio_core`.

Each repository must also commit these restrictions in its own AGENTS.md or project policy so fresh clones on another PC retain the rules. This parent file is a convenience copy, not a substitute for versioned repository policy.

Initial coordinated writer: SQL coordinator, Herdr w62:p1, 2026-11-26.
<!-- QFLI-PARENT-POLICY:2026-11-27:END -->

## Migration preservation override - 2026-11-27

The latest migration directive forbids all deletions. This stricter restriction
supersedes any earlier conditional cleanup or deletion permission.

- Do not delete files, directories, branches, worktrees, WSL distributions or VHDX files.
- Do not run `git clean` or unregister WSL distributions.
- Preserve private and generated files by moving them to
  `D:/MyNewProjects/_migration-backup/qflistudio-dart-20261127`.
- Preserve tracked source, nested repositories, migration evidence and existing backups.
  Do not overwrite backup files or follow reparse points while moving files.
- Inventory shared WSL preservation requirements without starting WSL.
  Retain the old source workspace and shared WSL images.
- Use the coordinator's push gate. Do not push directly.
- Do not run output-producing commands in the target workspace.
- Run the Chinese linter only in GitHub Actions. Local readback is not cloud validation.
