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