# Changelog

## Unreleased

### Fixed
- Refresh premium-card gradient and CTA immediately after selecting an app color in Appearance, without reopening settings or reloading unrelated rows.

## 4.0.5 — 2026-10-28

### Added
- Add a separate optional tierTitle to premium card payload/view: regular brand name plus bold PRO/Plus, with a default native sparkle icon. Existing initializers remain available.

## 4.0.4 — 2026-10-28

### Fixed
- Redesign PremiumCard as a compact single-line pill with a stronger three-tone gradient and native glass-prominent CTA; adapt narrow/large-text layouts without whole-card press animation.

## 4.0.3 — 2026-10-28

### Fixed
- Restore a visible premium gradient and use a native glass-prominent CTA with a distinct matching hue, white text and no whole-card press animation.
- Keep failed mail-opening recovery pending until the form reappears or the app becomes active; preserve editable text and re-enable Send after failure.

## 4.0.2 — 2026-10-28

### Fixed
- Revoke pending StoreKit navigation before invoking a custom `SettingsRow(action:)`, without cancelling catalog or image loading.

## 4.0.1 — 2026-10-28

### Fixed
- Replace anonymous custom-icon address keys with definition-scoped unique identities; definition copies retain cache hits without retaining the original image in the cache.
- Revoke pending StoreKit navigation after a newer accepted detail/modal/external route, preserving independent background requests.
- Clamp custom mail minimums to zero, make initial Send consistent, and cancel pending drafts when text changes.
- Validate Privacy/Terms HTTP(S) URLs and host before Safari, with a localized recoverable error.
- Use actor-correct async UI-test teardown and restore accessibility split widths without overriding Duo division policy.
- Use native interactive Liquid Glass for the premium-card CTA on iOS 26+, retaining a white capsule fallback on earlier systems.
- Remove the Mail preparation banner and its layout work; keep Send disabled while diagnostics are pending.
- Keep premium-card foregrounds white and increase background contrast while preserving the supplied hue; the native glass CTA uses a darker tint for readability.
- Show a native activity indicator instead of the visible Checking status in About; restore the row after completion or cancellation.

## 4.0.0 — 2026-10-28

### Added
- Optional avatar content revisions to avoid false profile changes when hosts recreate UIImage snapshots. Existing initializers and reference comparison remain supported.
- Synchronized source folders in the generated example and stable Mail action identifiers across horizontal and vertical native toolbars.
- Native iPhone Duo split presentation: equal sidebar/detail columns for an active division, selected detail retention across fold transitions, and the existing empty state when nothing is selected. Tabletop keeps left/right columns. This path requires Xcode 27.1 / Swift 6.4 and iOS 27.1; iOS 27.0 uses column-style presentation for native accessibility safety, while iOS 15–26 keep classic presentation.
- A visible, localized preparation status in the mail form while diagnostics load; Send remains a standard disabled navigation action during preparation.
- Lazy main-actor destination factories, explicit async state refresh and public AppItem construction.
- Deterministic regression coverage, public-import example host and iPhone/iPad CI with evidence artifacts.
- Retriable catalog state and recoverable external-mail opening failures.

### Fixed
- Compact empty-detail typography using Dynamic Type headline/subheadline styles, distinct text colours and tighter spacing.
- Avoid the native iPadOS 27.0 accessibility separator crash by using supported column-style split presentation.
- Reliable native Duo tabletop tracking, deferred column updates and restoration of minimum widths; cold empty detail remains visible.
- Readable premium-card subtitle contrast verified by the complete native accessibility audit.
- Incremental visible-table updates for account/premium/catalog changes, without rebuilding unrelated cells; safe offscreen synchronization is retained.
- Reused app placeholders, stable icon tasks, reduced cell configuration work, cached Mail status sizing and bounded Send-length checks.
- Shared catalog requests and consumer-aware image cancellation; bitmap caches now account for byte cost as well as object count.
- Percent encoding in mail drafts, cancelled/obsolete StoreKit fallbacks, late account/update results and task-handle races.
- Premium card restoration, profile updates behind sheets/on iPad, and missing typed User ID clearing.
- Removed-color selection, nil/zero inset cache collision, dynamic trait refresh, overlay inset restoration and bounded tile rendering.
- Dynamic Type, legacy hosting containment and shared image-request cancellation/scale behavior.

### Changed
- Require Swift tools/compiler 6.4+ (Xcode 27.1+); remove the Swift 6.3 compiler fallback. Minimum deployment remains iOS 15.
- Language directly opens app Settings; the internal language controller is removed.
- About opens before account loading and owns its cancellable request. CheckUpdate 1.0.1 provides data without automatic UI.
- Removed unused SwiftBoost and the automatic review request on theme changes.
- Mail diagnostics use public locale APIs and the accurate Preferred Language label. Added package privacy metadata.
- Reviewed new UI strings in context, corrected Finnish Cancel and four update messages, and verified ru/de/ar Mail/About rendering; this is not native-speaker certification of all locales.

