# Premium CTA native glass contrast

2026-10-29. Local unreleased change; SwiftMate integration is intentionally unchanged.

## Apple guidance

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass): custom control colors should have light/dark and Increased Contrast variants.
- [Meet Liquid Glass, WWDC25](https://developer.apple.com/videos/play/wwdc2025/219/): native tint and foreground adapt to content brightness.
- [glassProminent](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent): retain the contextual native prominent glass button style.

## Implementation

Keep the approved normal-light tint. For dark appearance or Increased Contrast, use a deeper related tint with luminance headroom for the real material. Forward SwiftUI colorSchemeContrast to palette traits. Scope white foreground to the heading and the older solid-button fallback; let native glass style the CTA label. Keep native capsule shape, dimensions, actions and gradient. No custom glass renderer, overlay, shadow or forced color scheme is added.

## Runtime evidence

Fresh iOS 27.1 sample captures show the final normal-light card is pixel-identical within its card crop to the pre-change light capture. Dark native blue CTA sampled foreground/fill contrast improved from approximately 1.58:1 to 5.07:1; final orange approximately 4.94:1. These are screenshot spot measurements, not certification across all pixels, colors, OS versions or accessibility modes. Increased Contrast routing is covered by palette tests; its full rendered matrix was not audited.

Two functional UI tests passed: light CTA/card and dark CTA/card navigation. Final tint adjustment after that run changed only color; final sample build and captures verified blue/light/orange. The native contrast audit explicitly reported the unchanged App Lock PRO heading over the bright gradient, not the CTA. It is not a blanket accessibility pass. The diagnostic audit is retained in evidence rather than added as a knowingly failing CI test.

Captures, native audit output and result bundle references: chat outputs/glass-dark-contrast/QA.md. Package test log: the same output folder, PackageTests.log.

Package verification: 16 selected heading/layout/palette cases were run. An existing distinct-tone assertion caught an already-dark accent matching the middle gradient stop; a final guard preserves a distinct CTA shade. The two affected palette tests then passed on rerun; the other 14 had passed. The guard does not change the captured blue/orange colors. Resource and diff validation passed.
