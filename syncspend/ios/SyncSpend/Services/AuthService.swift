import Foundation
import Observation
import AuthenticationServices
import CryptoKit
import UIKit

/// Authentication and session management coordinator for OpenID Connect (OIDC) via SpacetimeAuth.
@Observable
public final class AuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = AuthService()

    public var isAuthenticated: Bool = false
    public var currentUserEmail: String?
    public var currentUserName: String?
    public var currentUserIdentity: String?
    public var tokenExpirationTimestamp: TimeInterval?
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let authAuthority = "https://auth.spacetimedb.com/oidc"
    private let clientId = "client_034HBfvzsY4Xnxn1pwNaWA"
    private let redirectURI = "syncspend://auth/callback"
    private let callbackScheme = "syncspend"

    public override init() {
        super.init()
        checkExistingSession()
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ??
                UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }

    // MARK: - Session Lifecycle

    /// Checks Keychain for existing tokens on app startup with proactive expiration validation
    public func checkExistingSession() {
        if let token = KeychainManager.getAuthToken(), !token.isEmpty {
            parseAndPopulateClaims(from: token)
            if let ident = KeychainManager.getIdentity() {
                self.currentUserIdentity = ident
            }

            let now = Date().timeIntervalSince1970
            if let exp = tokenExpirationTimestamp, exp <= now + 60 {
                // Token expired or expiring in < 60s -> attempt proactive silent refresh
                Task { @MainActor in
                    do {
                        try await self.refreshSession()
                    } catch {
                        print("Session token expired and silent refresh failed: \(error)")
                        self.logout()
                    }
                }
            } else {
                self.isAuthenticated = true
            }
        } else {
            self.isAuthenticated = false
        }
    }

    /// Initiates OIDC Authorization Code Flow with PKCE via ASWebAuthenticationSession
    @MainActor
    public func loginWithSpacetimeAuth() async throws {
        self.isLoading = true
        self.errorMessage = nil

        do {
            // 1. Generate PKCE code verifier and code challenge
            let verifier = generateCodeVerifier()
            let challenge = generateCodeChallenge(from: verifier)
            let state = UUID().uuidString

            // 2. Construct Authorization URL
            var components = URLComponents(string: "\(authAuthority)/auth")
            guard components != nil else {
                throw URLError(.badURL)
            }

            components?.queryItems = [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: "openid profile email offline_access"),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "code_challenge", value: challenge),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "state", value: state)
            ]

            guard let authURL = components?.url else {
                throw URLError(.badURL)
            }

            // 3. Launch Web Authentication Session
            let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: self.callbackScheme
                ) { callbackURL, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let callbackURL = callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(throwing: URLError(.unknown))
                    }
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                session.start()
            }

            // 4. Extract authorization code from callback
            guard let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
                throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code in redirect callback"])
            }

            // 5. Exchange authorization code for OIDC tokens
            try await exchangeCodeForTokens(code: code, verifier: verifier)
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Exchanges authorization code for ID and refresh tokens
    public func exchangeCodeForTokens(code: String, verifier: String) async throws {
        guard let tokenURL = URL(string: "\(authAuthority)/token") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": verifier
        ]

        request.httpBody = params.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(escapedKey)=\(escapedValue)"
        }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown token error"
            throw NSError(domain: "AuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Token exchange failed: \(errorBody)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["id_token"] as? String else {
            throw NSError(domain: "AuthService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Malformed token response: missing id_token"])
        }

        // Save tokens securely in Keychain
        KeychainManager.saveAuthToken(idToken)
        if let refreshToken = json["refresh_token"] as? String {
            KeychainManager.saveRefreshToken(refreshToken)
        }

        self.isAuthenticated = true
        parseAndPopulateClaims(from: idToken)
    }

    /// Refreshes access tokens silently using stored refresh_token
    public func refreshSession() async throws {
        guard let refreshToken = KeychainManager.getRefreshToken() else {
            throw NSError(domain: "AuthService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
        }

        guard let tokenURL = URL(string: "\(authAuthority)/token") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": clientId,
            "refresh_token": refreshToken
        ]

        request.httpBody = params.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(escapedKey)=\(escapedValue)"
        }.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            logout()
            throw NSError(domain: "AuthService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Session refresh failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newIdToken = json["id_token"] as? String else {
            throw NSError(domain: "AuthService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid token refresh payload"])
        }

        KeychainManager.saveAuthToken(newIdToken)
        if let newRefreshToken = json["refresh_token"] as? String {
            KeychainManager.saveRefreshToken(newRefreshToken)
        }

        self.isAuthenticated = true
        parseAndPopulateClaims(from: newIdToken)
    }

    /// Logs out current user, clearing credentials and resetting active session
    public func logout() {
        KeychainManager.clear()
        self.isAuthenticated = false
        self.currentUserEmail = nil
        self.currentUserName = nil
        self.currentUserIdentity = nil
        self.tokenExpirationTimestamp = nil
    }

    // MARK: - Private Helpers (PKCE & JWT Claims)

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }

    private func parseAndPopulateClaims(from jwt: String) {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count >= 2 else { return }

        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return
        }

        if let email = json["email"] as? String {
            self.currentUserEmail = email
        }
        if let name = json["name"] as? String ?? json["preferred_username"] as? String {
            self.currentUserName = name
        }
        if let sub = json["sub"] as? String {
            self.currentUserIdentity = sub
        }
        if let exp = json["exp"] as? NSNumber {
            self.tokenExpirationTimestamp = exp.doubleValue
        } else if let exp = json["exp"] as? Double {
            self.tokenExpirationTimestamp = exp
        }
    }
}
