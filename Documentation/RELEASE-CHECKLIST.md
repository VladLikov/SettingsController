# 5.0 release acceptance

Current evidence: [5.0 verification](VERIFICATION-5.0.md). Reports for 4.x are kept in [Archive/4.x](Archive/4.x/) with their dated results.

## Automated gates

- Swift 6.4+ / Xcode 27.1+, iOS 15 deployment target.
- Package and public-example UI checks on explicit iPhone 27.0, iPad 27.0 and Duo 27.1 destinations in GitHub CI (`xcode-27` image).
- Public example uses ordinary `import SettingsController`.
- Native accessibility audit with all checks enabled, lifecycle and interactive-dismissal cancellation regressions.
- Localization JSON, translator comments, placeholders and coverage validation.
- `xcrun swift format lint --strict` over Sources, Tests, Examples and Package.swift.
- Premium card sizing: one SwiftUI measurement on first open for a horizontal card and none on later opens (unit tests); Release Time Profiler on a physical device (iPhone 12 mini reference) shows `PremiumCell.systemLayoutSizeFitting` work at or below 3 ms in total on first open.
- Final commit CI must be green; an earlier successful SHA is insufficient.

## Environment-specific checks

- Full VoiceOver traversal/activation and Reduce Motion animation inspection remain manual checks; enabling those settings alone does not prove the complete flow.
- Native iPad window resizing remains unverified where the test tools cannot enter resize mode. All four iPad orientations are declared.
- iOS 15 runtime, physical Mail handlers, real StoreKit/redemption and physical-device performance remain unverified. Simulator deployment-target builds and demo purchases do not prove them.
- The owner is the sole library consumer. Broad third-party migration certification, native-speaker certification of every locale and an official archive privacy PDF are not blockers for publishing this library. Host App Store privacy declarations still belong to the consuming application.

## Publication

PR preparation and CI are authorized. Do not merge, create a release tag or publish a GitHub release without the owner's release instruction. Preserve existing 3.x tags and signing settings.
