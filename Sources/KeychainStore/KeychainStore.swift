import Foundation
import Security

/// Thread-safe, Sendable wrapper providing type-safe Keychain access for iOS and macOS.
public struct KeychainStore: Sendable {
    public let service: String
    public let accessGroup: String?

    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Core Operations

    /// Saves raw Data to the Keychain under a specific key.
    @discardableResult
    public func set(
        _ data: Data,
        forKey key: String,
        accessibility: KeychainAccessibility = .afterFirstUnlock
    ) throws -> Bool {
        var query = baseQuery(forKey: key)
        query[kSecAttrAccessible as String] = accessibility.attributeValue
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Upsert: update existing item
            let updateQuery = baseQuery(forKey: key)
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: accessibility.attributeValue
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
            return true
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        return true
    }

    /// Retrieves raw Data from the Keychain for a specific key.
    public func get(forKey key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unhandledError(status: status)
        }

        return data
    }

    /// Deletes an item from the Keychain.
    @discardableResult
    public func delete(forKey key: String) throws -> Bool {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecItemNotFound || status == errSecSuccess {
            return true
        }

        throw KeychainError.unhandledError(status: status)
    }

    /// Clears all keys for this service.
    @discardableResult
    public func removeAll() throws -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound || status == errSecSuccess {
            return true
        }

        throw KeychainError.unhandledError(status: status)
    }

    // MARK: - Convenience Helpers

    /// Saves a String value.
    public func setString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try set(data, forKey: key)
    }

    /// Retrieves a String value.
    public func getString(forKey key: String) throws -> String? {
        guard let data = try get(forKey: key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    /// Saves a Codable model.
    public func setModel<T: Encodable>(_ model: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(model)
        try set(data, forKey: key)
    }

    /// Retrieves a Codable model.
    public func getModel<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try get(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Private Helpers

    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
