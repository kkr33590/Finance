import SwiftUI
import CoreText

/// Product Sans Bold Italic ഫോണ്ട് രജിസ്റ്റർ ചെയ്യാനും ഉപയോഗിക്കാനും
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
    }

    /// ഫോണ്ട് കിട്ടിയില്ലെങ്കിൽ സാധാരണ ഫോണ്ട് തനിയെ ഉപയോഗിക്കും
    static func font(_ size: CGFloat) -> Font {
        Font.custom(name, size: size)
    }
}