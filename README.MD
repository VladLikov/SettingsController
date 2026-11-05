> **5.0.0.** This release contains source-breaking changes relative to 4.0.x. Most 4.x initializers remain as deprecated wrappers. Read [Migration to 5.0](Documentation/MIGRATION-5.0.md), the [release checklist](Documentation/RELEASE-CHECKLIST.md) and the [5.0 verification and its limits](Documentation/VERIFICATION-5.0.md). Existing 4.x and 3.x release tags are unchanged.

# SettingsController

SettingsController is a modular UIKit settings screen for iOS apps. It gives you a ready-to-present `UITableViewController` with common settings flows: appearance, haptics, language, premium, support, App Store actions, social links, app metadata, and an App Store "more apps" section.

SettingsController is used across a portfolio of production iOS apps and is available to other developers through Swift Package Manager.

The package is configured from your app code, without subclassing the settings controller.

## Features

- UIKit-first `SettingsController` based on `UITableViewController`
- iPhone modal presentation, iPad split view and iPhone Duo two-column presentation
- Built-in rows for appearance, haptics, language, premium, support email, Telegram, VK, App Store review/share, redeem code, and an about screen
- Custom rows with your own icon, detail text and one destination: a controller type, a factory or an action
- Optional user profile row, premium row and premium card
- App Store "our apps" section loaded by developer ID, kept in memory for ten minutes
- Theme and haptic updates reported through event handler callbacks
- Localized resources (51 locales) via Swift Package resources

## Requirements

- iOS 15.0+
- Swift 6.4+ (Xcode 27.1+)
- UIKit
- Swift Package Manager

## Installation

Add the package in Xcode:

```text
File -> Add Package Dependencies...
https://github.com/VladLikov/SettingsController.git
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/VladLikov/SettingsController.git", from: "5.0.0")
```

Then add `SettingsController` to your target dependencies.

Upgrading from 4.0.x: read [MIGRATION-5.0](Documentation/MIGRATION-5.0.md). From 3.x: read [MIGRATION-4.0](Documentation/MIGRATION-4.0.md) first.

## Quick Start

A minimal settings screen needs only a configuration and a presenting controller:

```swift
import UIKit
import SettingsController

@MainActor
func showSettings(from controller: UIViewController) {
    let configuration = SettingsConfiguration(sections: [
        SettingsSection(kind: .rows([
            .defaultRow(.shareApp(appID: "1234567890")),
            .defaultRow(.rateApp(appID: "1234567890"))
        ]))
    ])
    SettingsController.present(configuration: configuration, from: controller)
}
```

Replace the example App Store ID with your app's ID.

### Full configuration example

Keep the settings composition in one place. In this example, `AppSettings.shared` is your app storage object that conforms to `ThemeStorage` and `TapticStorage`.

```swift
import UIKit
import SwiftUI
import SettingsController

@MainActor
enum SettingsComposition {
    private static let settings = AppSettings.shared

    static func sections() -> [SettingsSection] {
        let premium = PremiumPayload(
            isPremium: settings.isPremium,
            color: settings.accentColor,
            destination: .factory { PaywallViewController() }
        )

        return [
            // An active entitlement turns the card into an "Active" premium row automatically.
            SettingsSection(kind: .premiumCard(PremiumCardPayload(
                title: "App Lock",
                tierTitle: "PRO",
                buttonTitle: "Upgrade",
                premium: premium
            ))),

            SettingsSection(title: "App", kind: .rows([
                .row(SettingsRow(
                    title: "Notifications",
                    icon: SettingsIcon(symbol: .bell.fill, color: .systemRed),
                    destination: .controller(NotificationsViewController.self)
                )),
                .defaultRow(.appearance(theme: settings)),
                .defaultRow(.tapticEngine(taptic: settings)),
                .defaultRow(.language)
            ])),

            SettingsSection(title: "Feedback", kind: .rows([
                .defaultRow(.shareApp(appID: "1234567890")),
                .defaultRow(.rateApp(appID: "1234567890")),
                .defaultRow(.contactDeveloper(email: "support@example.com")),
                .defaultRow(.moreApps(developerID: "12345678")),
                .defaultRow(.telegram(id: "your_channel")),
                .defaultRow(.vkGroup(id: "123456789")),
                .defaultRow(.redeemCode)
            ])),

            SettingsSection(
                title: "More Apps",
                kind: .ourApps(developerID: "12345678", limit: 6, excludeAppID: "1234567890")
            ),

            SettingsSection(kind: .rows([
                .defaultRow(.about(
                    appID: "1234567890",
                    privacyURL: URL(string: "https://example.com/privacy")!,
                    termsURL: URL(string: "https://example.com/terms")!
                ))
            ]))
        ]
    }

    static func configuration(owner: SettingsControllerDelegate) -> SettingsConfiguration {
        SettingsConfiguration(
            title: "Settings",
            insets: SettingsInsets(top: 25),
            overlayAppID: "1234567890",
            sections: sections(),
            delegate: owner,
            productID: "com.example.premium.monthly"
        )
    }
}
```

