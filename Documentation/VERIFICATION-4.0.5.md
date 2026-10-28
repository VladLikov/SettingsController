# SettingsController 4.0.5 verification

2026-10-28. Patch to 4.0.4. Implementation: `c2337993e9d0401e4f343ec6b8bf17c80ec96d41`; subsequent changes are release documents only.

## Change

PremiumCardPayload and PremiumCard accept a separate optional tierTitle. The brand title uses regular title3 and the tier uses bold title3 in one attributed paragraph. The new initializer defaults to the native sparkle symbol and an empty subtitle. Exact existing initializer signatures remain available; existing combined titles are not parsed or changed. PremiumCell forwards the tier. Both card and CTA actions remain intact. Host-localized strings are preserved.

## Completed checks

- 28 package tests passed, zero failures: PremiumHeadingTests (3), ImageAndLayoutRegressionTests (12), SettingsConfigurationTests (4), StateRegressionTests (9). Duo simulator iOS 27.1, Xcode 27.1 / Swift 6.4, deployment target 15.0.
- 3 UI tests passed on iPhone Settings Verification iOS 27.0: blue App Lock PRO CTA/card navigation, purple Ripples Plus reference, dark/large-text/RTL. Native four-point sparkle and regular/bold heading visually verified at a common baseline; 72 pt normal card and compact CTA retained. Large text wraps without clipping.
- Resource validator passed: 80 keys, 51 locales, placeholders and privacy structure. git diff --check passed.

## Limits and evidence

No fresh full accessibility audit, VoiceOver traversal, physical-device deployment or iOS 15 runtime check. Prior release limits remain applicable. No duplicate full matrix is represented as a fresh pass.

Package and UI result bundles: sibling ../.settings-4-verification/premium-tier-title/Tests.xcresult and UI.xcresult. Captures and QA report: chat outputs/premium-tier-title/. Release readback: outputs/release-4.0.5/.
