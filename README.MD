# SettingsController

SettingsController is a modular UIKit settings screen for iOS apps. It gives you a ready-to-present `UITableViewController` with common settings flows: appearance, haptics, language, premium, support, App Store actions, social links, app metadata, and an App Store "more apps" section.

SettingsController is used across a portfolio of production iOS apps and is available to other developers through Swift Package Manager.

The package is built with Swift Package Manager and is intended to be configured from your app code without subclassing the settings controller.

## Features

- UIKit-first `SettingsController` based on `UITableViewController`
- iPhone modal presentation and iPad split-view presentation
- Built-in rows for appearance, haptics, language, premium, support email, Telegram, VK, App Store review/share, redeem code, and about screen
- Custom rows with your own icon, detail text, action, or destination controller
- Optional user profile row
- Premium row and premium card support
- App Store "our apps" section loaded by developer id
- Theme and taptic updates reported through delegate callbacks
- Localized resources via Swift Package resources

## Requirements

- iOS 15.0+
- Swift 6.3+
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
.package(url: "https://github.com/VladLikov/SettingsController.git", from: "3.1.0")
```

Then add `SettingsController` to your target dependencies.

**Upgrading from 2.8.8:** version 3.0.0 contains breaking API changes.
Read [MIGRATION.md](MIGRATION.md) before updating. For the old release, see the
[README at 2.8.8](https://github.com/VladLikov/SettingsController/blob/2.8.8/README.MD).

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

Create a small helper in your app and keep the settings composition in one place. In this example, `AppSettings.shared` is your app storage object that conforms to `ThemeStorage` and `TapticStorage`.

```swift
import UIKit
import SwiftUI
import SettingsController

struct SettingsControllerHelper {
    private static let settings = AppSettings.shared

    static func setupTitle() -> String {
        "Settings"
    }

    static func setupInsets() -> SettingsInsets {
        .init(top: 25)
    }

    static func setupOverlayAppID() -> String? {
        "1234567890"
    }

    static func setupSections() -> [SettingsSection] {
        let isPremium = settings.isPremium

        let premiumPayload = PremiumPayload(
            isPremium: isPremium,
            color: settings.appColor,
            destinationControllerType: nil
        ) { fromVC in
            let paywall = PaywallViewController()
            fromVC.present(paywall, animated: true)
        }

        let premiumSection: SettingsSection = isPremium
            ? SettingsSection(kind: .rows([.defaultRow(.premium(premiumPayload))]))
            : SettingsSection(kind: .premiumCard(.init(
                image: Image(systemName: "star.fill"),
                title: "Go Premium",
                subtitle: "Unlock all features",
                buttonTitle: "Upgrade",
                premium: premiumPayload
            )))

        return [
            premiumSection,

            SettingsSection(title: "App", kind: .rows([
                .row(.init(
                    title: "Notifications",
                    icon: .init(image: UIImage(systemName: "bell.fill"), color: .systemRed, inset: .init()),
                    destinationControllerType: NotificationsViewController.self
                )),
                .defaultRow(.appearance(theme: settings)),
                .defaultRow(.tapticEngine(taptic: settings)),
                .defaultRow(.language(email: "support@example.com"))
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
                    userID: settings.userID,
                    appID: "1234567890",
                    privacyURL: URL(string: "https://example.com/privacy")!,
                    termsURL: URL(string: "https://example.com/terms")!
                ))
            ]))
        ]
    }
}

extension SettingsConfiguration {
    static func setup(owner: SettingsControllerDelegate?) -> SettingsConfiguration {
        .init(
            title: SettingsControllerHelper.setupTitle(),
            insets: SettingsControllerHelper.setupInsets(),
            overlayAppID: SettingsControllerHelper.setupOverlayAppID(),
            sections: SettingsControllerHelper.setupSections(),
            delegate: owner
        )
    }
}
```

Then present settings from any view controller:

```swift
final class ViewController: UIViewController {
    func openSettings() {
        SettingsController.present(
            configuration: .setup(owner: self),
            from: self
        )
    }
}
```

## Events and Dynamic Data

Available from **3.1.0**. Pass `subscriptionID` to `SettingsConfiguration(sections: sections, subscriptionID: subscriptionID)` to include the app's subscription identifier in support and language-request emails. When presenting `MailController` directly, pass its optional `subscriptionID` argument. The email's user information shows `Subscription ID: -` when no identifier is supplied. Existing initializer calls remain valid.

Use `SettingsControllerDelegate` when the same object both receives settings events and provides dynamic data. For larger apps, pass separate `eventHandler` and `dataProvider` objects to `SettingsConfiguration`; those separate objects are retained by the configuration, while `delegate` is weak for the common `delegate: self` case.

```swift
extension ViewController: SettingsControllerDelegate {
    func settingsDidDismiss() {
        // Called after the modal settings controller is dismissed.
    }

