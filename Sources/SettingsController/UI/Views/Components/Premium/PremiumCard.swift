import SwiftUI

public struct PremiumCard: View {
    public let image: Image
    public let title: String
    public let subtitle: String
    public let buttonTitle: String
    public let color: UIColor
    public let onTap: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    public init(image: Image, title: String, subtitle: String, buttonTitle: String, color: UIColor, onTap: @escaping () -> Void) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.color = color
        self.onTap = onTap
    }

    public var body: some View {
        let palette = PremiumCardPalette(color: color, traits: UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light))
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    heading.allowsHitTesting(false)
                    callToAction(palette)
                }
            } else {
                HStack(spacing: 12) {
                    heading.allowsHitTesting(false)
                    Spacer(minLength: 0)
                    callToAction(palette)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .foregroundColor(Color(palette.text))
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(palette.base), Color(palette.end)], startPoint: .top, endPoint: .bottom))
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .onTapGesture(perform: onTap)
                .accessibilityHidden(true)
        }
        // Keep the card's existing single VoiceOver action, without nesting buttons.
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        // The host supplies these already-localized strings; do not extract a placeholder-only key.
        .accessibilityLabel(Text(verbatim: [title, subtitle, buttonTitle].joined(separator: ". ")))
        .accessibilityAction(.default) { onTap() }
    }

    private var heading: some View {
        HStack(alignment: .center, spacing: 10) {
            // In narrow iPad columns, scaled decoration must not squeeze the text.
            if !dynamicTypeSize.isAccessibilitySize {
                image.renderingMode(.template).font(.title2).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
    }

    @ViewBuilder
    private func callToAction(_ palette: PremiumCardPalette) -> some View {
        let label = Text(buttonTitle)
            .font(.headline)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

        let button = Button(action: onTap) { label.padding(.horizontal, 4) }
        Group {
            if #available(iOS 26.0, *) {
                button.buttonStyle(.glassProminent)
            } else {
                button.buttonStyle(.borderedProminent)
            }
        }
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .tint(Color(palette.controlTint))
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
    }

}

/// Preserves the 3.1.5 gradient; the native CTA gets its own related shade.
struct PremiumCardPalette {
    let base: UIColor
    let end: UIColor
    let text = UIColor.white
    let controlTint: UIColor

    init(color: UIColor, traits: UITraitCollection) {
        let resolved = color.resolvedColor(with: traits)
        base = resolved
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            end = resolved
            controlTint = .darkGray
            return
        }
        // These are the original 3.1.5 stops, without contrast-based dimming.
        end = UIColor(red: min(r + 0.07, 1), green: min(g + 0.12, 1), blue: min(b + 0.18, 1), alpha: 1)

        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
        resolved.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &a)
        let shade: UIColor
        if saturation < 0.05 {
            shade = UIColor(white: brightness > 0.5 ? 0.42 : 0.28, alpha: 1)
        } else {
            shade = UIColor(hue: (hue + 0.035).truncatingRemainder(dividingBy: 1),
                            saturation: max(saturation, 0.65), brightness: max(brightness * 0.85, 0.35), alpha: 1)
        }
        shade.getRed(&r, green: &g, blue: &b, alpha: &a)
        func contrast(_ factor: CGFloat) -> Double {
            let channels = [r, g, b].map { value -> Double in
                let v = Double(value * factor)
                return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 1.05 / (0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2] + 0.05)
        }
        var factor: CGFloat = 1
        if contrast(factor) < 4.8 {
            var low: CGFloat = 0, high: CGFloat = 1
            for _ in 0..<12 {
                let middle = (low + high) / 2
                if contrast(middle) >= 4.8 { low = middle } else { high = middle }
            }
            factor = low
        }
        controlTint = UIColor(red: r * factor, green: g * factor, blue: b * factor, alpha: 1)
    }
}