Then present settings from any view controller:

```swift
final class ViewController: UIViewController {
    func openSettings() {
        SettingsController.present(configuration: SettingsComposition.configuration(owner: self), from: self)
    }
}
```

## Destinations

Every custom row, profile row and premium payload has at most one `SettingsDestination`:

```swift
// A controller with a default initializer.
.controller(NotificationsViewController.self)

// A factory for controllers that need arguments. It runs on the main actor, once per selection.
.factory { ProfileController(accountService: accountService) }

// An action: present your own UI, run a task, open a URL.
.action { context in
    let alert = UIAlertController(title: "Cache cleared", message: nil, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    context.viewController.present(alert, animated: true)
}
```

`SettingsActionContext` gives the presenting `viewController` and, for rows, the `tableView` and `indexPath`. Rows with `.controller` or `.factory` show a chevron and open in the navigation stack, or in the detail column on iPad and Duo. A premium destination is presented modally (full screen in compact width). A row whose destination is `nil` is inert.

The configuration retains factories and actions. If their owner also retains the settings controller or configuration, capture independent services or use a weak capture.

## Typed email diagnostics

Implement `settingsMailInfo()` on your `SettingsControllerDataProvider` (or `SettingsControllerDelegate`) to supply the User ID, product ID and premium status for support and language-request emails:

```swift
func settingsMailInfo() async -> SettingsMailInfo? {
    guard let profile = try? await Adapty.getProfile() else { return nil }
    let premium = profile.accessLevels["premium"] // Replace with your access level ID.
    return SettingsMailInfo(
        userID: profile.profileId,
        productID: premium?.vendorProductId,
        isPremium: premium?.isActive ?? false
    )
}
```

`User ID` in support emails and the built-in About screen comes only from `SettingsMailInfo.userID`; a missing value is shown as `-`. The package has no Adapty dependency. A default implementation returns `nil`. Typed values win over the `productID` and `isPremium` fallbacks.

The support form opens a draft in the user's mail app (`mailto:`). While the form holds a message, swiping it down or tapping Close asks before discarding it. A hint below the message shows how many characters are still needed; whitespace does not count. After the mail app opens the draft, a presented form closes itself. If no mail app can open it, the message stays and the user can copy the address or the full draft.

## Events and Dynamic Data

Use `SettingsControllerDelegate` when one object both receives events and provides data. For larger apps, pass separate `eventHandler` and `dataProvider` objects; the configuration retains those, while `delegate` is weak for the common `delegate: self` case.

```swift
extension ViewController: SettingsControllerDelegate {
    func settingsDidDismiss() {
        // Called after the modal settings controller is dismissed.
    }

    func settingsDidSelectAppColor(_ color: any AppColorType) {
        view.window?.tintColor = color.color
    }

    func settingsDidUpdateTheme(_ theme: ThemeStorage) {
        view.window?.overrideUserInterfaceStyle =
            theme.followsSystemAppearance ? .unspecified : (theme.interfaceStyle == .light ? .light : .dark)
    }

    func settingsDidUpdateTaptic(_ taptic: TapticStorage) {
        // Apply the haptic setting in your app.
    }

    func settingsCurrentUserInfo() async -> UserInfo? {
        UserInfo(name: "Vlad Likov", avatar: UIImage(named: "avatar"))
    }

    func settingsIsPremiumActive() async -> Bool {
        false
    }
}
```

