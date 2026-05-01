# SettingsController

SettingsController is a modular UIKit settings screen for iOS apps. It gives you a ready-to-present `UITableViewController` with common settings flows: appearance, haptics, language, premium, support, App Store actions, social links, app metadata, and an App Store "more apps" section.

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

- iOS 14.0+
- Swift 6.0+
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
.package(url: "https://github.com/VladLikov/SettingsController.git", from: "2.8.8")
```

Then add `SettingsController` to your target dependencies.

## Quick Start

```swift
import UIKit
import SettingsController

final class ViewController: UIViewController {
    private let themeStorage = AppThemeStorage()
    private let tapticStorage = AppTapticStorage()

    func openSettings() {
        let configuration = SettingsConfiguration(
            title: "Settings",
            overlayAppID: "1234567890",
            sections: [
                SettingsSection(kind: .rows([
                    .defaultRow(.user("Vlad Likov", UIImage(named: "avatar"), ProfileViewController.self)),
                    .defaultRow(.premium(
                        PremiumPayload(
                            isPremium: false,
                            color: .systemYellow,
                            vc: PaywallViewController.self,
                            action: nil
                        )
                    ))
                ])),

                SettingsSection(title: "Preferences", kind: .rows([
                    .defaultRow(.appearance(theme: themeStorage)),
                    .defaultRow(.tapticEngine(taptic: tapticStorage)),
                    .defaultRow(.language(email: "support@example.com"))
                ])),

                SettingsSection(title: "App", kind: .rows([
                    .defaultRow(.shareApp(appID: "1234567890")),
                    .defaultRow(.rateApp(appID: "1234567890")),
                    .defaultRow(.contactDeveloper(email: "support@example.com")),
                    .defaultRow(.telegram(id: "your_channel")),
                    .defaultRow(.vkGroup(id: "123456789")),
                    .defaultRow(.about(
                        userID: "user-123",
                        appID: "1234567890",
                        privacyURL: URL(string: "https://example.com/privacy")!,
                        termsURL: URL(string: "https://example.com/terms")!
                    ))
                ])),

                SettingsSection(
                    title: "More Apps",
                    kind: .ourApps(developerID: "12345678", limit: 4, excludeAppID: "1234567890")
                )
            ],
            delegate: self
        )

        SettingsController.present(configuration: configuration, from: self)
    }
}
```

## Delegate

Use `SettingsControllerDelegate` to receive changes and provide dynamic data.

```swift
extension ViewController: SettingsControllerDelegate {
    func settingsDidDismiss(_ initialValues: [AnyKeyPath: Any]?) {
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

    func settingsUserInfoRequested(_ request: (UserInfo) -> Void) {
        request(UserInfo(name: "Vlad Likov", avatar: UIImage(named: "avatar")))
    }

    func settingsPremiumStatusRequested(_ request: (Bool) -> Void) {
        request(false)
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

    var iconName: String { rawValue }
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
    vc: NotificationsViewController.self
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

## Built-in Rows

`SettingsRowData.DefaultRow` includes:

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
    vc: PaywallViewController.self,
    action: nil
)

let card = PremiumCardPayload(
    image: Image(systemName: "star.fill"),
    title: "Go Premium",
    subtitle: "Unlock all features",
    buttonTitle: "Upgrade",
    base: premium
)

SettingsSection(kind: .premiumCard(card))
```

## Presentation Options

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
|   +-- Helpers
|   +-- Models
|   +-- Protocols
|   +-- Services
+-- Resources
+-- UI
    +-- Controllers
    +-- Extensions
    +-- Views
```

## Dependencies

The package currently uses:

- AlertKit
- SafeSFSymbols
- SwiftBoost
- CheckUpdate

## License

MIT.