    func settingsDidUpdateTheme(_ theme: ThemeStorage) {
        view.tintColor = theme.appColor

        let style: UIUserInterfaceStyle
        if theme.autoTheme {
            style = .unspecified
        } else {
            style = theme.interfaceStyle == 1 ? .light : .dark
        }

        view.window?.overrideUserInterfaceStyle = style
    }

    func settingsDidUpdateTaptic(_ taptic: TapticStorage) {
        // Persist or apply taptic settings in your app.
    }

    func settingsCurrentUserInfo() async -> UserInfo? {
        UserInfo(name: "Vlad Likov", avatar: UIImage(named: "avatar"))
    }

    func settingsIsPremiumActive() async -> Bool {
        false
    }
}
```

## Theme and Taptic Storage

The appearance and haptic screens mutate objects that conform to `ThemeStorage` and `TapticStorage`. A simple implementation can look like this:

```swift
import UIKit
import SettingsController

final class AppThemeStorage: ThemeStorage {
    var appColorRawValue: String = AppColor.blue.rawValue
    var autoTheme: Bool = true
    var interfaceStyle: Int = 1 // 1 = light, 2 = dark

    var appColor: UIColor {
        get {
            AppColor(rawValue: appColorRawValue)?.color ?? .systemBlue
        }
        set {
            if let color = AppColor.allCases.first(where: { $0.color == newValue }) {
                appColorRawValue = color.rawValue
            }
        }
    }
}

final class AppTapticStorage: TapticStorage {
    var tapticStyle: Int = 1 // 0 = light, 1 = medium, 2 = hard
    var tapticEngine: Bool = true
}
```

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
```

Then pass it to the appearance row:

```swift
.defaultRow(.appearance(theme: themeStorage, colors: BrandColor.allCases))
```

## Custom Rows

Use `SettingsRow` when a built-in row does not cover your case.

```swift
let row = SettingsRow(
    title: "Notifications",
    detail: "Enabled",
    icon: SettingsIcon(
        image: UIImage(systemName: "bell.fill"),
        color: .systemRed,
        inset: Inset()
    ),
    destinationControllerType: NotificationsViewController.self
)

let actionRow = SettingsRow(
    title: "Clear Cache",
    icon: SettingsIcon(image: UIImage(systemName: "trash.fill"), color: .systemGray),
    action: { indexPath, tableView, controller in
        tableView.deselectRow(at: indexPath, animated: true)
        // Clear cache and show your own result UI.
    }
)
```

Add them to a section:

```swift
SettingsSection(title: "Advanced", kind: .rows([
    .row(row),
    .row(actionRow)
]))
```

## Settings Icon Generator

You can also use the same cached icon renderer outside `SettingsController`.
Rendering is handled inside `SettingsController` and includes caching, trait-aware color keys, optional insets, and `SettingsIcon` integration.

```swift
let image = SettingsIconGenerator.generate(
    systemName: "bell.fill",
    backgroundColor: .systemBlue
)

let safeSymbolImage = SettingsIconGenerator.generate(
    symbol: .star.fill,
    backgroundColor: .systemOrange
)

let customImage = SettingsIconGenerator.generate(
    image: UIImage(named: "BrandGlyph"),
    backgroundColor: .systemPurple,
    cacheIdentifier: "brand-glyph"
)
```

For an existing `SettingsIcon`:

```swift
let settingsIcon = SettingsIcon(symbol: .heart.fill, color: .systemRed)
let image = settingsIcon.generateSettingsImage()
```

