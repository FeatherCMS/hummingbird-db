import HummingbirdDatabase
import NIOCore
import Logging

struct HBSQLiteDatabase: HBDatabase {
    
    let service: HBSQLiteDatabaseService
    let logger: Logger
    let eventLoop: EventLoop
    
    func getConnectionPool() async throws {
        let pool = service.poolGroup.getConnectionPool(on: eventLoop)
        let res = try await pool.lease(logger: logger) { connection in
            return true
        }
    }
}
