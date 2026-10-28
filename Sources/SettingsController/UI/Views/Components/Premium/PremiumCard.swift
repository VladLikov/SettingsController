import SwiftUI

public struct PremiumCard: View {
    public let image: Image
    public let title: String
    public let tierTitle: String?
    public let subtitle: String
    public let buttonTitle: String
    public let color: UIColor
    public let onTap: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init(image: Image, title: String, subtitle: String, buttonTitle: String, color: UIColor, onTap: @escaping () -> Void) {
        self.init(image: image, title: title, tierTitle: nil, subtitle: subtitle,
                  buttonTitle: buttonTitle, color: color, onTap: onTap)
    }

    public init(image: Image = Image(systemName: "sparkle"), title: String, tierTitle: String?,
                subtitle: String = "", buttonTitle: String, color: UIColor, onTap: @escaping () -> Void) {
        self.image = image
        self.title = title
        let tier = tierTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tierTitle = tier?.isEmpty == false ? tier : nil
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.color = color
        self.onTap = onTap
    }

    var displayTitle: String {
        [title, tierTitle].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    var headingText: AttributedString {
        // Both fragments are already localized by the host; this is brand composition, not a library localization key.
        var text = AttributedString(title)
        text.font = Font.title3.weight(.regular)
        if let tierTitle {
            var tier = AttributedString((title.isEmpty ? "" : " ") + tierTitle)
            tier.font = Font.title3.weight(.bold)
            text.append(tier)
        }
        return text
    }

    public var body: some View {
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light),
            UITraitCollection(accessibilityContrast: colorSchemeContrast == .increased ? .high : .normal)
        ])
        let palette = PremiumCardPalette(color: color, traits: traits)
        content(palette)
        .padding(.leading, 24)
        .padding(.trailing, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(LinearGradient(colors: [Color(palette.base), Color(palette.middle), Color(palette.end)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .contentShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .onTapGesture(perform: onTap)
                .accessibilityHidden(true)
        }
        // Keep the card's existing single VoiceOver action, without nesting buttons.
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        // The host supplies these already-localized strings; do not extract a placeholder-only key.
        .accessibilityLabel(Text(verbatim: [displayTitle, subtitle, buttonTitle].filter { !$0.isEmpty }.joined(separator: ". ")))
        .accessibilityAction(.default) { onTap() }
    }

    @ViewBuilder
    private func content(_ palette: PremiumCardPalette) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            stackedContent(palette)
        } else if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                horizontalContent(palette, allowsWrapping: false)
                stackedContent(palette)
            }
        } else {
            horizontalContent(palette, allowsWrapping: true)
        }
    }

    private func horizontalContent(_ palette: PremiumCardPalette, allowsWrapping: Bool) -> some View {
        HStack(spacing: 16) {
            heading.fixedSize(horizontal: !allowsWrapping, vertical: true).allowsHitTesting(false)
            Spacer(minLength: 0)
            callToAction(palette).fixedSize(horizontal: true, vertical: true)
        }
    }

    private func stackedContent(_ palette: PremiumCardPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            heading.allowsHitTesting(false)
            callToAction(palette)
        }
    }

    private var heading: some View {
        HStack(spacing: 16) {
            if !dynamicTypeSize.isAccessibilitySize {
                image.renderingMode(.template).font(.title3.weight(.regular)).accessibilityHidden(true)
            }
            Text(headingText)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .foregroundColor(.white)
    }

    @ViewBuilder
    private func callToAction(_ palette: PremiumCardPalette) -> some View {
        let label = Text(buttonTitle)
            .font(.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

        let button = Button(action: onTap) { label.padding(.horizontal, 4) }
        Group {
            if #available(iOS 26.0, *) {
                button.buttonStyle(.glassProminent).tint(Color(palette.controlTint))
            } else {
                button.buttonStyle(.borderedProminent).tint(Color(palette.legacyControlTint))
                    .foregroundColor(.white)
            }
        }
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
    }

}

/// Three related hues make the reference pill's gradient pronounced without animating it.
struct PremiumCardPalette {
    let base: UIColor
    let middle: UIColor
    let end: UIColor
    let text = UIColor.white
    let controlTint: UIColor
    let legacyControlTint: UIColor

    init(color: UIColor, traits: UITraitCollection) {
        let resolved = color.resolvedColor(with: traits)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 1
        guard resolved.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            base = resolved; middle = resolved; end = resolved; controlTint = .darkGray; legacyControlTint = .darkGray
            return
        }
        if saturation < 0.05 {
            base = UIColor(white: max(brightness * 0.55, 0.08), alpha: 1)
            middle = UIColor(white: max(brightness * 0.75, 0.16), alpha: 1)
            end = UIColor(white: max(brightness * 0.95, 0.24), alpha: 1)
        } else {
            func stop(_ offset: CGFloat, saturation: CGFloat, brightness: CGFloat) -> UIColor {
                UIColor(hue: (hue + offset + 1).truncatingRemainder(dividingBy: 1),
                        saturation: min(max(saturation, 0), 1), brightness: brightness, alpha: 1)
            }
            base = stop(-0.035, saturation: max(saturation, 0.95), brightness: 0.92)
            middle = stop(0.005, saturation: max(saturation, 0.9), brightness: 0.98)
            end = stop(0.045, saturation: max(saturation * 0.8, 0.75), brightness: 1)
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        middle.getRed(&r, green: &g, blue: &b, alpha: &a)
        // The native prominent glass gets a softer, lighter tone than the banner.
        let lightControlTint = UIColor(red: r + (1 - r) * 0.55, green: g + (1 - g) * 0.55,
                                       blue: b + (1 - b) * 0.55, alpha: 1)
        // Older systems have a solid prominent fill rather than adaptive native glass.
        func contrast(_ factor: CGFloat) -> Double {
            let channels = [r, g, b].map { value -> Double in
                let v = Double(value * factor)
                return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 1.05 / (0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2] + 0.05)
        }
        // Leave luminance headroom for the native glass material in dark/high-contrast appearances.
        let minimumContrast = traits.userInterfaceStyle == .dark || traits.accessibilityContrast == .high ? 5.5 : 4.8
        var factor: CGFloat = 1
        if contrast(1) < minimumContrast {
            var low: CGFloat = 0, high: CGFloat = 1
            for _ in 0..<12 {
                let middle = (low + high) / 2
                if contrast(middle) >= minimumContrast { low = middle } else { high = middle }
            }
            factor = low
        }
        if traits.userInterfaceStyle == .dark || traits.accessibilityContrast == .high {
            // Already-dark accents still need a distinct CTA tone rather than the gradient's middle stop.
            factor = min(factor, 0.9)
        }
        legacyControlTint = UIColor(red: r * factor, green: g * factor, blue: b * factor, alpha: 1)
        // Custom tints need appearance and Increased Contrast variants (Apple's adoption guidance).
        // Keep the approved light tint; avoid adding white to a dark-mode glass fill.
        controlTint = traits.userInterfaceStyle == .dark || traits.accessibilityContrast == .high
            ? legacyControlTint : lightControlTint
    }
}
