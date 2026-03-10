import XCTest
@testable import GarageKeep

final class KeychainHelperTests: XCTestCase {
    private let testKey = "test.keychain.key"

    override func tearDown() {
        KeychainHelper.delete(for: testKey)
        KeychainHelper.clearAll()
        super.tearDown()
    }

    func testSaveAndRead_returnsStoredValue() {
        KeychainHelper.save("hello", for: testKey)
        XCTAssertEqual(KeychainHelper.read(for: testKey), "hello")
    }

    func testSave_overwritesExistingValue() {
        KeychainHelper.save("first", for: testKey)
        KeychainHelper.save("second", for: testKey)
        XCTAssertEqual(KeychainHelper.read(for: testKey), "second")
    }

    func testDelete_removesValue() {
        KeychainHelper.save("to-delete", for: testKey)
        KeychainHelper.delete(for: testKey)
        XCTAssertNil(KeychainHelper.read(for: testKey))
    }

    func testRead_returnsNil_whenNothingStored() {
        XCTAssertNil(KeychainHelper.read(for: "nonexistent.key.xyz"))
    }

    func testClearAll_removesBothTokenKeys() {
        KeychainHelper.save("access", for: KeychainHelper.accessTokenKey)
        KeychainHelper.save("refresh", for: KeychainHelper.refreshTokenKey)
        KeychainHelper.clearAll()
        XCTAssertNil(KeychainHelper.read(for: KeychainHelper.accessTokenKey))
        XCTAssertNil(KeychainHelper.read(for: KeychainHelper.refreshTokenKey))
    }
}
