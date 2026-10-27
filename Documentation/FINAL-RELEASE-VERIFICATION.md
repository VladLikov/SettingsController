# Final verification — 28 October 2026

PR: https://github.com/VladLikov/SettingsController/pull/2. No merge, release tag or signing changes.

## Changes discovered during acceptance

- Duo reserved-region observation now uses `UIView.updateConstraints()`, where UIKit tracks reads. The controller hook did not reliably update tabletop layouts. Column writes are deferred to the next MainActor turn, avoiding a cold-start overlay that hid part of the empty state. Active division removes minimum-width constraints and uses 50/50 columns; disappearing division restores all original width values. Native gestures remain enabled.
- Native full accessibility audit found insufficient premium subtitle contrast. The palette preserves the supplied hue and selects readable text/gradient colours. The audit now passes locally with no excluded checks.
- The sample declares all four iPad orientations and all 52 supported languages (English source plus 51 translations), so contextual localization tests exercise the real selected language.
- Finnish Cancel and four update-available translations were corrected after context review. Catalog JSON, comments, placeholders and all locale validations pass.
- Added UI checks for native interactive-dismissal cancellation, the complete accessibility audit and Russian/German/Arabic Mail preparation and About labels. Cancellation is observed through the actual transition coordinator; the sample probe does not prevent dismissal.

## Local evidence

Evidence is retained in the authorized test folder, `.settings-4-verification`.

| Check | Result |
| --- | --- |
| Final package suite, Duo 27.1 | 74 passed, 0 failed, 0 skipped |
| Native full accessibility audit, iPhone 27.0 | Passed after contrast correction |
| Localized Mail preparing/disabled Send and About, ru/de/ar | Passed; screenshots and AX hierarchies retained |
| Phone interactive sheet cancellation | Passed; cancellation callback plus subsequent profile rename verified |
| Native Duo cold empty and selected Appearance, book/tabletop | Both columns visible, approximately 50/50; selected detail preserved across Open/Closed/Partial |
| iPad maximum accessibility text size | Wrapping and final footer reachability passed |
| VoiceOver | Real setting and focus ring confirmed; complete traversal/activation not verified |
| Reduce Motion | Real setting enabled and screen inspected; animation suppression not measured |
| iPad window resizing | Unverified: resize controls disabled in sample and Settings; one fallback returned no windows |

Native Duo poses were controlled through Device Hub, not synthesized frame sizes. Screenshots are unretouched native captures. Simulator checks do not prove physical-device behaviour.

## Profiling

Native Release Time Profiler and baseline/after Memory Graph sessions use an isolated sample workload: three warmup cycles, then 30 repetitions of settings → profile update → paywall → premium refresh → dismissal. Demo purchases and programmatic transitions are not real StoreKit or physical gestures. Temporary workload source is preserved as evidence and removed from the committed sample.

The first profiling pass found zero reported leaks in both graphs and no SettingsController/ProfileController/PaywallController remaining after the workload. Time Profiler recorded two microhangs (258 and 263 ms); their cause was not established. Inclusive CPU sample weights overlap and must not be interpreted as wall time or summed percentages. A repeat on the final source is retained separately under `final-profiling-final`; see the delivered evidence report for its measured results.

Final-source repeat: 90.665 seconds, all 30 cycles completed, 7,432 CPU samples and no recorded hang rows. Both baseline and after graphs report **0 leaks / 0 bytes**; no SettingsController/ProfileController/PaywallController remains. Live malloc bytes changed from 9,402,560 to 9,540,176 (+137,616 bytes). Physical footprint changed from 38.6M to 88.1M; VM analysis shows Performance Tool Data increasing from 16.2M to 62.6M in the MallocStackLogging run, accounting for most of that increase. This is not an uninstrumented app memory benchmark. Native Instruments reported one table without a known input source; CPU samples exported successfully. No hang rows does not prove zero jank on physical devices. Trace symbols match arm64 UUID `47385CEC-99D4-36E5-AC32-5975199F9FB5`.

## CI and remaining scope

Both workflows now use GitHub's `xcode-27` image and explicit Xcode 27.1 / Swift 6.4 destinations: iPhone 18 Pro 27.0, iPad Pro 11-inch (M5) 27.0, iPhone Duo 27.1. UI results include screenshots/hierarchies and expected device-specific skips. The phone sheet gesture test explicitly skips iPad; it does not claim tablet cancellation coverage.

Only a successful run for the final PR SHA closes the CI gate. The initial ab05952 package matrix passed, while its iPad UI job timed out during the first test; that failure is retained, not counted as a pass.

Unverified: full VoiceOver flow, measured Reduce Motion animations, native iPad resizing, real iOS 15 runtime, physical Mail handlers, real StoreKit and physical-device performance. Context review is not native-speaker certification of all locales. These limits remain explicit for the sole consuming application.
