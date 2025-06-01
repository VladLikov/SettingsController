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
    var image: Image
    var title: String
    var subtitle: String
    var buttonTitle: String
    var color: UIColor
    var onTap: () -> Void

    // UI State
    @State private var isPressed = false
    @State private var hologramPhase = 0.0

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
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(gradient)
                .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 2)

            // Tiny star sparkle
            StarFlashBackground()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

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

                Button(action: onTap) {
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
                                .holographicOverlay(phase: hologramPhase)
                        )
                }
                .buttonStyle(HolographicButtonStyle(isPressed: $isPressed))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        hologramPhase = 1
                    }
                }
                .padding(.trailing, 20)
            }
            .onTapGesture {
                onTap()
            }
        }
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

// MARK: - HolographicButtonStyle
private struct HolographicButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.interactiveSpring(), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(AngularGradient(colors: [.white.opacity(0.25), .white.opacity(0.25)], center: .center))
                    .blur(radius: 10)
                    .opacity(0.5)
                    .compositingGroup()
                    .scaleEffect(configuration.isPressed ? 1.2 : 1)
            )
    }
}

// MARK: - View+HolographicBorderOverlay
private extension View {
    func holographicOverlay(phase: Double) -> some View {
        overlay(
            AngularGradient(colors: [.clear, .white.opacity(0.3), .white.opacity(0.3), .clear],
                             center: .center,
                             startAngle: .degrees(phase * 360),
                             endAngle:   .degrees(phase * 360 + 180))
                .blendMode(.screen)
                .mask(RoundedRectangle(cornerRadius: 22).stroke(lineWidth: 1))
        )
    }
}

// MARK: - StarFlashBackground (one star, 5–8 s pause)
// MARK: - StarFlashBackground (fills full card)
private struct StarFlashBackground: View {
    @State private var star: Star? = nil
    @State private var size: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let s = star {
                    Image(systemName: "star.fill")
                        .font(.system(size: s.font))
                        .foregroundColor(.white.opacity(s.opacity))
                        .scaleEffect(s.visible ? s.scale : 0.1)
                        .rotationEffect(.degrees(s.angle))
                        .position(x: s.x, y: s.y)
                        .opacity(s.visible ? 1 : 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onAppear {
                size = geo.size
                loop()
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: Animation loop
    private func loop() {
        guard star == nil, size != .zero else { return }
        star = Star.random(in: size)
        
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.12)) { update { $0.visible = true; $0.scale = 1.15 } }
            try await Task.sleep(nanoseconds: 120_000_000)   // 120 ms
            withAnimation(.easeOut(duration: 0.1)) { update { $0.scale = 1 } }
            withAnimation(.linear(duration: 0.6)) { update { $0.angle += 20 } }
            try await Task.sleep(nanoseconds: 600_000_000)   // 600 ms
            withAnimation(.easeIn(duration: 0.18)) { update { $0.visible = false; $0.scale = 0.1 } }
            try await Task.sleep(nanoseconds: 200_000_000)   // 200 ms
            star = nil
            // pause 5–8 s
            let pause = UInt64(Int.random(in: 3...5)) * 1_000_000_000
            try await Task.sleep(nanoseconds: pause)
            loop()
        }
    }
    
    private func update(_ change: (inout Star) -> Void) {
        guard var s = star else { return }; change(&s); star = s
    }

    // MARK: Star model
    private struct Star: Identifiable {
        let id = UUID()
        var x, y: CGFloat
        let font: CGFloat
        let opacity: Double
        var scale: CGFloat = 0.1
        var angle: Double = 0
        var visible: Bool = false
        static func random(in size: CGSize) -> Star {
            .init(x: size.width  * .random(in: 0.15...0.85),
                   y: size.height * .random(in: 0.2 ... 0.8),
                   font: .random(in: 4...10),
                   opacity: .random(in: 0.5...0.8))
        }
    }
}

// MARK: - View+Conditional modifier helper
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
// MARK: - Preview
#if DEBUG
#Preview {
    PremiumCard(
        image: Image(systemName: "star.fill"),
        title: "StepsGo+asdlkasl;dmas;lmd;lasmdl;amsl;dml;a",
        subtitle: "Unlock all featuresnkdnfksdnf",
        buttonTitle: "Upgrade",
        color: .systemBlue,
        onTap: {}
    )
    .padding()
    .frame(height: 150)
}
#endif
