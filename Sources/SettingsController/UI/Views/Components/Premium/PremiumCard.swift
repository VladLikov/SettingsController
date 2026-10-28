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

    @ViewBuilder
    private func callToAction(_ palette: PremiumCardPalette) -> some View {
        let label = Text(buttonTitle)
            .font(.headline)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)

        if #available(iOS 26.0, *) {
            label.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            label
                .background(Capsule().fill(Color(palette.controlFill)))
                .overlay(Capsule().stroke(Color.white, lineWidth: 1))
        }
    }

}

/// Keeps the supplied hue, lowering luminance only where white text needs contrast.
struct PremiumCardPalette {
    let base: UIColor
    let end: UIColor
    let text = UIColor.white
    let controlFill = UIColor.black.withAlphaComponent(0.14)

    init(color: UIColor, traits: UITraitCollection) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        let resolved = color.resolvedColor(with: traits)
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            base = .black; end = .black
            return
        }
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 1
        UIColor.systemGroupedBackground.resolvedColor(with: traits).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        var start = [r * a + br * (1 - a), g * a + bg * (1 - a), b * a + bb * (1 - a)]
        func contrast(_ rgb: [CGFloat]) -> Double {
            let v = rgb.map { channel -> Double in
                let c = Double(channel)
                return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 1.05 / (0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2] + 0.05)
        }
        let target = 6.0
        if contrast(start) < target {
            var low: CGFloat = 0, high: CGFloat = 1
            for _ in 0..<12 {
                let middle = (low + high) / 2
                if contrast(start.map { $0 * (1 - middle) }) < target { low = middle } else { high = middle }
            }
            start = start.map { $0 * (1 - high) }
        }
        let light = [min(start[0] + 0.07, 1), min(start[1] + 0.12, 1), min(start[2] + 0.18, 1)]
        var low: CGFloat = 0, high: CGFloat = 1
        for _ in 0..<12 {
            let middle = (low + high) / 2
            let candidate = zip(start, light).map { $0 + ($1 - $0) * middle }
            if contrast(candidate) >= target { low = middle } else { high = middle }
        }
        let finish = zip(start, light).map { $0 + ($1 - $0) * low }
        // Keep distinct stops even when the lighter stop reaches the contrast boundary.
        base = UIColor(red: start[0] * 0.75, green: start[1] * 0.75, blue: start[2] * 0.75, alpha: 1)
        end = UIColor(red: finish[0], green: finish[1], blue: finish[2], alpha: 1)
    }
}

private struct PremiumCardButtonStyle: ButtonStyle {
    // Keep the card stationary; native glass supplies the CTA's local interaction.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
