import SwiftUI
import UIKit
import CoreText

/// ആപ്പ് മുഴുവൻ ഉപയോഗിക്കുന്ന ഫോണ്ട് (Product Sans Bold Italic)
enum FinFont {
    static let fileName = "ProductSans-BoldItalic"
    static let name = "ProductSans-BoldItalic"

    /// ആപ്പ് തുടങ്ങുമ്പോൾ ഒരിക്കൽ വിളിക്കുന്നു
    static func register() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "ttf") else {
            print("FinFont: \(fileName).ttf bundle-ൽ കണ്ടില്ല")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            print("FinFont: register ചെയ്യാൻ പറ്റിയില്ല: \(String(describing: error))")
        }
        applyUIKitAppearance()
    }

    /// ഫോണ്ട് കിട്ടിയില്ലെങ്കിൽ സാധാരണ ഫോണ്ട് തനിയെ ഉപയോഗിക്കും
    static func font(_ size: CGFloat) -> Font {
        Font.custom(name, size: size)
    }

    // iOS-ൻ്റെ സാധാരണ text style വലുപ്പങ്ങൾക്ക് തുല്യം
    static let largeTitle = FinFont.font(34)
    static let title = FinFont.font(28)
    static let title2 = FinFont.font(22)
    static let title3 = FinFont.font(20)
    static let headline = FinFont.font(17)
    static let body = FinFont.font(17)
    static let subheadline = FinFont.font(15)
    static let footnote = FinFont.font(13)
    static let caption = FinFont.font(12)
    static let caption2 = FinFont.font(11)

    /// മുകളിലെ ടൈറ്റിലും ടൂൾബാർ ബട്ടണുകളും (Done, Save, Cancel…)
    private static func applyUIKitAppearance() {
        guard let titleFont = UIFont(name: name, size: 17) else { return }

        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.titleTextAttributes = [.font: titleFont]

        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.titleTextAttributes = [.font: titleFont]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = standard
        bar.compactAppearance = standard
        bar.scrollEdgeAppearance = scrollEdge

        let item = UIBarButtonItem.appearance()
        item.setTitleTextAttributes([.font: titleFont], for: .normal)
        item.setTitleTextAttributes([.font: titleFont], for: .highlighted)
    }
}