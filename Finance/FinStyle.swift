import SwiftUI

enum FinStyle {
    // MARK: - നിറങ്ങൾ
    static let neon = Color(red: 0.12, green: 0.55, blue: 1.0)
    static let cyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    static let receive = Color(red: 0.20, green: 0.95, blue: 0.70)
    static let pay = Color(red: 1.0, green: 0.38, blue: 0.52)
    static let heroReceive = FinStyle.receive
    static let heroPay = FinStyle.pay

    static let accent = LinearGradient(
        colors: [Color(red: 0.10, green: 0.45, blue: 1.0),
                 Color(red: 0.0, green: 0.78, blue: 1.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.13, blue: 0.33),
                 Color(red: 0.02, green: 0.06, blue: 0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static func avatarGradient(for name: String) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.12, green: 0.55, blue: 1.0), Color(red: 0.0, green: 0.85, blue: 1.0)],
            [Color(red: 0.45, green: 0.35, blue: 1.0), Color(red: 0.12, green: 0.55, blue: 1.0)],
            [Color(red: 0.0, green: 0.85, blue: 0.75), Color(red: 0.20, green: 0.95, blue: 0.55)],
            [Color(red: 0.70, green: 0.40, blue: 1.0), Color(red: 1.0, green: 0.40, blue: 0.75)],
            [Color(red: 0.0, green: 0.75, blue: 1.0), Color(red: 0.30, green: 0.50, blue: 1.0)]
        ]
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let colors = palettes[sum % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func initial(of name: String) -> String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }
}

// MARK: - ബാക്ക്ഗ്രൗണ്ട് (ഡാർക്ക് നേവി + നിയോൺ glow)

struct GlowBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.01, green: 0.03, blue: 0.09),
                         Color(red: 0.02, green: 0.06, blue: 0.17)],
                startPoint: .top, endPoint: .bottom)

            Circle()
                .fill(FinStyle.neon.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 150, y: -280)

            Circle()
                .fill(FinStyle.cyan.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: -160, y: 300)
        }
        .ignoresSafeArea()
    }
}

// MARK: - ഗ്ലോ കാർഡ് ബാക്ക്ഗ്രൗണ്ട്

struct GlowCardBackground: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(FinStyle.heroGradient)
            .overlay(
                // glow വൃത്തങ്ങൾ overlay-ൽ ആയതുകൊണ്ട് കാർഡിൻ്റെ വലുപ്പം മാറ്റില്ല
                ZStack {
                    Circle()
                        .fill(FinStyle.neon.opacity(0.35))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: 110, y: -70)
                    Circle()
                        .fill(FinStyle.cyan.opacity(0.14))
                        .frame(width: 160, height: 160)
                        .blur(radius: 60)
                        .offset(x: -120, y: 90)
                }
            )
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [FinStyle.cyan.opacity(0.9),
                                 FinStyle.neon.opacity(0.25),
                                 FinStyle.neon.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1)
            )
    }
}

// MARK: - Avatar

struct AvatarView: View {
    let name: String
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle().fill(FinStyle.avatarGradient(for: name).opacity(0.22))
            Circle().strokeBorder(FinStyle.avatarGradient(for: name), lineWidth: 1.5)
            Text(FinStyle.initial(of: name))
                .font(FinFont.font(size * 0.42))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - ഗ്ലാസ് card

extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.03)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
    }
}