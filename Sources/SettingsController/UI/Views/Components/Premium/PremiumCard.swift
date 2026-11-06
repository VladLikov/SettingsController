import SwiftUI

public struct PremiumCard: View {
    public let image: Image
    public let title: String
    public let tierTitle: String?
    public let subtitle: String
    public let buttonTitle: String
    public let color: UIColor
    public let onTap: () -> Void
    /// A precomputed palette for the current appearance; resolved from the environment when nil.
    let palette: PremiumCardPalette?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public init(image: Image, title: String, subtitle: String, buttonTitle: String, color: UIColor, onTap: @escaping () -> Void) {
        self.init(
            image: image, title: title, tierTitle: nil, subtitle: subtitle,
            buttonTitle: buttonTitle, color: color, onTap: onTap)
    }

    public init(
        image: Image = Image(systemName: "sparkle"), title: String, tierTitle: String?,
        subtitle: String = "", buttonTitle: String, color: UIColor, onTap: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        let tier = tierTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tierTitle = tier?.isEmpty == false ? tier : nil
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.color = color
        self.onTap = onTap
        self.palette = nil
    }

    /// Library cells pass a palette cached for their traits.
    init(payload: PremiumCardPayload, palette: PremiumCardPalette?, onTap: @escaping () -> Void) {
        image = payload.image
        title = payload.title
        tierTitle = payload.tierTitle
        subtitle = payload.subtitle
        buttonTitle = payload.buttonTitle
        color = payload.premium.color
        self.onTap = onTap
        self.palette = palette
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
        let palette = palette ?? PremiumCardPalette.cached(color: color, traits: environmentTraits)
        content(palette)
            .padding(.leading, PremiumCardMetrics.leadingPadding)
            .padding(.trailing, PremiumCardMetrics.trailingPadding)
            .padding(.vertical, PremiumCardMetrics.verticalPadding)
            .frame(maxWidth: .infinity, minHeight: PremiumCardMetrics.minimumHeight, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(palette.start), Color(palette.end)], startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
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

    private var environmentTraits: UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light),
            UITraitCollection(accessibilityContrast: colorSchemeContrast == .increased ? .high : .normal),
        ])
    }

    @ViewBuilder
    private func content(_ palette: PremiumCardPalette) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            stackedContent(palette)
        } else if #available(iOS 16.0, *) {
            // Decided in the cell's real environment; PremiumCell caches the resulting height.
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
        // Native translucent styles over the card: glass on iOS 26, bordered with a white tint earlier.
        Group {
            if #available(iOS 26.0, *) {
                button.buttonStyle(.glass).tint(.white).foregroundStyle(.white)
            } else {
                button.buttonStyle(.bordered).tint(.white).foregroundColor(.white)
            }
        }
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        // The card is always a dark surface; render the control as it would appear on one.
        .environment(\.colorScheme, .dark)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
    }

}

enum PremiumCardMetrics {
    static let minimumHeight: CGFloat = 72
    static let leadingPadding: CGFloat = 24
    static let trailingPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 14
}

/// One hue, two stops: the accent darkened until white text stays readable, and a deeper shade of it.
/// The darkening also covers the translucent CTA fill, which lightens what lies under its label.
struct PremiumCardPalette {
    let start: UIColor
    let end: UIColor
    let text = UIColor.white

    /// Approximate lightening of the card under a translucent white CTA fill.
    static let controlFillOpacity: CGFloat = 0.2
    static let startShade: CGFloat = 0.78

    private struct CacheKey: Hashable {
        let color: UIColor
        let style: UIUserInterfaceStyle
        let contrast: UIAccessibilityContrast
    }

    @MainActor private static var cache: [CacheKey: PremiumCardPalette] = [:]

    /// The palette only depends on the accent color, light or dark style and contrast.
    @MainActor
    static func cached(color: UIColor, traits: UITraitCollection) -> PremiumCardPalette {
        let key = CacheKey(color: color, style: traits.userInterfaceStyle, contrast: traits.accessibilityContrast)
        if let palette = cache[key] { return palette }
        if cache.count >= 32 { cache.removeAll() }
        let palette = PremiumCardPalette(color: color, traits: traits)
        cache[key] = palette
        return palette
    }

    init(color: UIColor, traits: UITraitCollection) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1
        if !color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a) {
            (r, g, b) = (0.35, 0.35, 0.38)
        }
        let rgb = [r, g, b].map { min(max($0, 0), 1) }
        let minimum: Double = traits.accessibilityContrast == .high ? 7 : 4.5
        let factor = Self.darkening(rgb, minimum: minimum)
        let endRGB = rgb.map { $0 * factor }
        end = UIColor(red: endRGB[0], green: endRGB[1], blue: endRGB[2], alpha: 1)
        start = UIColor(
            red: endRGB[0] * Self.startShade, green: endRGB[1] * Self.startShade, blue: endRGB[2] * Self.startShade, alpha: 1)
    }

    /// White text contrast against a color, per WCAG relative luminance.
    static func whiteContrast(_ rgb: [CGFloat]) -> Double {
        let channels = rgb.map { value -> Double in
            let v = Double(value)
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 1.05 / (0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2] + 0.05)
    }

    /// The largest scale of the color that keeps white text at `minimum`, also under the CTA fill.
    private static func darkening(_ rgb: [CGFloat], minimum: Double) -> CGFloat {
        func passes(_ factor: CGFloat) -> Bool {
            let shaded = rgb.map { $0 * factor }
            let underControl = shaded.map { $0 + (1 - $0) * controlFillOpacity }
            return whiteContrast(shaded) >= minimum && whiteContrast(underControl) >= minimum
        }
        if passes(1) { return 1 }
        var low: CGFloat = 0
        var high: CGFloat = 1
        for _ in 0..<16 {
            let middle = (low + high) / 2
            if passes(middle) { low = middle } else { high = middle }
        }
        return low
    }
}
