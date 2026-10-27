# 4.0 release acceptance

## Automated gates

- Build the package using Swift 6.4+ / Xcode 27.1+ with iOS 15 deployment target. Swift 6.3 support is no longer a release gate.
- Pass all original and added regression tests on the explicitly selected iPhone and iPad runtimes. Preserve summaries, destination and tested commit SHA.
- Build the public example with ordinary `import SettingsController`, not `@testable`.
- Pass public-example UI tests for profile edits, purchase, logout, sheets, factories and large-text/dark/RTL smoke scenarios.
- Validate localization key coverage, placeholders and privacy plist structure.
- Verify CheckUpdate's versioned data-only dependency and absence of unused SwiftBoost.

## Manual release blockers — not replaced by CI

- Execute on a real iOS 15 environment using a compatible toolchain/runtime. Forcing the legacy hosting path on a newer runtime is useful regression coverage, not equivalent.
- Test app Settings navigation and host localization configuration on a physical iPhone and iPad.
- Test Apple Mail, a third-party mail handler and absence/refusal of a handler. Confirm Unicode, `&`, `+`, newlines and long drafts survive the real client.
- Test StoreKit, code redemption and overlay geometry on devices, including rotation, tab bars and resizable windows.
- Check VoiceOver focus, switch labels, Dynamic Type extremes, contrast and Reduce Motion with actual assistive settings.
- Inspect real split collapse/expansion and cancelled interactive dismissals.
- Profile a large custom icon and repeated settings/paywall/profile sessions with Allocations, Time Profiler and Memory Graph. Record device/OS, workload and before/after results; no performance percentage is assumed.
- Generate the final host archive privacy report and verify the host plus every dependency. The package manifest does not cover application-owned storage, purchase analytics or support data processing.
- Review new translations in context, especially long mail error text and RTL layouts.
- Migrate and smoke-test at least one real consuming application. Keep its integration change together with the package version for rollback.

## Publication

Keep 4.0 marked unreleased until all gates above have evidence. Create an immutable 4.0.0 tag only then. Preserve existing 3.x tags. Release notes must distinguish code changes, automated evidence and remaining environment-specific checks.
