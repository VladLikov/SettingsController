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
        Button(action: onTap) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) {
                        heading
                        callToAction(palette)
                    }
                } else {
                    HStack(spacing: 12) {
                        heading
                        Spacer(minLength: 0)
                        callToAction(palette)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .foregroundColor(Color(palette.text))
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(
                LinearGradient(colors: [Color(palette.base), Color(palette.end)], startPoint: .top, endPoint: .bottom)
            ))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PremiumCardButtonStyle())
        // The host supplies these already-localized strings; do not extract a placeholder-only key.
        .accessibilityLabel(Text(verbatim: [title, subtitle, buttonTitle].joined(separator: ". ")))
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

    private func callToAction(_ palette: PremiumCardPalette) -> some View {
        Text(buttonTitle)
            .font(.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color(palette.controlFill)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(palette.text).opacity(0.42), lineWidth: 1))
    }

}

/// Preserves the supplied hue while keeping readable text across the whole gradient.
struct PremiumCardPalette {
    let base: UIColor
    let end: UIColor
    let text: UIColor
    let controlFill: UIColor

    init(color: UIColor, traits: UITraitCollection) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        let resolved = color.resolvedColor(with: traits)
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            base = .black; end = .black; text = .white; controlFill = UIColor.white.withAlphaComponent(0.14)
            return
        }
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 1
        UIColor.systemGroupedBackground.resolvedColor(with: traits).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        var start = [r * a + br * (1 - a), g * a + bg * (1 - a), b * a + bb * (1 - a)]
        let white = Self.luminance(start) < 0.179
        func contrast(_ rgb: [CGFloat]) -> Double {
            let value = Self.luminance(rgb)
            return white ? 1.05 / (value + 0.05) : (value + 0.05) / 0.05
        }
        // Leave room for platform colour conversion and narrow-column text rendering.
        let target = 6.0
        if contrast(start) < target {
            let endpoint: CGFloat = white ? 0 : 1
            var low: CGFloat = 0, high: CGFloat = 1
            for _ in 0..<12 {
                let middle = (low + high) / 2
                let rgb = start.map { $0 + (endpoint - $0) * middle }
                if contrast(rgb) < target { low = middle } else { high = middle }
            }
            start = start.map { $0 + (endpoint - $0) * high }
        }
        let candidate = [min(start[0] + 0.07, 1), min(start[1] + 0.12, 1), min(start[2] + 0.18, 1)]
        var amount: CGFloat = 1
        if contrast(candidate) < target {
            var low: CGFloat = 0, high: CGFloat = 1
            for _ in 0..<12 {
                let middle = (low + high) / 2
                let rgb = zip(start, candidate).map { $0 + ($1 - $0) * middle }
                if contrast(rgb) >= target { low = middle } else { high = middle }
            }
            amount = low
        }
        let finish = zip(start, candidate).map { $0 + ($1 - $0) * amount }
        base = UIColor(red: start[0], green: start[1], blue: start[2], alpha: 1)
        end = UIColor(red: finish[0], green: finish[1], blue: finish[2], alpha: 1)
        text = white ? .white : .black
        controlFill = (white ? UIColor.black : UIColor.white).withAlphaComponent(0.14)
    }

    private static func luminance(_ rgb: [CGFloat]) -> Double {
        let linear = rgb.map { channel -> Double in
            let value = Double(channel)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
    }
}

private struct PremiumCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .interactiveSpring(), value: configuration.isPressed)
    }
}
