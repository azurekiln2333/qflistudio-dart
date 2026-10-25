# Native offline guard verification

The product now returns OFFLINE_ONLY for direct openUrl and openAgreement
requests before reading arguments. It does not create an external ability intent.
Local share, picker, plugin registration and native window initialization remain.

Actual host behavioral checks:

- Current EntryAbility: 2 passed, 0 failed.
- Focused candidate derived from HEAD: 2 passed, 0 failed.
- Original HEAD as a negative control: exit 1; URL refusal assertion fails.

Command: `node --max-old-space-size=128 --test test/native_entry_ability_test.cjs`.
The candidate and negative control used the same test bytes in ignored
`.dart_tool/native-commit-check/{candidate,old}/` mirrors. Each mirror transpiles
its actual EntryAbility source and stubs only OHOS system services. This proves
the test detects the removed delegation behavior.

The focused candidate excludes the pre-task startupProgress changes. The working
source retains those changes. No initial signing configuration, main startup,
native splash or manifest work is included in the offline guard commit.

Candidate EntryAbility SHA-256: `e0c1b94730f737921942e97736abc49889c1e6b3669ff7a8bbb18b4d67a18557`.
Test SHA-256: `d4910bde5c98de6531f2d7fb97475856ac76f749fb7836cc2551eaf05b4d54dd`.

This is source/host behavior evidence. ArkTS type checking, rebuilding the final
package and actual installed target acceptance remain unverified. The signed
700336ef audit HAP predates the native guard and cannot prove this new behavior.
