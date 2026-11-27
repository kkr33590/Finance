import UIKit
import AuthenticationServices
import CryptoKit

enum AuthError: LocalizedError {
    case notConfigured
    case cancelled
    case notSignedIn
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return tr("Google Client ID is not set in GoogleConfig.swift",
                      "GoogleConfig.swift-ൽ Client ID ചേർത്തിട്ടില്ല")
        case .cancelled:
            return tr("Sign-in cancelled", "സൈൻ-ഇൻ റദ്ദാക്കി")
        case .notSignedIn:
            return tr("Please sign in again", "വീണ്ടും സൈൻ-ഇൻ ചെയ്യുക")
        case .failed(let message):
            return message
        }
    }
}

private final class PresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

/// Google OAuth 2.0 (PKCE) — SDK ഇല്ലാതെ
@MainActor
final class GoogleAuth {
    private let refreshKey = "refreshToken"
    private let emailKey = "googleEmail"
    private let tokenURL = "https://oauth2.googleapis.com/token"
    private let context = PresentationContext()
    private var session: ASWebAuthenticationSession?
    private var accessToken: String?
    private var expiry = Date.distantPast

    var email: String? { UserDefaults.standard.string(forKey: emailKey) }
    var hasRefreshToken: Bool { Keychain.get(refreshKey) != nil }

    // MARK: - സൈൻ-ഇൻ

    func signIn() async throws {
        guard GoogleConfig.isConfigured else { throw AuthError.notConfigured }

        let verifier = Self.randomString(64)
        let challenge = Self.sha256Base64URL(verifier)
        let state = Self.randomString(24)

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: GoogleConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: GoogleConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: GoogleConfig.scopes),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent select_account")
        ]

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let s = ASWebAuthenticationSession(
                url: comps.url!,
                callbackURLScheme: GoogleConfig.callbackScheme
            ) { url, error in
                if let url = url {
                    continuation.resume(returning: url)
                } else if let e = error as? ASWebAuthenticationSessionError,
                          e.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.cancelled)
                } else {
                    continuation.resume(throwing: error ?? AuthError.failed("No response"))
                }
            }
            s.presentationContextProvider = context
            s.prefersEphemeralWebBrowserSession = false
            self.session = s
            s.start()
        }

        let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }
        if let err = value("error") { throw AuthError.failed(err) }
        guard value("state") == state, let code = value("code") else {
            throw AuthError.failed("Invalid response from Google")
        }

        let json = try await postForm(tokenURL, [
            "client_id": GoogleConfig.clientID,
            "code": code,
            "code_verifier": verifier,
            "redirect_uri": GoogleConfig.redirectURI,
            "grant_type": "authorization_code"
        ])
        apply(json)
    }

    func signOut() {
        Keychain.delete(refreshKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        accessToken = nil
        expiry = Date.distantPast
    }

    // MARK: - Access token

    func validAccessToken() async throws -> String {
        if let token = accessToken, Date() < expiry.addingTimeInterval(-60) {
            return token
        }
        guard let refresh = Keychain.get(refreshKey) else { throw AuthError.notSignedIn }
        do {
            let json = try await postForm(tokenURL, [
                "client_id": GoogleConfig.clientID,
                "refresh_token": refresh,
                "grant_type": "refresh_token"
            ])
            apply(json)
        } catch AuthError.notSignedIn {
            signOut()
            throw AuthError.notSignedIn
        }
        guard let token = accessToken else { throw AuthError.notSignedIn }
        return token
    }

    // MARK: - Helpers

    private func apply(_ json: [String: Any]) {
        if let token = json["access_token"] as? String { accessToken = token }
        let seconds = (json["expires_in"] as? Double) ?? 3600
        expiry = Date().addingTimeInterval(seconds)
        if let refresh = json["refresh_token"] as? String {
            Keychain.set(refresh, for: refreshKey)
        }
        if let idToken = json["id_token"] as? String,
           let mail = Self.emailFromIDToken(idToken) {
            UserDefaults.standard.set(mail, forKey: emailKey)
        }
    }

    private func postForm(_ urlString: String, _ params: [String: String]) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params
            .map { "\(Self.encode($0.key))=\(Self.encode($0.value))" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.failed("Bad response from Google")
        }
        if let err = json["error"] as? String {
            if err == "invalid_grant" { throw AuthError.notSignedIn }
            throw AuthError.failed((json["error_description"] as? String) ?? err)
        }
        return json
    }

    private static let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

    private static func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
    }

    private static func randomString(_ length: Int) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private static func sha256Base64URL(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func emailFromIDToken(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return object["email"] as? String
    }
}