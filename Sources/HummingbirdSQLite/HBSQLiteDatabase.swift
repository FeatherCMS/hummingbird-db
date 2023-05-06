import HummingbirdDatabase
import Logging
import NIOCore
import SQLiteNIO

struct HBSQLiteDatabase: HBDatabase {

    let service: HBSQLiteDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

    let type: HBDatabaseType = .sqlite

    func run<T>(
        _ block: @escaping ((SQLiteConnection) async throws -> T)
    ) async throws -> T {
        let pool = service.poolGroup.getConnectionPool(on: eventLoop)
        return try await pool.lease(logger: logger, process: block)
    }

    func executeRaw(queries: [String]) async throws {
        try await run { connection in
            for query in queries {
                _ = try await connection.query(
                    .init(stringLiteral: query)
                )
                .get()
            }
        }
    }

    func executeWithBindings(_ queries: [String]) async throws {
        try await run { connection in
            for query in queries {
                _ = try await connection.query(query).get()
            }
        }
    }

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
    {
        try await run { connection in
            let decoder = SQLiteRowDecoder()
            return try await connection.query(query).get().map {
                try decoder.decode(T.self, from: $0)
            }
        }
    }
}
