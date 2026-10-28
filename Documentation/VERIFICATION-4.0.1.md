# SettingsController 4.0.1 verification

2026-10-28. Patch to the published `4.0.0` commit `df81cc9a5f8a1dcec71b27b3648f984c874328a3` (tree `b9f49fc67c779b5f5189f82b7dbb6093b200c69b`). The candidate branch is `codex/settingscontroller-4.0.1`; the release tag identifies the final source revision. Existing requested UI changes were preserved. The consumer application and its signing configuration were not modified.

## Findings and fixes

| ID | Evidence and correction | Regression coverage |
|---|---|---|
| F1 | An anonymous icon's cached tile outlived its source image while its key used that image's address. Replaced address identity with a token created once per icon definition; copies preserve it. Explicit IDs require a content revision when pixels change. Native allocator address reuse and display of an incorrect image were not forced. | `testAnonymousIconIdentitySurvivesCopyWithoutRetainingReleasedSource`, `testExplicitIconRevisionAndSymbolIdentityRemainStable` |
| F2 | Late StoreKit success/error could supersede a newer detail in a genuinely expanded iPad split. Accepted navigation now invalidates only the pending product request, leaving catalog/state work independent. | `testNewSplitDetailRevokesLateStoreSuccessAndErrorWithoutCancellingCatalogs`, `testOrdinaryLateStoreSuccessStillPresentsOnce`, existing StoreKit cancellation/race tests |
| F3 | Negative custom minimum reached a trapping `String.prefix`; zero produced inconsistent initial Send state. The effective minimum is `max(0, minimum)` everywhere and zero enables initial Send. | `testCustomMinimumIsSafeForEveryIntAndUsesGraphemes`, `testZeroMinimumCannotSendTwiceWhilePendingAndRestoresAfterCancel` |
| F4 | Privacy/Terms could violate Safari's HTTP(S) URL contract. Validate scheme case-insensitively and require a host before constructing Safari; invalid configuration shows a localized recoverable alert. A native Safari exception was not reproduced. | `testSafariValidationPreservesValidURLComponents`, `testInvalidSafariRouteShowsAlertWithoutCreatingSafariOrOpeningExternally` |
| F5 | Five MainActor diagnostics came from synchronous UI-test teardown. Async teardown preserves actor isolation and awaits superclass cleanup. | Fresh Swift 6.4 typecheck: exit 0, no diagnostics; executed UI cases clean up through that teardown. |

Additional corrections: editing Mail during diagnostics cancels the old snapshot, so another Send uses the edited body. Mail has no preparation banner. About uses a native update spinner and restores the row after completion/cancellation. Premium text/icons remain white, with contrast-adjusted host hue and a native Liquid Glass CTA on iOS 26+. Accessibility text can expand the ordinary primary column to 45%; an active Duo division takes precedence at 50/50 and widths restore after transitions.

## Environment and automated results

Xcode 27.1 (27A9275), Swift 6.4, arm64 Apple Silicon simulators, Debug configuration, deployment target 15.0. Dependencies and minimum platform requirements are unchanged.

| Run | Passed | Failed | Skipped | Scope |
|---|---:|---:|---:|---|
| Package, iPad Settings Verification, iOS 27.0 | 81 | 0 | 3 | All 84 package tests; two Duo-only tests and the combined 27.1 accessibility/division policy skip. |
| Package, iPhone Duo Settings QA, iOS 27.1 | 83 | 0 | 1 | All 84 package tests; genuinely expanded iPad StoreKit fixture skips on the closed phone. That scenario passes on iPad. |
| Initial targeted UI, iPad iOS 27.0 | 4 | 2 | 0 | Mail edit/cancel, sheet/factory, simulated premium restore and dark/RTL/AX text pass. Two complete accessibility audits report contrast; this attempt remains recorded. |
| Final contrast UI attempts | — | — | — | Three attempts failed to start the UI runner and were interrupted, not passed. Two used iPad, one iPhone; evidence is retained in `UI-Contrast-v2`, `UI-Contrast-v3` and `UI-Contrast-iPhone` bundles/logs. |

The final glass-tint adjustment is a visual-only modifier, after package verification. Its affected full accessibility audits were attempted separately rather than repeating all package tests, but runner launch failed. Final runtime contrast acceptance remains unverified; the earlier failed audit is not erased. Resource validation passes: 80 keys, 51 locales, placeholder parity, translator comments and privacy plist structure. `git diff --check` passes. Typecheck does not substitute for runtime UI evidence.

## Broader review coverage

