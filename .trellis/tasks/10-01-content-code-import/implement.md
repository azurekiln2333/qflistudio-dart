# Implementation

- [x] Inspect existing catalogs, details, import methods, editor navigation, and dirty state.
- [x] Record full requirements, implementation contracts, and scope constraints.
- [x] Prepare task-only changes in staged core files and adapt to concurrent core implementation.
- [x] Validate the initial follow-up patch and obtain filesystem approval for shared-core edits.
- [x] Apply the initial follow-up without overwriting unrelated changes.
- [ ] Apply final persistence, failure-handling, and test delta after incremental review.
- [ ] Add and run storage/import, catalog/detail, and actual editor navigation tests.
- [ ] Verify compact/desktop MD3 layout and enlarged text.
- [ ] Run app/core static analysis and relevant full test gates.
- [ ] Review every requirement against current evidence and update specs/progress.
- [ ] Verify the isolated HEAD-based feature snapshot and commit only this task's delta.

Do not include unrelated core edits in a commit. Any commit must be a reviewed,
coherent delta that also preserves the existing working tree.
