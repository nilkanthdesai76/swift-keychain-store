import XCTest
@testable import KeychainStore

struct UserSession: Codable, Equatable {
    let userId: String
    let expiresAt: Date
}

final class KeychainStoreTests: XCTestCase {
    let store = KeychainStore(service: "com.nilkanth.keychainstore.tests")
    let testKey = "test_auth_token"

    override func tearDownWithError() throws {
        try? store.delete(forKey: testKey)
    }

    func testStringPersistence() throws {
        let expected = "sample_secure_jwt_token_12345"
        try store.setString(expected, forKey: testKey)

        let retrieved = try store.getString(forKey: testKey)
        XCTAssertEqual(retrieved, expected)

        try store.delete(forKey: testKey)
        let afterDelete = try store.getString(forKey: testKey)
        XCTAssertNil(afterDelete)
    }

    func testCodableModelPersistence() throws {
        let session = UserSession(userId: "user_999", expiresAt: Date())
        let sessionKey = "user_session_key"

        try store.setModel(session, forKey: sessionKey)
        let loaded = try store.getModel(UserSession.self, forKey: sessionKey)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.userId, session.userId)

        try store.delete(forKey: sessionKey)
    }

    func testUpsertUpdatesValue() throws {
        try store.setString("first_value", forKey: testKey)
        try store.setString("second_value", forKey: testKey)

        let retrieved = try store.getString(forKey: testKey)
        XCTAssertEqual(retrieved, "second_value")
    }
}
