import SwiftUI

enum FinStyle {
    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.07, green: 0.12, blue: 0.30),
                 Color(red: 0.16, green: 0.30, blue: 0.62)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let accent = LinearGradient(
        colors: [Color(red: 0.25, green: 0.45, blue: 0.95),
                 Color(red: 0.45, green: 0.30, blue: 0.90)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let receive = Color(red: 0.12, green: 0.65, blue: 0.40)
    static let pay = Color(red: 0.88, green: 0.28, blue: 0.30)
    static let heroReceive = Color(red: 0.50, green: 0.95, blue: 0.72)
    static let heroPay = Color(red: 1.0, green: 0.66, blue: 0.62)

    static func avatarGradient(for name: String) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.25, green: 0.45, blue: 0.95), Color(red: 0.45, green: 0.30, blue: 0.90)],
            [Color(red: 0.10, green: 0.65, blue: 0.60), Color(red: 0.20, green: 0.80, blue: 0.45)],
            [Color(red: 0.95, green: 0.55, blue: 0.20), Color(red: 0.95, green: 0.35, blue: 0.40)],
            [Color(red: 0.55, green: 0.30, blue: 0.85), Color(red: 0.90, green: 0.35, blue: 0.65)],
            [Color(red: 0.15, green: 0.55, blue: 0.90), Color(red: 0.10, green: 0.75, blue: 0.85)]
        ]
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let colors = palettes[sum % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func initial(of name: String) -> String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }
}

struct AvatarView: View {
    let name: String
    var size: CGFloat = 46

    var body: some View {
        Text(FinStyle.initial(of: name))
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(FinStyle.avatarGradient(for: name))
            .clipShape(Circle())
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}