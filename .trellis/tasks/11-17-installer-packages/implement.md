# Execution

- [x] Audit existing workflows and runner image tools.
- [x] Add `tool/ci/package_installer.py` and `tool/ci/windows_installer.iss`.
- [x] Add `tool/ci/test_package_installer.py`.
- [ ] Build a Debian package from a fixture in WSL and install it there.
      Not run: WSL cannot start on this machine (Hyper-V is unavailable).
      The Linux installer is verified only by the real workflow.
- [x] Add installer steps to `application-build.yml` and `apple-build.yml`.
- [x] Update `GITHUB_BUILD.zh-CN.md` and the native runtime spec.
- [ ] Push `ci/installer-packages` and inspect the real runs.
- [ ] Fix evidenced failures; record run URLs and artifact inventory.

Validate YAML and Python syntax before pushing. Run the helper unit tests and
`tool/ci/test_prepare_core.py`. Run `scripts/ste-lint-zh.py` on changed Chinese
documents. Application analysis and tests are unnecessary: no app code changes.
Apple, Debian and Inno Setup behaviour can only be verified in the real
workflows.
