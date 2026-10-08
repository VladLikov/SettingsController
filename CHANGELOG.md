# Changelog

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
