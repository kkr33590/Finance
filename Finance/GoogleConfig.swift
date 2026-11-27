import Foundation

enum GoogleConfig {
    // Google Cloud-ൽ ഉണ്ടാക്കിയ iOS OAuth Client ID ഇവിടെ പേസ്റ്റ് ചെയ്യുക
    static let clientID = "917786745333-dgov871hvftb7sea7f4800jq4pqb9954.apps.googleusercontent.com"

    static let scopes = "openid email https://www.googleapis.com/auth/drive.appdata"

    static var isConfigured: Bool {
        clientID.hasSuffix(".apps.googleusercontent.com")
    }

    /// Client ID-യുടെ reversed രൂപം (Google ഇതിലേക്കാണ് ലോഗിൻ കഴിഞ്ഞ് തിരിച്ചു വിടുന്നത്)
    static var callbackScheme: String {
        "com.googleusercontent.apps."
            + clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
    }

    static var redirectURI: String {
        callbackScheme + ":/oauth2redirect"
    }
}