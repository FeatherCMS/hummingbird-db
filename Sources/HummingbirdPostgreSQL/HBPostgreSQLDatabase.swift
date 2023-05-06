import HummingbirdDatabase
import Logging
import NIOCore
import PostgresNIO

struct HBPostgreSQLDatabase: HBDatabase {

    let service: HBPostgreSQLDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

    func execute<T>(
        _ block: @escaping ((PostgresConnection) async throws -> T)
    ) async throws -> T {
        let pool = service.poolGroup.getConnectionPool(on: eventLoop)
        return try await pool.lease(logger: logger, process: block)
    }

    func typedQueryBuilder(_ block: ((HBDatabaseType) -> String)) -> String {
        block(.sqlite)
    }
}
