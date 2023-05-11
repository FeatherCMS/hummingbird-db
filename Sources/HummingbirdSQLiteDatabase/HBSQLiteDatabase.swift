import FeatherDatabase
import FeatherSQLiteDatabase
import Logging
import NIOCore
import SQLiteNIO

struct HBSQLiteDatabase: FeatherDatabase {

    let type: FeatherDatabaseType = .sqlite

    let service: HBSQLiteDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

    func run<T>(
        _ block: @escaping ((SQLiteConnection) async throws -> T)
    ) async throws -> T {
        let pool = service.poolGroup.getConnectionPool(on: eventLoop)
        return try await pool.lease(logger: logger, process: block)
    }

    func execute(_ queries: [FeatherDatabaseQuery]) async throws {
        _ = try await run { connection in
            try await FeatherSQLiteDatabase(
                connection: connection,
                logger: logger,
                eventLoop: eventLoop
            )
            .execute(queries)
        }
    }

    func execute<T: Decodable>(
        _ query: FeatherDatabaseQuery,
        rowType: T.Type
    ) async throws -> [T] {
        try await run { connection in
            try await FeatherSQLiteDatabase(
                connection: connection,
                logger: logger,
                eventLoop: eventLoop
            )
            .execute(query, rowType: rowType)
        }
    }
}
