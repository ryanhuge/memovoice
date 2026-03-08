import Foundation
import KeychainAccess

enum KeychainHelper {
    nonisolated(unsafe) private static let keychain = Keychain(service: "com.memovoice.app")
        .accessibility(.afterFirstUnlock)

    static func save(key: String, value: String) throws {
        try keychain.set(value, key: key)
    }

    static func get(key: String) -> String? {
        try? keychain.get(key)
    }

    static func delete(key: String) throws {
        try keychain.remove(key)
    }

    // MARK: - Convenience for API Keys

    static func getAPIKey(for provider: TranslationProvider) -> String? {
        get(key: provider.keychainKey)
    }

    static func saveAPIKey(_ key: String, for provider: TranslationProvider) throws {
        try save(key: provider.keychainKey, value: key)
    }

    static func getTTSKey(for provider: TTSProvider) -> String? {
        get(key: provider.keychainKey)
    }

    static func saveTTSKey(_ key: String, for provider: TTSProvider) throws {
        try save(key: provider.keychainKey, value: key)
    }
}
