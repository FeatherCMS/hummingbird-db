import XCTest
import NIO
import Hummingbird
import HummingbirdDatabase
import HummingbirdPostgreSQL
import Logging

final class HummingbirdPostgreSQLTests: XCTestCase {
    
    func testExample() async throws {
        let env = ProcessInfo.processInfo.environment
        let app = HBApplication()
        
        try app.shutdownApplication()
    }
}
