import HummingbirdDatabase
import NIOCore
import Logging
import SQLiteNIO

struct HBSQLiteDatabase: HBDatabase {
    
    let service: HBSQLiteDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

    func execute<T>(
        _ block: @escaping ((SQLiteConnection) async throws -> T)
    ) async throws -> T {
        let pool = service.poolGroup.getConnectionPool(on: eventLoop)
        return try await pool.lease(logger: logger, process: block)
    }
}
