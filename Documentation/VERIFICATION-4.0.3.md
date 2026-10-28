# SettingsController 4.0.3 verification

2026-10-28. Patch to 4.0.2 (`35b797d9170630eaf32bb294b7f2c0e17b9a8473`). The owner explicitly authorized publication. Existing release tags remain unchanged. Public API, dependencies, iOS 15 minimum and Swift 6.4 / Xcode 27.1 requirements are unchanged.

## Changes

Mail keeps a failed draft pending when its error alert cannot be presented immediately, retrying on form appearance, application activation and transition completion. Text remains editable and Send is restored. Editing, closing or starting another attempt revokes the old error. Existing localized recovery actions are reused; no new host plist requirement or restriction to Apple Mail is introduced.

Premium restores distinct gradient stops, keeps white foregrounds and uses a real native `.glassProminent` CTA on iOS 26+. The CTA has a lighter tone in the gradient family and a light outline. The card background remains tappable, without nesting buttons or adding whole-card press animation. A single accessibility action still represents the card. Earlier OS versions keep the outlined fallback.

## Validation actually performed

| Scope | Result | Revision / destination |
|---|---|---|
| Mail builder, resolver, Mail regressions and patch regressions | 27 passed, 0 failed, 1 skipped | `b5e17fa`, Duo iOS 27.1; genuinely expanded iPad-only StoreKit scenario skips on the closed phone. |
| Native unavailable-mail UI | 1 passed, 0 failed/skipped | iPad iOS 27.0; real mailto opening refusal shows recovery, Cancel preserves text and enables Send. This UI build precedes the final transition-completion refinement; that refinement compiled in package verification, but a real animated transition completion was not directly exercised. |
| Premium palette | 1 passed, 0 failed/skipped | Final production PremiumCard code at `444d6f1`, Duo iOS 27.1; distinct gradient/CTA tones and calculated white-text contrast checked across host colors and light/dark traits. This calculation is not a rendered-glass audit. |
| Premium CTA and card-background taps | 1 passed, 0 failed/skipped | Final code, iPhone Settings Verification iOS 27.0: CTA opens paywall, standard Close dismisses it, card-heading tap opens paywall. |
| Dark / large text / RTL | 1 passed, 0 failed/skipped | Final premium production code, iPhone iOS 27.0. Screenshots inspected; no visible clipping or overlap. |
| Resource structure | Passed | 80 keys, 51 locales, placeholder parity, comments and privacy plist structure. No new translation keys. |
| Whitespace / source consistency | Passed | `git diff --check`; only release documents changed after the checks above. |

Toolchain: Xcode 27.1 (27A9275), Swift 6.4, Debug, package/sample deployment 15.0. Apple Xcode MCP built the real host successfully. For the sample's known missing-package-product issue, XcodeBuildMCP supplied supported UI build/test fallback. No duplicate full UI matrix is represented as a fresh pass.

Earlier attempts remain recorded: the first premium compile needed an explicit accessibility action kind; the first premium UI attempt passed dark/RTL and reached the paywall, then failed because the test expected capitalized Close. A stable identifier fixed that selector and only the affected case was repeated. Mail package transition fixtures also had failures/timeouts; the final window-detachment regression preserves assertions on the alert, text and Send without relying on an unsupported full-screen transition in the package test host. Failed/interrupted attempts are not counted as passes.

## Physical iPhone 12 mini: limits

The exact physical iPhone 12 mini (iOS 27.2) was inspected. Before updating, Settings → Contact Developer actually opened an Apple Mail draft: the reported failure was **not reproduced**. No email was sent; only the owned QA draft was deleted.

AppLock was built and updated over the existing installation with the same bundle ID, version/build and signing team. No app deletion, data reset, signing change, Mail setting or entitlement change occurred. After updating, a startup paywall without an accessible Close blocked the repeated Mail check. One native Get Help quick-action attempt did not reveal the form. Therefore the Mail fix is **not verified on that physical device**. Physical sessions and owned automation server were closed. No OS authorization proof is inferred from the app's main screen.

The final prominent CTA was subsequently tested in the public example on simulator, not deployed to the phone in that task.

## Outstanding coverage

The earlier full accessibility audit on 4.0.1/4.0.2 reported contrast for an unspecified SwiftUI node. It did not identify a particular CTA label. The final glass-prominent appearance has **not received a new full accessibility audit**; this release does not claim that finding resolved. White text and native glass are preserved as explicitly requested.

iOS 15 runtime, full VoiceOver traversal, real Reduce Motion animation inspection and a new Instruments profile remain unverified. Package deployment builds, palette calculations and screenshots do not substitute for them.

## Evidence

Large logs/results/screenshots remain outside the repository in sibling `../.settings-4-verification/mail-open-error/` and `../.settings-4-verification/premium-prominent/`. Owner-facing exports are in this chat's `outputs/mail-open-error`, `outputs/premium-prominent` and `outputs/release-4.0.3`. No personal diagnostic letters, physical account details or large binary traces are committed.
