//
//  PremiumCard.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import SwiftUI

// MARK: - PremiumCard
public struct PremiumCard: View {
    // Public API
    public let image: Image
    public let title: String
    public let subtitle: String
    public let buttonTitle: String
    public let color: UIColor
    public let onTap: () -> Void

    // Cache gradient once
    private let gradient: LinearGradient
    public init(image: Image, title: String, subtitle: String, buttonTitle: String, color: UIColor, onTap: @escaping () -> Void) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.color = color
        self.onTap = onTap
        self.gradient = LinearGradient(
            colors: Self.makeGradientColors(from: color),
            startPoint: .top, endPoint: .bottom)
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 2)

                // Content stack
                HStack(spacing: 8) {
                    image
                        .renderingMode(.template)
                        .foregroundColor(.white.opacity(0.93))
                        .font(.system(size: 25, weight: .regular))
                        .padding(.leading, 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    .padding(.leading, 2)

                    Spacer(minLength: 0)

                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 35)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.white.opacity(0.14))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(.white.opacity(0.42), lineWidth: 1)
                        )
                        .padding(.trailing, 20)
                }
            }
        }
        .buttonStyle(PremiumCardButtonStyle())
    }

    // MARK: Private helpers
    private static func makeGradientColors(from ui: UIColor) -> [Color] {
        guard let c = ui.cgColor.components, c.count >= 3 else { return [.init(ui), .init(ui)] }
        let light = UIColor(
            red: min(c[0] + 0.07, 1),
            green: min(c[1] + 0.12, 1),
            blue: min(c[2] + 0.18, 1),
            alpha: 1)
        return [.init(ui), .init(light)]
    }
}

// MARK: - PremiumCardButtonStyle
private struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

#if DEBUG
#Preview {
    PremiumCard(
        image: Image(systemName: "star.fill"),
        title: "Go Premium",
        subtitle: "Unlock all features",
        buttonTitle: "Upgrade",
        color: .systemBlue,
        onTap: {}
    )
    .padding()
    .frame(height: 150)
}
#endif
