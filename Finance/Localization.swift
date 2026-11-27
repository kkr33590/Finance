import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case ml, en

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ml: return "മലയാളം"
        case .en: return "English"
        }
    }
}

/// tr("English text", "മലയാളം text") — തിരഞ്ഞെടുത്ത ഭാഷയിലെ text തിരിച്ചു തരും
func tr(_ en: String, _ ml: String) -> String {
    UserDefaults.standard.string(forKey: "appLanguage") == "en" ? en : ml
}