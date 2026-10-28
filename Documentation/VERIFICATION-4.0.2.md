# SettingsController 4.0.2 verification

2026-10-28. Patch to published 4.0.1 (`3341c6f4dd9d85e4ff4be3037c019e598074b4d5`). The owner subsequently authorized publication as 4.0.2. Existing tags remain unchanged.

## Custom actions — fixed

`SettingsRow(action:)` did not invalidate a pending StoreKit product request. Added `cancelPendingStoreProduct()` immediately before invoking the action. This invalidates only StoreKit navigation, without calling the general operation cancellation method.

Two new deterministic regressions exercise the real table-selection callback and a noncooperative provider:

- `testCustomActionRevokesLateStoreSuccessWithoutCancellingIndependentLoads`
- `testCustomActionRevokesLateStoreErrorWithoutCancellingIndependentLoads`

Before the fix, both fail: the callback still observes the pending request; late success presents the old controller, late error triggers the old external fallback. After the fix, both pass. Tests also hold a catalog request and a fixture image request pending during the action, then verify successful completion, no cancellation and one image-network request.

RoutingRegressionTests, CatalogRegressionTests and ImageAndLayoutRegressionTests: **32 passed, 0 failed, 0 skipped**, on iPhone Duo Settings QA / iOS 27.1, Xcode 27.1 / Swift 6.4, Debug, deployment 15.0. Resource validation: 80 keys / 51 locales. `git diff --check` passes.

## Published premium appearance — audit still fails

The audited PremiumCard.swift matches the published 4.0.1 blob `0450a4749ccc2f9f9fdf6416fbfc14100cc6a385`: white foregrounds and native regular interactive Liquid Glass with black tint opacity 0.75.

The complete, unfiltered accessibility audit actually executed on iPad Settings Verification / iOS 27.0: **0 passed, 2 failed, 0 skipped** (initial and after scrolling). Both report `Contrast failed for SwiftUI.AccessibilityNode`, without an associated element. This confirms the audit failure; it does not identify the CTA text, subtitle or another specific fragment as the cause. No issue was ignored and no assertion weakened.

Two controlled A/B attempts were made separately:

1. Local dark color scheme for only the glass CTA: **0 passed, 1 failed** with the same contrast issue.
2. White foreground on the parent Button as well as its content: **0 passed, 1 failed** with the same contrast issue.

Neither improved the audit, so **both experiments were removed**. The final PremiumCard.swift is byte-identical to 4.0.1. White text and native glass remain. There is no claimed contrast fix or green final audit. Pinpointing the flagged fragment remains an open diagnostic task; no additional recoloring is included without evidence.

## Evidence

Binary results/logs are outside the repository in the sibling `../.settings-4-verification/post401-custom-action/`: `Before-runtime.xcresult`, `After.xcresult`, `UI-Contrast.xcresult`, and separately named A/B result bundles. The initial test-fixture compile error is retained as `Before.xcresult`; it is not counted as a product assertion failure. Owner-facing screenshots, exported issues and detailed follow-up report are in this chat's `outputs/post401-custom-action`.

These simulator results do not establish physical-device behavior, full VoiceOver traversal or iOS 15 runtime acceptance. The published 4.0.1 verification remains historical; this document records the newer observations without rewriting that release.
