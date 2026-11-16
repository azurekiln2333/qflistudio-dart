# Multi-platform CI design

Pin upstream Flutter 3.41.9 and shared core commit
573d1b6eecf1c2b392ad753264a5a09f62f8335e for standard-platform CI.
Check out app and core as siblings. The local Flutter OHOS installation is a
modified mixed tree and cannot serve as a reproducible CI input. The fixed
core has explicit OHOS-only enum/widget references. Apply a checked patch only
to the disposable standard-Flutter core checkout, leaving OHOS builds and the
user's dirty shared-core directory unchanged. App startup tests keep OHOS first
frame behavior and desktop/mobile non-OHOS behavior distinct.

Android reuses verified 3.13.5 input packages and stages each requested ABI.
Desktop jobs publish the actual host SDK separately, then publish the complete
app bundle with its embedded SDK. Archive Unix bundles before artifact upload
to preserve executable bits and symbolic links. Native SDK smoke checks compile
and execute Kernel after removing source. iOS builds an unsigned archive and
exports compiled frameworks, not an independently executable Dart SDK.
OHOS uses a pinned upstream fork and public SDK if available. Explicitly report
missing toolchain input instead of replacing OHOS with Linux or skipping as green.

Keep platform jobs independent so one compiler failure does not erase another
platform's usable native package. Artifacts include source/toolchain provenance,
checksums and a 30-day retention period. No runtime or installer success claims
are inferred from compilation. Do not reuse local signing credentials.
