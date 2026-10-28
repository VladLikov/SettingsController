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

        if #available(iOS 26.0, *) {
            Button(action: onTap) {
                label.padding(.horizontal, 4).frame(minHeight: 28)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Color(palette.controlTint))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 1).allowsHitTesting(false))
        } else {
            Button(action: onTap) {
                label
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(Color(palette.controlFill)))
                    .overlay(Capsule().stroke(Color.white, lineWidth: 1))
            }
            .buttonStyle(PremiumCardButtonStyle())
        }
    }

}

/// Keeps the supplied hue, lowering luminance only where white text needs contrast.
struct PremiumCardPalette {
    let base: UIColor
    let end: UIColor
    let text = UIColor.white
    let controlFill = UIColor.black.withAlphaComponent(0.14)
    let controlTint: UIColor

    init(color: UIColor, traits: UITraitCollection) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        let resolved = color.resolvedColor(with: traits)
        guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            base = .black; end = .black; controlTint = .darkGray
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
        // A lighter tone in the gradient's color family separates the prominent CTA.
        low = 0; high = 1
        for _ in 0..<12 {
            let middle = (low + high) / 2
            let candidate = finish.map { $0 + (1 - $0) * middle }
            if contrast(candidate) >= 4.8 { low = middle } else { high = middle }
        }
        let control = finish.map { $0 + (1 - $0) * low }
        controlTint = UIColor(red: control[0], green: control[1], blue: control[2], alpha: 1)
    }
}

private struct PremiumCardButtonStyle: ButtonStyle {
    // Keep the card stationary; native glass supplies the CTA's local interaction.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
