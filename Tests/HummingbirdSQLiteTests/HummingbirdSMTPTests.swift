import XCTest
import NIO
import Hummingbird
import HummingbirdDatabase
import HummingbirdSQLite
import Logging

final class HummingbirdSQLiteTests: XCTestCase {
    
    func testExample() async throws {
        let env = ProcessInfo.processInfo.environment
        let app = HBApplication()
        
        try app.shutdownApplication()
    }
}