Generated images are cached by glyph, color, inset, size, corner radius, scale, and interface style. If needed, clear the cache:

```swift
SettingsIconGenerator.removeAllCachedImages()
```

## Built-in Rows

`SettingsRowItem.DefaultRow` includes:

- `.user(_:_:_:)`
- `.premium(_:)`
- `.appearance(theme:colors:)`
- `.tapticEngine(taptic:)`
- `.language(email:)`
- `.contactDeveloper(email:)`
- `.shareApp(appID:)`
- `.rateApp(appID:)`
- `.moreApps(developerID:)`
- `.telegram(id:)`
- `.vkGroup(id:)`
- `.redeemCode`
- `.about(userID:appID:privacyURL:termsURL:)`

## Premium Card

Use `.premiumCard` when you want a larger call-to-action instead of a regular premium row.

```swift
import SwiftUI

let premium = PremiumPayload(
    isPremium: false,
    color: .systemYellow,
    destinationControllerType: PaywallViewController.self,
    action: nil
)

let card = PremiumCardPayload(
    image: Image(systemName: "star.fill"),
    title: "Go Premium",
    subtitle: "Unlock all features",
    buttonTitle: "Upgrade",
    premium: premium
)

SettingsSection(kind: .premiumCard(card))
```

## Presentation Options

Presentation helpers are `@MainActor`, because UIKit presentation must happen on the main actor.

Present immediately:

```swift
SettingsController.present(configuration: configuration, from: self)
```

Or get a configured split presentation controller and present it yourself:

```swift
let controller = SettingsController.getSplitPresentationSettingsController(configuration: configuration)
present(controller, animated: true)
```

You can also instantiate and push the controller in your own navigation flow:

```swift
let controller = SettingsController(configuration: configuration)
navigationController?.pushViewController(controller, animated: true)
```

## App Store and URL Notes

- `shareApp`, `rateApp`, `about`, `overlayAppID`, and `ourApps` expect App Store ids as strings.
- `.ourApps(developerID:limit:excludeAppID:)` fetches apps from the App Store and hides the current app id.
- `.telegram(id:)` expects the channel or username without `@`.
- `.vkGroup(id:)` expects the numeric group id, without `club`.
- If you want `tg://` and `vk://` deep links to open installed apps, add the URL schemes to `LSApplicationQueriesSchemes` in your app's `Info.plist`.

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>tg</string>
    <string>vk</string>
</array>
```

## Project Structure

```text
Sources/SettingsController
+-- Core
|   +-- Configuration
|   +-- Mail
|   +-- Models
|   |   +-- AppStore
|   |   +-- Common
|   |   +-- Premium
|   |   +-- Settings
|   +-- Protocols
|   +-- Services
|       +-- AppReview
|       +-- AppStore
|       +-- Image
+-- Resources
+-- UI
    +-- Controllers
    |   +-- About
    |   +-- Mail
    |   +-- Preferences
    |   +-- Presentation
    |   +-- Settings
    +-- Extensions
    +-- Views
        +-- Cells
        |   +-- AppStore
        |   +-- Mail
        |   +-- Premium
        |   +-- Settings
        +-- Components
            +-- EmptyState
            +-- Premium
```

## Dependencies

The package currently uses:

- AlertKit
- SafeSFSymbols
- CheckUpdate (1.0.0+)
- SwiftBoost

## Localization

Built-in strings and images are loaded from the Swift Package resource bundle.
The string catalog is `Sources/SettingsController/Resources/Localizable.xcstrings`.
Localize custom row titles in the consuming app. Language availability follows
that app's supported localizations; the language row opens system app settings.

## Testing and Contributing

Use Xcode 26.6 with its iOS Simulator runtime for the CI configuration:

```bash
bash scripts/test-ios.sh
```

The script resolves dependencies and builds and tests the package on an available
iPhone simulator. Override `SIMULATOR_ID` to choose a specific device.
Tests run without App Store access or credentials. UIKit requires an iOS
Simulator; plain macOS `swift test` is not supported.
See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow and
[CHANGELOG.md](CHANGELOG.md) for unreleased changes.

## License

[MIT](LICENSE). Dependencies retain their own licenses.
