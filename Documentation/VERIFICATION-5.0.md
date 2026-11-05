# 5.0 verification

Date: 5 November 2026. Toolchain: Xcode 27.2 (27B52), Swift 6.4.4, iOS 15.0 deployment target. Simulators: iOS 27.2 iPhone, iPad Pro 11-inch (M5), iPhone Duo.

## Automated results

| Gate | Result |
| --- | --- |
| `scripts/test-ios.sh`, iPhone | 125 tests, 1 skipped (Duo-only policy test), 0 failures |
| `scripts/test-ios.sh`, iPad | 125 tests, 0 failures |
| `scripts/test-ios.sh`, iPhone Duo (`IOS_RUNTIME=27.2-iPhone19-4`) | 125 tests, 1 skipped, 0 failures |
| `scripts/test-example.sh`, iPhone (public example UI tests, plain `import`) | 17 tests, 0 failures |
| `scripts/validate-resources.py` | 83 keys, 51 locales, placeholders and privacy manifest valid |
| `swift format lint --strict` (Sources, Tests, Examples, Package.swift) | no findings |
| Compiler warnings in package sources and tests (clean build) | none |

The final runs are recorded in `.build/verification/final-*` and `.build/example-results/final-example` (not committed).

## PremiumCell sizing

Measured with `PremiumCardSizingStatistics` and the `PremiumCell sizing` / `PremiumCard measurement` signposts, in a 375 pt window that mounts the real split presentation.

| | 4.0.8 | 5.0 |
| --- | --- | --- |
| SwiftUI layouts on first open, horizontal card | one per self-sizing call (UIKit asks twice: on cell creation and for row heights) | 1 |
| SwiftUI layouts on first open, card that stacks | one per call, each with a `ViewThatFits` trial | 2 (fit check + stacked height) |
| SwiftUI layouts on reload, second open, wider window | one per call | 0 |
| Row estimate | fixed 72 pt | last measured height |
| Palette | rebuilt in every `body` | cached per color, style and contrast |

Simulator timing, first open including the SwiftUI cold start of the test process: 113–166 ms before, 2–8 ms of measurement work after (Debug and Release). These numbers come from an Apple-silicon simulator and are not a substitute for the device target in the original report (iPhone 12 mini Release, `PremiumCell.systemLayoutSizeFitting` at or below 3 ms). That device check remains open.

Layout parity: for 3 card contents × 5 text sizes (small to AX5) × 7 widths (288–700 pt), the measured height equals the 4.0.8 `ViewThatFits` card height within 1 pt, and both horizontal and stacked layouts occur.

The modal presentation of the original trace (sheet width changes during presentation) cannot be reproduced in the package test host, which has no UIScene.

## Visual checks

The example UI tests' screenshots were reviewed for: settings list accessories (chevrons only on screens, arrow on Language), horizontal premium card, active premium row, profile glyph without avatar, About in German, Russian and Arabic (localized premium status, RTL layout), AX5 RTL settings, mail recovery alert, Appearance.

## Not verified

- iPhone 12 mini Release Time Profiler for PremiumCell (target at or below 3 ms).
- iOS 15 runtime (only the deployment-target build was compiled), physical mail handlers, real StoreKit and offer code sheets.
- Full VoiceOver traversal, Reduce Motion behavior of the new cross-fades, and the haptic preview on hardware.
- Native-speaker review of the three new strings (`Discard Message`, `Characters needed: %ld`, `Copy`), marked `needs_review` in the catalog.
- GitHub CI on the `xcode-27` image for the final commit.
