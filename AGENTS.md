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
