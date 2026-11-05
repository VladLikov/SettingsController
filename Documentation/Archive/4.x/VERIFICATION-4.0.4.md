# SettingsController 4.0.4 verification

2026-10-28. Patch to 4.0.3 (`6dd5f394b111961b12efd3fe5d34f4ff3036179f`). The owner approved the rendered design and explicitly authorized publication. Final implementation commit: `20ceda0`; only release documents changed afterward. Public initializer signatures, dependencies, iOS 15 minimum and Swift 6.4 / Xcode 27.1 requirements remain unchanged.

## Approved appearance and behavior

PremiumCard is a 72 pt rounded pill at normal text sizes, with icon, single-line title and a compact native glassProminent CTA. Its stronger three-tone diagonal gradient follows the host application's color family; the owner explicitly chose application colors rather than fixed purple. White text remains. No manually drawn CTA outline or whole-card press animation is added.

Subtitle remains accepted by the existing API and included in the accessibility label, but is omitted from the compact visual layout. Narrow widths use the native ViewThatFits fallback on iOS 16+; accessibility text uses a stacked layout. iOS 15 keeps a wrapping layout and native borderedProminent CTA. The older solid CTA has its own contrast-adjusted tint rather than reusing the lighter glass tint.

Both CTA and card background open the same destination. The card retains a single accessibility action without nesting buttons. Estimated premium-row height follows the new 72 pt baseline; actual rows remain self-sizing.

## Completed checks

Xcode 27.1 / Swift 6.4, Debug, deployment 15.0.

| Check | Result | Destination / evidence |
|---|---|---|
| Image/layout regression suite | 12 passed, 0 failed | Duo iOS 27.1, including forced legacy hosting containment and self-sizing. |
| Final palette check after glass tint adjustment | 1 passed, 0 failed | Duo iOS 27.1; distinct gradient/CTA tones and calculated contrast of the older solid fallback. |
| Initial new-design UI | 3 passed, 0 failed | iPhone Settings Verification iOS 27.0: CTA/card taps, dark/large-text/RTL, purple reference appearance with 72 pt height and no visible subtitle. |
| Final lighter-glass UI | 2 passed, 0 failed | Same iPhone simulator: blue CTA/card taps and purple reference appearance. Only CTA tint changed since the first UI run; dark/large-text/RTL was not redundantly repeated. |
| Resource and diff validation | Passed | 80 keys, 51 locales, placeholders, translator comments, privacy structure and git diff --check. |

Rendered normal card: 362 × 72 pt; native CTA: 99.3 × 34.3 pt. Large-text/RTL layout grew to 362 × 264.3 pt with no visible clipping. Blue and purple captures were compared directly against the supplied reference. Final native glass is slightly more saturated/less translucent than that reference; no pixel-perfect claim is made.

The intermediate 3.1.5-style iteration was checkpointed as `184da57`, then superseded by the owner's new pill reference before publication. Tests expecting its old background stops/100 pt height were updated to the explicitly requested new visual contract; unrelated assertions were not removed.

## Limits

No new full accessibility audit, VoiceOver traversal, real iOS 15 runtime run or physical-device deployment was performed for this redesign. Palette checks and forced legacy hosting on a newer simulator do not substitute for those checks. The earlier unspecified-node contrast finding is not claimed resolved. Mail/physical-device limits remain described in VERIFICATION-4.0.3.md; this release does not reclassify them as passes.

## Evidence

Large results/logs remain outside the repository in sibling `../.settings-4-verification/premium-pill/`: Layout.xcresult, Palette-Final.xcresult, UI.xcresult and UI-LightGlass.xcresult. Owner-facing reference comparisons and blue/purple/large-text screenshots are in this chat's `outputs/premium-pill`. Release readback is saved separately in `outputs/release-4.0.4`. No duplicate full test matrix is represented as a fresh pass.
