@testable import FeatherDatabase
import XCTest

final class FeatherDatabaseTests: XCTestCase {
    
    func testExample() async throws {
        let joannis = "joannis"
        let query: FeatherDatabaseQuery = "SELECT * FROM users WHERE name = \(joannis)"
        XCTAssertEqual(query.unsafeSQL, "SELECT * FROM users WHERE name = ?")
        XCTAssertEqual(query.bindings.count, 1)
    }
}
