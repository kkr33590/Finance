import SwiftUI

// A glowing beam that runs around the border of a view.
// Use it like this: .borderBeam(RoundedRectangle(cornerRadius: 12), active: isFocused)
enum BeamColors {
    static let neon: [Color] = [
        Color(red: 0.00, green: 0.90, blue: 1.00),
        Color(red: 0.25, green: 0.55, blue: 1.00),
        Color(red: 0.55, green: 0.35, blue: 1.00),
        Color(red: 1.00, green: 0.30, blue: 0.85)
    ]
}

struct BeamBorder<S: InsettableShape>: View {
    let shape: S
    let active: Bool
    let colors: [Color]
    let lineWidth: CGFloat
    let duration: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(shape: S, active: Bool, colors: [Color], lineWidth: CGFloat, duration: Double) {
        self.shape = shape
        self.active = active
        self.colors = colors
        self.lineWidth = lineWidth
        self.duration = duration
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !active || reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let progress = (t / max(duration, 0.1)).truncatingRemainder(dividingBy: 1)
            let angle: Double = reduceMotion ? 40 : progress * 360
            let gradient = Self.gradient(colors, angle: angle)

            ZStack {
                shape
                    .strokeBorder(gradient, lineWidth: lineWidth * 3.5)
                    .blur(radius: 7)
                    .opacity(0.65)
                shape
                    .strokeBorder(gradient, lineWidth: lineWidth)
            }
        }
        .opacity(active ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: active)
        .allowsHitTesting(false)
    }

    static func gradient(_ colors: [Color], angle: Double) -> AngularGradient {
        let list = colors.isEmpty ? [Color.white] : colors
        let count = list.count
        let start = 0.04
        let length = 0.32

        var stops: [Gradient.Stop] = [
            Gradient.Stop(color: list[0].opacity(0), location: 0)
        ]

        for (index, color) in list.enumerated() {
            let fraction = count > 1 ? Double(index) / Double(count - 1) : 1
            let strength = 0.35 + 0.65 * fraction
            stops.append(
                Gradient.Stop(color: color.opacity(strength), location: start + length * fraction)
            )
        }

        let last = list[count - 1]
        stops.append(Gradient.Stop(color: last.opacity(0), location: start + length + 0.03))
        stops.append(Gradient.Stop(color: last.opacity(0), location: 1))

        return AngularGradient(
            gradient: Gradient(stops: stops),
            center: .center,
            angle: .degrees(angle)
        )
    }
}

extension View {
    func borderBeam<S: InsettableShape>(
        _ shape: S,
        active: Bool = true,
        colors: [Color] = BeamColors.neon,
        lineWidth: CGFloat = 1.6,
        duration: Double = 2.6
    ) -> some View {
        overlay(
            BeamBorder(
                shape: shape,
                active: active,
                colors: colors,
                lineWidth: lineWidth,
                duration: duration
            )
        )
    }
}