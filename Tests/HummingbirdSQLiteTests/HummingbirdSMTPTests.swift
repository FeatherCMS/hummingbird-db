import XCTest
import NIO
import Logging
import Hummingbird
import HummingbirdDatabase
@testable import HummingbirdSQLite

final class HummingbirdSQLiteTests: XCTestCase {
    
    func testExample() async throws {
        let app = HBApplication()
        
        app.services.setUpSQLiteDatabase(
            storage: .memory,
            threadPool: app.threadPool,
            eventLoopGroup: app.eventLoopGroup,
            logger: app.logger
        )
        
        guard let db = app.db as? HBSQLiteDatabase else {
            return XCTFail()
        }
        
        try await db.execute { connection in
            let v = try await connection.query("select sqlite_version();").get()
            print(v)
        }

        try app.shutdownApplication()
    }
}
