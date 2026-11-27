import SwiftUI

// All the colors of the app live here. Change a number and the whole app changes.
enum Theme {
    // Red, green and blue, each from 0 to 1.
    static let accent = Color(red: 0.30, green: 0.55, blue: 1.00)

    static let bg = Color.black
    static let surface = Color(white: 0.09)
    static let surfaceHigh = Color(white: 0.14)
    static let border = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.62)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.38)
    static let success = Color(red: 0.25, green: 0.80, blue: 0.50)
}