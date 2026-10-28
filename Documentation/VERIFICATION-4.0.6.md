# SettingsController 4.0.6 verification

2026-10-28. Patch to 4.0.5. Fix implementation: 7288c41. No production changes after verification; release branch applies the same fix to published main.

## Change

Selecting an app color in Appearance now immediately updates existing premium-card gradient and CTA. A weak callback passes the selected color to SettingsController, updates its rendered projection and reconfigures only visible premium cards. Offscreen cards acquire the new projection when displayed. No full table reload or catalog/image request is triggered by this update. Repeated identical color updates are ignored. The color survives premium activation and card restoration; original configuration snapshots and destination callbacks are preserved.

## Completed checks

- Before the fix: regression reproduced through existing Settings -> Appearance selection; both immediate and rebuilt card color assertions failed.
- After the fix: 13 package tests passed (heading 3, state 9, theme selection 1). Final focused run passed 2 theme tests, including activation/restoration. Total: 14 unique passing tests across these runs.
- Resource validator passed: 80 keys, 51 locales, placeholders and privacy structure. git diff --check passed.
- Environment: Duo simulator iOS 27.1, Xcode 27.1 / Swift 6.4, deployment target 15.0.

## Limits and evidence

No fresh rendered UI/device run, full accessibility audit or iOS 15 runtime check. Existing release limits remain applicable. No duplicate full CI matrix is represented as a fresh pass.

Owner-facing logs: chat outputs/premium-live-color/{red,green,final}.log and RESULT.md. Release readback: outputs/release-4.0.6/.
