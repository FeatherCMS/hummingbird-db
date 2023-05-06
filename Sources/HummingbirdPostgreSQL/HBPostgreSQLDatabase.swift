import HummingbirdDatabase
import Logging
import NIOCore
import PostgresNIO

struct HBPostgreSQLDatabase: HBDatabase {

    let service: HBPostgreSQLDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

    let type: HBDatabaseType = .postgresql

    private func run<T>(
        _ block: @escaping ((PostgresConnection) async throws -> T)
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
                try await connection.query(
                    .init(stringLiteral: query),
                    logger: logger
                )
            }
        }
    }

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
    {
        try await run { connection in
            let stream = try await connection.query(
                .init(stringLiteral: query),
                logger: logger
            )
            let decoder = PostgreSQLRowDecoder()
            var res: [T] = []
            for try await row in stream {

                let racRow = row.makeRandomAccess()
                //                print(row, racRow)
                let item = try decoder.decode(T.self, from: racRow)
                res.append(item)
            }
            return res
        }
    }
}
