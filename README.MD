# SettingsController

🎛️ A modular, customizable UIKit settings screen for iOS apps.  
Powered by Swift Package Manager. Designed to be dropped in and used in minutes.

---

## ✨ Features

- 📱 Ready-to-use settings controller (`SettingsController`)
- 🧩 Supports appearance (themes), haptics, language selection, premium actions, and more
- 🧍 User profile section
- 🛍 App Store integration (rate app, share app, "our apps")
- 💬 Social/contact rows: Telegram, VK, email
- 💻 iPad split-screen support
- 🎯 Delegate-based customization (no subclassing)
- 📦 Fully modular SwiftPM package

---

## 📦 Installation

Using [Swift Package Manager](https://developer.apple.com/documentation/swift_packages):

```swift
.package(url: "https://github.com/vladlikov/SettingsController.git", from: "1.0.0")

Then add "SettingsController" to your target dependencies.

⸻

🚀 Quick Start

1. Create config

import SettingsController

let config = SettingsConfiguration(
    title: "Settings",
    sections: [
        SettingsSection(title: "Interface", kind: .rows([
            .defaultRow(.appearance),
            .defaultRow(.tapticEngine),
            .defaultRow(.language("support@example.com"))
        ])),
        SettingsSection(title: "Info", kind: .rows([
            .defaultRow(.contactDeveloper("support@example.com")),
            .defaultRow(.telegram(id: "@yourchannel")),
            .defaultRow(.vkGroup(id: "vkclub123"))
        ])),
        SettingsSection(title: "More", kind: .ourApps(developerId: "12345678", limit: 4))
    ],
    overlayAppID: "1234567890",
    initialValues: .init(appColorIndex: 0, tapticStyle: 1),
    delegate: self
)

2. Present controller

SettingsController.present(from: self, with: config)

✅ Can be presented modally or pushed into navigation stack.

⸻

👤 Implement Delegate

extension YourViewController: SettingsControllerDelegate {
    func settingsUserInfoRequested() -> UserInfo? {
        .init(name: "John Appleseed", avatar: UIImage(named: "avatar"))
    }

    func settingsPremiumActionTriggered() {
        // show your paywall
    }

    func settingsDidRequestDismiss() {
        dismiss(animated: true)
    }
}

More hooks available:
settingsAppColorDidChange(_:), settingsTapticStyleDidChange(_:), settingsIsPremiumRequested()

⸻

🌙 Appearance & Haptics

You control app theme & haptics via two protocols:

protocol ThemeStorage {
    var appColor: UIColor { get set }
    var appColorIndex: Int { get set }
    var autoTheme: Bool { get set }
    var interfaceStyle: Int { get set }
}

protocol TapticStorage {
    var tapticStyle: Int { get set }
    var tapticEngine: Bool { get set }
}

Provide your own storage, e.g. backed by UserDefaults.

⸻

📂 Structure

SettingsController/
├── Core/         // Configuration, models, storage protocols
├── UI/           // Controllers, cells, reusable views
├── Services/     // App Store, notifications
├── Extensions/   // UIKit/Foundation helpers
├── Resources/    // xcstrings, assets



⸻

📄 License

MIT © vladlikov

⸻

🙌 Contribute / Feedback

Feel free to open issues or submit pull requests.

---
