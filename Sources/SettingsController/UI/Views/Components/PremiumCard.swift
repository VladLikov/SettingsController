//
//  PremiumCard.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import SwiftUI

struct PremiumCard: View {
    var image: Image
    var title: String
    var subtitle: String
    var onUpgrade: () -> Void

    @State private var isPressed = false
    @State private var hologramPhase = 0.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2196, green: 0.0078, blue: 0.8549),
                            Color(red: 0.3647, green: 0.0666, blue: 0.9686)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 2)

            StarFlashBackground()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 20) {
                image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 25, height: 25)
                    .padding(.leading, 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Button(action: onUpgrade) {
                    Text("Upgrade")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 90, height: 35)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.white.opacity(0.14))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(.white.opacity(0.42), lineWidth: 2)
                                .holographicOverlay(phase: hologramPhase)
                        )
                }
                .buttonStyle(HolographicButtonStyle(isPressed: $isPressed))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        hologramPhase = 1
                    }
                }
                .padding(.trailing, 14)
            }
        }
    }
}

struct HolographicButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.interactiveSpring(), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        AngularGradient(colors: [.white.opacity(0.3), .white.opacity(0.3)], center: .center)
                    )
                    .blur(radius: 20)
                    .opacity(0.5)
                    .scaleEffect(configuration.isPressed ? 1.2 : 1)
            )
    }
}

extension View {
    func holographicOverlay(phase: Double) -> some View {
        overlay(
            AngularGradient(
                colors: [.clear, .white.opacity(0.3), .white.opacity(0.3), .clear],
                center: .center,
                startAngle: .degrees(phase * 360),
                endAngle:   .degrees(phase * 360 + 180)
            )
            .blendMode(.screen)
            .mask(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(lineWidth: 2)
            )
        )
    }
}

struct StarFlashBackground: View {
    @State private var stars: [Star] = []
    @State private var batchID = 0          // перезапуск «залпа»

    var body: some View {
        GeometryReader { geo in
            if #available(iOS 14.0, *) {
                ZStack {
                    ForEach(stars) { star in
                        Image(systemName: "star.fill")
                            .font(.system(size: star.font))
                            .foregroundColor(.white.opacity(star.opacity))
                            .shadow(color: .white, radius: 4)
                            .scaleEffect(star.visible ? star.scale : 0.1)
                            .rotationEffect(.degrees(star.angle))
                            .position(x: geo.size.width  * star.x,
                                      y: geo.size.height * star.y)
                            .opacity(star.visible ? 1 : 0)
                    }
                }
                .onAppear { spawn() }
                .onChange(of: batchID) { _ in spawn() }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: – создаём 1–3 звезды, каждая со своим offset’ом
    private func spawn() {
        let count = [1,1,1,1,1,1,1,1,2,3].randomElement()!  // 80 % →1, 15 % →2, 5 % →3
        stars = (0..<count).map { _ in .random }            // базовые параметры

        for i in stars.indices {
            // индивидуальные тайминги
            let spawnDelay = Double.random(in: 0...0.35)    // сдвиг старта
            let fadeIn     = 0.12
            let hold       = Double.random(in: 0.3...0.5)   // тоже слегка разное
            let fadeOut    = 0.18
            let lifeSpan   = spawnDelay + fadeIn + hold + fadeOut

            // начальные состояния
            stars[i].scale   = 0.1
            stars[i].angle   = .random(in: 0...360)
            stars[i].visible = false

            // появление (scale 0.1 → 1.25 → 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + spawnDelay) {
                withAnimation(.easeOut(duration: fadeIn)) {
                    stars[i].visible = true
                    stars[i].scale   = 1.25
                }
                withAnimation(.easeOut(duration: 0.15).delay(fadeIn)) {
                    stars[i].scale = 1.0
                }
                // плавный полуоборот за всю жизнь
                withAnimation(.linear(duration: lifeSpan - spawnDelay)) {
                    stars[i].angle += 20
                }
            }

            // исчезновение (scale 1 → 0.1 + fade)
            let vanishTime = spawnDelay + fadeIn + hold
            DispatchQueue.main.asyncAfter(deadline: .now() + vanishTime) {
                withAnimation(.easeIn(duration: fadeOut)) {
                    stars[i].visible = false
                    stars[i].scale   = 0.1
                }
            }
        }

        // пауза перед следующим залпом
        let pause = Double.random(in: 3...4.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + pause) {
            batchID += 1
        }
    }

    // MARK: – модель
    struct Star: Identifiable {
        let id = UUID()
        let x, y: CGFloat
        let font: CGFloat          // 4 – 10 pt
        let opacity: Double        // 0.5 – 0.8
        var scale:   CGFloat = 0.1
        var angle:   Double  = 0
        var visible: Bool    = false

        static var random: Star {
            .init(
                x:       .random(in: 0.15...0.85),
                y:       .random(in: 0.20...0.80),
                font:    .random(in: 4...10),
                opacity: .random(in: 0.5...0.8)
            )
        }
    }
}
