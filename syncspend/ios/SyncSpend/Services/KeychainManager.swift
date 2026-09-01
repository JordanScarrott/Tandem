import Foundation
import Security

/// Secure wrapper around iOS Keychain for storing OIDC authentication tokens and credentials.
public enum KeychainManager {
    private static let service = "com.tandem.SyncSpend"
    private static let accountAuthToken = "spacetimedb_auth_token"
    private static let accountRefreshToken = "spacetimedb_refresh_token"
    private static let accountIdentity = "spacetimedb_identity"

    public static func saveAuthToken(_ token: String) {
        save(key: accountAuthToken, data: Data(token.utf8))
    }

    public static func getAuthToken() -> String? {
        guard let data = load(key: accountAuthToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func saveRefreshToken(_ token: String) {
        save(key: accountRefreshToken, data: Data(token.utf8))
    }

    public static func getRefreshToken() -> String? {
        guard let data = load(key: accountRefreshToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func saveIdentity(_ identity: String) {
        save(key: accountIdentity, data: Data(identity.utf8))
    }

    public static func getIdentity() -> String? {
        guard let data = load(key: accountIdentity) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func clear() {
        delete(key: accountAuthToken)
        delete(key: accountRefreshToken)
        delete(key: accountIdentity)
    }

    // MARK: - Private Keychain Helpers

    private static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        return status == errSecSuccess ? (dataTypeRef as? Data) : nil
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
