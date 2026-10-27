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
        Button(action: onTap) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) {
                        heading
                        callToAction
                    }
                } else {
                    HStack(spacing: 12) {
                        heading
                        Spacer(minLength: 0)
                        callToAction
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(gradient))
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

    private var callToAction: some View {
        Text(buttonTitle)
            .font(.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.14)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.42), lineWidth: 1))
    }

    private var gradient: LinearGradient {
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let lighter: UIColor
        if resolved.getRed(&r, green: &g, blue: &b, alpha: &a) {
            lighter = UIColor(red: min(r + 0.07, 1), green: min(g + 0.12, 1), blue: min(b + 0.18, 1), alpha: a)
        } else { lighter = resolved }
        return LinearGradient(colors: [Color(resolved), Color(lighter)], startPoint: .top, endPoint: .bottom)
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