`settingsDidSelectAppColor(_:)` has a default empty implementation. Call `await settingsController.refreshState()` after purchases, restores, account changes and profile edits; the latest refresh wins, and the profile and account state are requested concurrently. A nil user snapshot means "no new profile data"; return an explicit guest `UserInfo` for logout.

## Theme and Taptic Storage

The appearance and haptic screens write to objects that conform to `ThemeStorage` and `TapticStorage`. The raw values of `InterfaceStyle` (1, 2) and `TapticStyle` (0, 1, 2) match the integers stored by 4.x, so existing persisted values migrate directly.

```swift
import SettingsController

final class AppSettings: ThemeStorage, TapticStorage {
    // ThemeStorage
    var appColorID = AppColor.blue.rawValue
    var followsSystemAppearance = true
    var interfaceStyle = InterfaceStyle.light

    // TapticStorage
    var isTapticEngineEnabled = true
    var tapticStyle = TapticStyle.medium

    var accentColor: UIColor { AppColor(rawValue: appColorID)?.color ?? .systemBlue }
}
```

Choosing a strength on the Taptic screen plays a sample of it. The library's own feedback (selection haptics, confirmation alerts) is silent when `isTapticEngineEnabled` is false; the setting is read from the configuration's `.tapticEngine` row.

You can use the built-in `AppColor` values or provide your own color enum:

```swift
enum BrandColor: String, CaseIterable, AppColorType {
    case blue
    case mint

    var title: String {
        switch self {
        case .blue: "Blue"
        case .mint: "Mint"
        }
    }

    var color: UIColor {
        switch self {
        case .blue: .systemBlue
        case .mint: .systemMint
        }
    }
}

.defaultRow(.appearance(theme: settings, colors: BrandColor.allCases))
```

## Custom Rows

```swift
let row = SettingsRow(
    title: "Notifications",
    detail: "Enabled",
    icon: SettingsIcon(image: UIImage(systemName: "bell.fill"), color: .systemRed, padding: IconPadding()),
    destination: .controller(NotificationsViewController.self)
)

let actionRow = SettingsRow(
    title: "Clear Cache",
    icon: SettingsIcon(symbol: .trash.fill, color: .systemGray),
    destination: .action { _ in ImageCache.shared.removeAll() }
)

SettingsSection(title: "Advanced", kind: .rows([.row(row), .row(actionRow)]))
```

Rows that show a screen have a chevron. Rows that leave the app (review, more apps, Telegram, VK, Language) show an arrow; sheets and actions show no accessory.

## Settings Icon Generator

The cached icon renderer is also available outside `SettingsController`:

```swift
let image = SettingsIconGenerator.generate(systemName: "bell.fill", backgroundColor: .systemBlue)
let symbol = SettingsIconGenerator.generate(symbol: .star.fill, backgroundColor: .systemOrange)
let custom = SettingsIconGenerator.generate(
    image: UIImage(named: "BrandGlyph"), backgroundColor: .systemPurple, cacheIdentifier: "brand-glyph:v1")

let icon = SettingsIcon(symbol: .heart.fill, color: .systemRed)
let tile = icon.generateSettingsImage()
SettingsIconGenerator.removeAllCachedImages()
```

Images are cached by glyph, color, padding, size, corner radius, scale and interface style. `SettingsIcon(image:)` without a `cacheIdentifier` gets a unique identity at initialization, so create such icons once; in DEBUG builds the library logs a warning when many anonymous icons are rendered. Never reuse one explicit identifier for different pixels.

## Built-in Rows

`SettingsRowItem.DefaultRow` includes:

- `.user(name:avatar:destination:)`
- `.premium(_:)`
- `.appearance(theme:colors:)`
- `.tapticEngine(taptic:)`
- `.language`: opens the app's page in system Settings
- `.contactDeveloper(email:)`
- `.shareApp(appID:)`
- `.rateApp(appID:)`
- `.moreApps(developerID:)`
- `.telegram(id:)`
- `.vkGroup(id:)`
- `.redeemCode`: the offer code sheet (`AppStore.presentOfferCodeRedeemSheet` on iOS 16+)
- `.about(appID:privacyURL:termsURL:)`: build, device, account and locale diagnostics; every value offers Copy

## Premium Card

