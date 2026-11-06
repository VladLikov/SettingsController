# 5.0 verification

## 5.0.1 update

On a 375 pt iPhone the 5.0 premium card stacked where 4.0.8 showed one row: the offscreen measurement of the one-row card (346 pt) was wider than the cell (343 pt), while `ViewThatFits` in the cell fit it. 5.0.1 lets `ViewThatFits` decide in the cell again and caches only the resulting height (per content, text size and width) and the palette; first open lays the card out once, reloads and later presentations zero times. The offscreen-measurement and layout-parity results in the "PremiumCell sizing" section below describe 5.0.0 only.

5.0.1 also replaces the premium palette (one hue, two stops, white text at 4.5:1 or 7:1 with Increase Contrast, also under the CTA fill) and uses the native glass or bordered CTA rendered for a dark surface. With this palette the stacked card's CTA is back at the leading edge and the iPad accessibility audit passes. Actionable rows show chevrons again; More Apps shows an arrow.

Local results (Xcode 27.2, iOS 27.2): package tests on iPhone and iPad pass; example UI tests pass on iPhone 18 Pro (17), iPad Pro 11-inch (16 + 1 phone-only skip) and iPhone 13 mini (17, including the 72 pt one-row card at 375 pt). Card screenshots in all eight `AppColor` values, light and dark, were reviewed on the iPhone 13 mini.


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

## Animations and translations

Only system animations remain: table section updates with `.automatic` and the existing insert/delete of preference sections. There are no `UIView.animate` or `UIView.transition` calls in the package.

The three new strings were reviewed in context for all 51 locales: the counter reads as "characters still missing" rather than "characters required", "Discard Message" uses each language's delete wording instead of "reject" or "ignore", and verbs and nouns match the existing Copy Message, Message and Cancel translations. They are marked `translated` in the catalog.

## GitHub CI findings

The first CI run of this branch failed two iPad example UI tests that fail identically on the 4.0.8 code: the premium card height assertion expected the one-row pill, but the iPad settings column (288 pt) stacks the card by design; and the accessibility audit reported a contrast failure for the stacked card. Experiments isolated the cause to the glass CTA at the leading edge, over the darker start of the gradient. The stacked CTA is now trailing-aligned like the one-row card, and the height test expects a stacked card on iPad. One iPhone test failed because the example app stopped before its first interaction on the runner; it passes locally.

After the fix: example UI tests on iPad 16 passed and 1 skipped (phone-only), on iPhone 17 passed.

## Not verified

- iPhone 12 mini Release Time Profiler for PremiumCell (target at or below 3 ms).
- iOS 15 runtime (only the deployment-target build was compiled), physical mail handlers, real StoreKit and offer code sheets.
- Full VoiceOver traversal and the haptic preview on hardware.
- GitHub CI on the `xcode-27` image for the final commit.