### Breaking changes
- `.language(email:)` becomes `.language`.
- `SettingsMailInfo.userID` is the only User ID source; remove the old Adapty-specific ID and separate About/Mail userID arguments.
- See Documentation/MIGRATION-4.0.md for provider invocation, nil semantics, ownership and refresh requirements.

## Earlier unreleased User ID changes

### Changed

- Replace the old deprecated `SettingsMailInfo(adaptyProfileID:productID:isPremium:)` initializer with a single non-deprecated `SettingsMailInfo(userID:productID:isPremium:)`.
- Use `SettingsMailInfo.userID` as the only source for User ID in support emails and the built-in About screen.
- Retrieve About-screen User ID and premium status via the existing asynchronous data provider, avoiding separate User ID configuration.

### Breaking changes

- Remove `userID:` from `MailController.init`, the internal `LanguageController.init`, `MailBuilder.buildMail`, and the `.about` row.
- Remove `adaptyProfileID` from `SettingsMailInfo`. Update consuming apps to set `userID: profile.profileId` in `settingsMailInfo()`.
- Applications without a data provider now show `User ID: -` in support emails and About instead of reading an ID from the `.about` row.

## 3.1.5 — 2026-10-25

### Changed

- Display only `User ID`, `Product ID`, and `Pro Status` in the email's user-info section. Never display or substitute Adapty Profile ID, even when User ID is unavailable.
- Offer a two-field `SettingsMailInfo(productID:isPremium:)` initializer. Keep the old profile-ID initializer deprecated but source-compatible; its profile-ID argument has no effect on emails.
- Correct the Russian support form title, remove an unsupported lifetime Premium promise from translation-help text, and polish five additional Russian UI strings.

### Testing

- Verify user-ID precedence and absence of Adapty Profile ID in support, language-request, and custom emails.

### Compatibility

- Existing callers continue to compile. No Adapty SDK dependency.

## 3.1.4 — 2026-10-15

### Changed

- Remove user-assigned device name from support, language-request, and custom mail diagnostics.
- Retain Device Model and Device Type fields, with regression tests for all mail types.

### Compatibility

- No public API changes.

## 3.1.3 — 2026-10-13

### Added
- `SettingsMailInfo` with only `adaptyProfileID`, `productID`, and `isPremium`.
- Async `settingsMailInfo()` provider invoked when preparing support/language/custom emails.
- On-demand typed diagnostics take priority over legacy fields, with compatibility fallbacks.
- Regression tests for typed diagnostics and old provider behavior.

### Compatibility
- No Adapty dependency and no breaking changes to existing callers.

## 3.1.2 — 2026-10-11

### Added

- Include `System Language`, `App Language`, and `App Region` in support, language-request, and custom email diagnostics.
- Keep the existing `Locale` and `Time Zone` fields for backward-compatible support information.
- Add regression assertions for the new email diagnostics across all mail types.

### Compatibility

- No public API changes; existing integration with version 3.1.1 remains source-compatible.

## 3.1.1 — 2026-10-08

### Changed

- Replace `subscriptionID` with optional `productID` in settings, direct support forms, and language requests.
- Email diagnostics display the store product identifier as `Product ID`, with `-` when absent.
- When upgrading from 3.1.0, rename the `subscriptionID` argument to `productID` and supply the store product identifier.
- Initializer calls that omit product metadata remain source-compatible.

## 3.0.2 — 2026-10-08

### Changed

- Replace `subscriptionID` with optional `productID` in settings, direct support forms, and language requests.
- Email diagnostics now display `Product ID`, with `-` when the app supplies no product identifier.
- Callers using the 3.1.0 `subscriptionID` argument must rename it to `productID` and pass their store product identifier.
- Pin version 3.0.2 exactly; the previously published 3.1.0 tag keeps its original API.

## 3.1.0 — 2026-10-08

### Added

- Optional `subscriptionID` in `SettingsConfiguration` and `MailController`.
- Subscription ID in support and language-request emails, with `-` when absent.
- Regression coverage for all mail types and existing initializer arguments.

### Compatibility

- Existing 3.0.0 initializer calls remain source-compatible.
- Install from version 3.1.0 to use subscription ID metadata.

## 3.0.0 — 2026-09-08

### Breaking changes

- Require iOS 15+ and Swift 6.3+ (previously iOS 14 / Swift 6.0).
- Replace callback-based data requests with async data provider methods.
- Remove configuration `initialValues` and the dismissal callback argument.
- Make configuration values immutable and split event handling from data provision.
- Rename `SettingsRowData` to `SettingsRowItem` and destination initializer labels
  from `vc:` to `destinationControllerType:`.
- Isolate delegate protocols to the main actor.

See [MIGRATION.md](MIGRATION.md) before upgrading from 2.8.8.

### Added

- Cached settings icon rendering and expanded App Store loading support.
- Standalone MIT license and contribution instructions.
- Regression tests for configuration ownership and icon rendering/cache behavior.
- iOS Simulator test script and GitHub Actions workflow.

### Changed

- Use a versioned CheckUpdate dependency so release-based SPM installation resolves.

- Clarify Swift 6.3 requirements, dependencies, localization, and minimal setup.
