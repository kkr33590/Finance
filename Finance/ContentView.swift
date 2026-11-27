import SwiftUI

struct ContentView: View {
    // @State remembers a value. When it changes, SwiftUI draws the screen again.
    @State private var count = 0
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            // VStack puts its children in a vertical column.
            VStack(spacing: 24) {
                Text("kKr")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.textPrimary)

                // A text field needs a Binding ($name), so typing updates the variable.
                TextField("Your name", text: $name)
                    .focused($nameFocused)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
                    .borderBeam(
                        RoundedRectangle(cornerRadius: 12, style: .continuous),
                        active: nameFocused
                    )

                Text(name.isEmpty ? "Hello!" : "Hello, \(name)!")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)

                Text("\(count)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())

                HStack(spacing: 16) {
                    roundButton("minus") { count -= 1 }
                    roundButton("plus") { count += 1 }
                }
            }
            .padding(24)
        }
    }

    // A small helper that builds a round button. We use it twice above.
    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation { action() }
        } label: {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.accent))
        }
    }
}