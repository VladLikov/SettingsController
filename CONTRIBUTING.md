# Contributing

Use macOS, Xcode with Swift 6.4 or newer, and an installed iOS Simulator runtime.
CI requires Xcode 27.1. The library supports iOS 15 and newer.

```bash
git clone https://github.com/VladLikov/SettingsController.git
cd SettingsController
open Package.swift
bash scripts/test-ios.sh
```

In Xcode, select the SettingsController scheme and an iPhone simulator, then
Build or Test. The test script uses the same scheme and resolves dependencies.
It picks the first available simulator of `DEVICE_FAMILY` (`iPhone` or `iPad`)
for `IOS_RUNTIME` (default: the installed SDK version). Set `DEVICE_NAME` to an
exact simulator name, for example `DEVICE_NAME="iPhone 18 Pro"`, to choose one.

Keep pull requests focused and preserve public API and iOS 15 compatibility.
Follow the surrounding Swift style. Add regression tests for behavior fixes;
avoid unrelated formatting and unnecessary dependencies. Document public API
behavior and provide translator context for new localized strings.

Format with the toolchain's swift-format before submitting; CI runs
`xcrun swift format lint --strict --recursive Sources Tests Examples Package.swift`.
Run tests and `git diff --check`. Describe what changed,
why, and what you tested. Never include credentials or production secrets.

For bugs, include Xcode/iOS versions, reproduction steps, expected and actual
behavior, and a minimal example where possible. Remove personal data from logs.
