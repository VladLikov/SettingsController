# Migrating from 2.8.8 to 3.0.0

Version 3.0.0 requires iOS 15+ and Swift 6.3+. Update the consuming app's
minimum deployment target and toolchain before upgrading.

## Configuration and delegate

- Remove `initialValues` from `SettingsConfiguration`. Keep any before/after
  comparison state in your app.
- Replace `settingsDidDismiss(_ initialValues:)` with `settingsDidDismiss()`.
- Replace `settingsUserInfoRequested(_:)` with
  `settingsCurrentUserInfo() async -> UserInfo?`.
- Replace `settingsPremiumStatusRequested(_:)` with
  `settingsIsPremiumActive() async -> Bool`.
- Delegate protocols are now `@MainActor`; access UI and implement callbacks
  on the main actor.
- Configuration properties are now immutable. Construct a new configuration
  when changing its title, sections, insets, or overlay app ID.
- `configuration.delegate` is replaced by `eventHandler` and `dataProvider`.
  The initializer still accepts `delegate:` as a weak reference. Explicit
  `eventHandler:` and `dataProvider:` objects are retained and take priority
  over the delegate for their respective roles.

## Rows and destinations

- Replace explicit references to `SettingsRowData` with `SettingsRowItem`.
- Change the `vc:` initializer label to `destinationControllerType:` in
  `SettingsRow` and `PremiumPayload`.
- The App Store row payload is now `AppStoreAppRowState` instead of `AppRow`.
  Prefer `.ourApps(developerID:limit:excludeAppID:)` for automatic app listings.

See the README for current configuration, premium card, custom row, storage,
and presentation examples. These notes cover the main integration changes;
compile your consuming app and check its settings flows before shipping.
