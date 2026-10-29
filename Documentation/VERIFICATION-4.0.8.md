# SettingsController 4.0.8 verification

2026-10-29. Patch to 4.0.7. Implementation: 0f938f6. Release branch applies the same change onto published main; subsequent edits are documentation only.

## Change

Install the existing standard modal Close UIBarButtonItem in viewWillAppear rather than viewDidAppear. UIKit calls viewWillAppear before configuring presentation animations, while viewDidAppear runs after animations finish. Conditional modal detection remains intact; embedded settings do not gain a modal Close item. No navigation appearance/shared-glass overrides or custom bar-button views are introduced. SwiftMate source and dependency configuration are unchanged.

## Completed checks

- RED: modal-navigation and presentation-root tests reproduced the missing item before didAppear; embedded case passed.
- GREEN: 3 Close timing tests and 9 state regressions passed (12 total), iOS 27.1 simulator.
- Native sample built cleanly through Apple Xcode MCP. Full-screen modal showed the native Close item; tapping it dismissed settings and restored the home buttons. Session was closed.
- git diff --check passed.

## Limits and evidence

The native UI check confirms settled appearance and dismissal, not a frame-by-frame timing measurement. Unit tests verify item installation before didAppear. No fresh physical-device or iOS 15 runtime verification, full accessibility audit, or repeated full test matrix.

Logs, screenshots and QA report: chat outputs/close-button-timing/. Release readback: outputs/release-4.0.8/. Prior release limitations remain applicable.
