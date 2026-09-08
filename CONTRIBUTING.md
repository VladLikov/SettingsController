# Contributing

Use macOS, Xcode with Swift 6.3 or newer, and an installed iOS Simulator runtime.
CI uses Xcode 26.6. The library supports iOS 15 and newer.

```bash
git clone https://github.com/VladLikov/SettingsController.git
cd SettingsController
open Package.swift
bash scripts/test-ios.sh
```

In Xcode, select the SettingsController scheme and an iPhone simulator, then
Build or Test. The test script uses the same scheme and resolves dependencies.
Set `SIMULATOR_ID` to an available simulator UUID to override automatic selection.

Keep pull requests focused and preserve public API and iOS 15 compatibility.
Follow the surrounding Swift style. Add regression tests for behavior fixes;
avoid unrelated formatting and unnecessary dependencies. Document public API
behavior and provide translator context for new localized strings.

Before submitting, run tests and `git diff --check`. Describe what changed,
why, and what you tested. Never include credentials or production secrets.

For bugs, include Xcode/iOS versions, reproduction steps, expected and actual
behavior, and a minimal example where possible. Remove personal data from logs.
