# Execution

- [x] Identify old/new clone and Herdr pane ownership.
- [x] Read workflow and applicable specifications.
- [ ] Audit remote heads, local branches and unpublished work.
- [ ] Audit tracked/ignored files and complete Trellis progress.
- [ ] Review six-platform CI, installer outputs and dependencies.
- [ ] Add cloud-only rules and address verified migration gaps.
- [ ] Commit reviewed changes and integrate into main.
- [ ] Push GitHub and validate exact-SHA cloud runs.
- [ ] Pull the target clone and compare content/Trellis inventories.
- [ ] Record cleanup boundaries and send final Herdr handoff.

Validation runs only in GitHub Actions. Local operations are limited to source editing, Git, API/Herdr inspection and read-only inventory/hash comparison. No local build, test, analyzer or dependency-install commands are allowed.
