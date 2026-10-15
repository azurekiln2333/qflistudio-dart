# Design and boundaries

The behavior gap is unverified release integrity across the product profile, shared terminal UI, platform runtimes and authored curriculum.

Use existing `StudioProfile`, `ProgramRunner`, `NativeDartToolchain`, content repository and core terminal implementations. Do not duplicate core policy in each screen. Inspect the core read-only first; coordinate required core changes with its owner rather than concurrent edits.

Ownership: terminal Pi owns runner/toolchain/tools code and related tests; content Pi owns curriculum/assets/content tests; offline Pi owns main/profile app tests and offline audit; dispatcher owns native packaging, build/device verification and task integration. Each Pi owns one research report under this task. Avoid overlapping edits and stage exact paths only.

No other language repository, global SDK installation, signing identity or original curriculum data is changed speculatively. Existing real 120-lesson data is retained if the audit passes. Native and portable engines have separate capability evidence.