| Area | Result and limits |
|---|---|
| R1 Mail lifecycle | Minimum/grapheme boundaries, pending single-flight, cancel, edited body, obsolete completion and failed external opening have regression coverage. UI confirms editable text, disabled pending Send and Close. No real email was sent; actual Mail/Gmail handlers were not exercised. |
| R2 StoreKit routing | Controlled success/error and obsolete requests tested, including expanded iPad detail replacement. No real product purchase or redemption. |
| R3 State refresh | Existing incremental refresh, nil/zero semantics, unchanged-state and obsolete-generation tests pass in both complete package runs. |
| R4 Destinations and ownership | Existing lazy factory/lifecycle coverage passes; native sheet/factory UI passes. Full physical interactive cancellation is not claimed. |
| R5 Icons and async images | Stable token/copy behavior, released source, explicit revision, traits/insets/scale, coalesced requests and consumer cancellation are covered. Cache cost limits remain policy, not a strict process-memory ceiling. |
| R6 About | Update/account cancellation, row spinner cleanup and invalid Safari routes are covered. Real App Store/provider responses were not required by the controlled tests. |
| R7 Duo | Package division/restoration tests pass on 27.1. Native posture verification is recorded separately below. Synthetic frames/trait overrides are unit evidence, not native fold screenshots. |
| R8 Accessibility | Fresh dark/RTL/max-text screenshot and full unfiltered audits. VoiceOver traversal and animation under real Reduce Motion remain manual coverage gaps. |
| R9 iOS 15 | Build uses deployment 15.0, availability guards and existing forced legacy-hosting tests pass on newer simulators. No iOS 15 runtime/device is installed; this is not an iOS 15 runtime pass. |
| R10 Performance/memory | No fresh matched 4.0.0/4.0.1 Instruments benchmark. Previous 30-cycle profile belongs to an older revision and is not reused as patch performance evidence. Source-image release has deterministic native coverage; no speedup percentage or complete leak guarantee is claimed. |
| R11 Privacy/localization/dependencies | Resource and source checks pass; no SwiftBoost or dependency updates. New invalid-link message has 51 translations; Checking is VoiceOver-only, Preparing removed. Catalog completeness is not native-speaker certification or a host archive privacy report. |
| R12 Automation | Full package suites on two destinations plus focused UI. No repeated three-device UI matrix; cancelled/unrun runs are not passes. |
| R13 Integration/docs | README, migration and changelog describe actual patch semantics. Sample public API is built and exercised. No fresh real AppLock provider/purchase/logout acceptance was performed; the host remains unchanged. |

## Native Duo verification

The current sample installed and launched on iPhone Duo Settings QA, iOS 27.1. Device Hub could not open the exact Duo posture panel (bounded timeout), so book/tabletop active-division screenshots and native AX/division interaction were **not verified**. No synthetic frame is substituted for that evidence. The 27.1 package policy/restoration tests passed; they do not establish visual posture acceptance. No device pose, accessibility setting, signing or user data was changed.

## Evidence and reproduction

Local evidence is in the sibling directory `../.settings-4-verification/release-4.0.1/`: `Package-iPad.xcresult`, `Package-Duo.xcresult`, package logs, `UI-iPad.xcresult`, and final contrast results. Owner-facing exported attachments and the independent audit live in this chat's `outputs/release-4.0.1` and `outputs/audit-4.0.1`; large binary/log evidence is not committed to the repository.

Equivalent package command from the package root (select a new result path for a deliberate rerun):

```sh
xcodebuild -scheme SettingsController \
  -destination 'platform=iOS Simulator,name=iPad Settings Verification,OS=27.0' \
  -derivedDataPath .build/xcode \
  -resultBundlePath ../.settings-4-verification/release-4.0.1/Package-iPad.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -test-timeouts-enabled YES -maximum-test-execution-time-allowance 60 \
  test CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0
```

The Duo run uses `name=iPhone Duo Settings QA,OS=27.1` and `Package-Duo.xcresult`. UI tests use the SettingsExample project/scheme with separate DerivedData, selecting the two accessibility audits, dark/large-text/RTL, sheet/factory, simulated restore and slow Mail edit/cancel tests. Apple Xcode MCP's sample build reported a missing package product despite successful resolution; XcodeBuildMCP performed the UI build/test fallback. Package CLI handles the package-only workspace.

For remaining manual acceptance: use an iOS 15-compatible device/runtime; navigate actual Mail handlers without sending; traverse settings/About with VoiceOver; compare transitions with Reduce Motion toggled; resize iPad while reading the final row. Real consumer adoption should keep the package pin and host integration revision together for rollback, without deleting application data or changing signing.

## Compatibility and release verdict

No new public parameters or dependencies. Correct 4.0 integrations remain source-compatible. Behavior changes are explicit: negative mail minimums clamp to zero; zero allows an empty draft immediately; editing revokes pending preparation; invalid Privacy/Terms links show an error; anonymous icon definitions only share cache entries when copied or given an explicit shared revision identifier.

The functional corrections are ready for code review/merge on the fresh package and targeted UI evidence above. Publication is explicitly authorized by the owner and proceeds with documented coverage limits. **Complete final UI acceptance is not established:** the earlier contrast audit failed, the final stronger glass tint could not receive a fresh audit because runner launch hung, native Duo posture controls were unavailable, and physical/iOS 15/manual checks above remain outstanding. These limitations are not represented as passes. The attached review document's earlier no-publication instruction is superseded by the owner's direct request to fix and publish 4.0.1.