```swift
import SwiftUI

let card = PremiumCardPayload(
    image: Image(systemName: "sparkle"),
    title: "App Lock",
    tierTitle: "PRO",
    buttonTitle: "Upgrade",
    premium: PremiumPayload(isPremium: false, color: .systemYellow, destination: .controller(PaywallViewController.self))
)

SettingsSection(kind: .premiumCard(card))
```

The header has three inputs: `image`, regular-weight `title` and bold, host-localized `tierTitle` (for example `PRO` or `Plus`). The title stays on one row when it fits; narrow widths and accessibility text sizes use a stacked layout. The subtitle is available to VoiceOver but not shown. The CTA uses native glass-prominent styling on iOS 26+ and bordered-prominent earlier; the CTA and the card background open the same destination.

The card is measured once per content and text size and the result is shared by every settings presentation, so self-sizing does not repeat its SwiftUI layout. When your own appearance screen changes the accent, call `settingsController.updatePremiumColor(newColor)`; the built-in Appearance screen does this automatically.

## Presentation Options

Presentation helpers are `@MainActor`.

```swift
// Present full screen with the library's split container.
SettingsController.present(configuration: configuration, from: self)

// Or get the split container and present or embed it yourself.
let controller = SettingsController.makeSplitPresentation(configuration: configuration)
present(controller, animated: true)

// Or push the list into your own navigation stack; your navigation bar settings are kept.
navigationController?.pushViewController(SettingsController(configuration: configuration), animated: true)
```

On iOS 27.0 and later the library uses a column-style `UISplitViewController`; on iOS 27.1 an active division (iPhone Duo) requests equal 50/50 columns, with Settings in the primary pane. UIKit owns fold avoidance, safe areas and compact/expanded transitions. iOS 15–26 keep the classic split presentation.

## App Store and URL Notes

- `shareApp`, `rateApp`, `about`, `overlayAppID` and `ourApps` expect App Store IDs as strings.
- `.ourApps(developerID:limit:excludeAppID:)` fetches apps from the App Store, hides the excluded app, and keeps successful results in memory for ten minutes. A limit at or below zero, or an empty result, hides the section; errors show a retry row.
- Tapping an app shows progress on its row until the App Store page is ready; a second tap does not restart the request.
- `.telegram(id:)` expects the channel or username without `@`; `.vkGroup(id:)` expects the numeric group ID without `club`.
- Review, More Apps, Telegram and VK try the app link and fall back to the web page. `LSApplicationQueriesSchemes` entries are no longer needed.
- `overlayAppID` shows an App Store overlay once per presentation; it is dismissed when another screen is pushed and is not shown again until the next presentation.

## Project Structure

```text
Sources/SettingsController
+-- Core
|   +-- Configuration     SettingsConfiguration, delegate protocols
|   +-- Diagnostics       signposts and sizing counters
|   +-- Mail              MailType, drafts, diagnostics
|   +-- Models            rows, destinations, icons, premium payloads
|   +-- Protocols         ThemeStorage, TapticStorage, AppColorType
|   +-- Services          App Store, images, request lifetimes, deduplication
+-- Resources             string catalog, assets, privacy manifest
+-- UI
    +-- Controllers       settings, about, mail, preferences, split presentation
    +-- Presentation      titles and icons of built-in rows and options
    +-- Shared            row metrics, accessories, haptics
    +-- Views             cells and components (premium card and its measurer)
```

## Dependencies

- AlertKit
- SafeSFSymbols
- CheckUpdate (1.0.1+)

## Localization

Built-in strings and images load from the package resource bundle; the catalog is `Sources/SettingsController/Resources/Localizable.xcstrings`. Localize custom row titles in the consuming app. Language availability follows the app's supported localizations; the language row opens system app settings.

## Testing and Contributing

Use Xcode 27.1 or later (Swift 6.4+) with an installed iOS Simulator runtime:

```bash
bash scripts/test-ios.sh
DEVICE_FAMILY=iPad bash scripts/test-ios.sh
python3 scripts/validate-resources.py
xcrun swift format lint --strict --recursive Sources Tests Examples Package.swift
bash scripts/test-example.sh
```

UIKit requires an iOS Simulator; plain macOS `swift test` is not supported. Tests run without App Store access or credentials. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

Instruments users can follow the `SettingsController` Points of Interest signposts `PremiumCell sizing` and `PremiumCard measurement`.

## License

[MIT](LICENSE). Dependencies retain their own licenses.
