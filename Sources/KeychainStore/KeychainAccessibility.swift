import Foundation
import Security

public enum KeychainAccessibility: Sendable {
    case whenUnlocked
    case afterFirstUnlock
    case whenPasscodeSetThisDeviceOnly
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly

    public var attributeValue: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

public enum KeychainError: LocalizedError, Sendable, Equatable {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item was not found in the Keychain."
        case .duplicateItem:
            return "Item already exists in the Keychain."
        case .invalidData:
            return "Data could not be encoded or decoded."
        case .unhandledError(let status):
            if let message = SecCopyErrorMessageString(status, nil) {
                return String(message)
            }
            return "Keychain operation failed with status: \(status)."
        }
    }
}
