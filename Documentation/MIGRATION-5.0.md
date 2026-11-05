# Migrating from 4.0.x to 5.0

Requirements are unchanged: Swift 6.4+ / Xcode 27.1+, minimum deployment iOS 15.

Most 4.x initializers still compile as deprecated wrappers. Fix the deprecation warnings first, then the errors listed below.

## Row and premium destinations

`SettingsRow` and `PremiumPayload` take one `destination: SettingsDestination?` instead of three mutually exclusive properties. A 4.x row that set both a controller type and an action silently used the type; now each row has exactly one behavior.

| 4.x | 5.0 |
| --- | --- |
| `SettingsRow(title:icon:destinationControllerType: X.self)` | `SettingsRow(title:icon:destination: .controller(X.self))` |
| `SettingsRow(title:icon:destinationFactory: { … })` | `SettingsRow(title:icon:destination: .factory { … })` |
| `SettingsRow(title:icon:action: { indexPath, tableView, vc in … })` | `SettingsRow(title:icon:destination: .action { context in … })` |
| `PremiumPayload(isPremium:color:destinationControllerType:action:)` | `PremiumPayload(isPremium:color:destination:)` |
| `PremiumPayload(isPremium:color:destinationFactory:)` | `PremiumPayload(isPremium:color:destination: .factory { … })` |

`SettingsActionContext` provides `viewController`, and for rows also `tableView` and `indexPath`. Action rows are deselected by the library. The `destinationControllerType`, `action` and `destinationFactory` properties were removed; read `destination` instead.

## Profile row

`DefaultRow` has one profile case: `.user(name:avatar:destination:)`.

```swift
// 4.x
.defaultRow(.user("Guest", nil, ProfileController.self))
.defaultRow(.user("Guest", destinationFactory: { ProfileController(service: service) }))
// 5.0
.defaultRow(.user(name: "Guest", destination: .controller(ProfileController.self)))
.defaultRow(.user(name: "Guest", destination: .factory { ProfileController(service: service) }))
```

The `.userFactory` case was removed. Code that pattern-matches `.user(let name, let avatar, let type)` now binds a `SettingsDestination`.

## Theme and haptic storage

The storage protocols use typed values. Raw values match the 4.x integers, so stored preferences can be read as before:

```swift
// 4.x                                   // 5.0
var appColor: UIColor                    // removed
var appColorRawValue: String             var appColorID: String
var autoTheme: Bool                      var followsSystemAppearance: Bool
var interfaceStyle: Int  // 1, 2         var interfaceStyle: InterfaceStyle  // .light = 1, .dark = 2
var tapticEngine: Bool                   var isTapticEngineEnabled: Bool
var tapticStyle: Int     // 0, 1, 2      var tapticStyle: TapticStyle        // .light, .medium, .heavy
```

A storage backed by `UserDefaults` integers can wrap them, for example `InterfaceStyle(rawValue: defaults.integer(forKey: "style")) ?? .light`.

The library no longer writes a `UIColor`. To apply the accent, implement the new event `settingsDidSelectAppColor(_ color: any AppColorType)` (it has a default empty implementation) or map `appColorID` to your color enum in `settingsDidUpdateTheme(_:)`.

The Appearance and Taptic screens now keep a local copy of what they display, so a storage that ignores or transforms a write can no longer desynchronize table sections. Changes made to the storage from outside while the screen is open are not reflected until it is reopened.

## Icons

`Inset` is renamed `IconPadding`; `SettingsIcon(…, inset:)` becomes `SettingsIcon(…, padding:)` and `SettingsIconGenerator.generate(…, inset:)` becomes `generate(…, padding:)`. The old `Inset` name and `SettingsIcon` initializers remain deprecated; generator calls must use the new label.

## Presentation

`SettingsController.getSplitPresentationSettingsController(configuration:)` is deprecated; use `makeSplitPresentation(configuration:)`.

A `SettingsController` pushed into your own navigation controller no longer turns on `prefersLargeTitles` for that navigation bar.

## Removed public types

These were implementation details and are now internal: `SettingsCell`, `SwitchCell`, `MailCell`, `AppItem`, `AppStoreAppsLoader`, `AppStoreAppRowState`. The `SettingsRowItem.app` case was removed; catalog rows come only from `SettingsSectionKind.ourApps`. `PremiumCard`, `MailController` and `MailType` remain public.

## Behavior changes

- `MailType` minimum lengths ignore spaces and line breaks; `MailType.missingCharacters(in:)` and `allowsSending(_:)` expose the rule.
- A presented support form asks before discarding a typed message and closes itself after the mail app opens the draft.
- Review, More Apps, Telegram and VK fall back to web links; you can remove `tg` and `vk` from `LSApplicationQueriesSchemes`.
- The library's haptics and confirmation alerts are silent while the Taptic Engine setting is off.
- App catalog results stay in memory for ten minutes per developer, limit and excluded app.
- Chevrons appear only on rows that show a screen.
