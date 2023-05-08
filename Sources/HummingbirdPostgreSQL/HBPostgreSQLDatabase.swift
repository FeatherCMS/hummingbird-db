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

    private func prepare(
        query: HBDatabaseQuery
    ) throws -> (String, PostgresBindings) {
        var patterns: [String: PostgresData] = [:]

        let encoder = PostgreSQLRowEncoder()
        for b in query.bindings {
            let res = try encoder.encode(b)
            for item in res {
                patterns[item.0] = item.1
            }
        }
        var bindingQuery = ""
        var isOpened = false
        var currentKey = ""
        var currentIndex = 1
        var currentBindings = PostgresBindings()

        for c in query.unsafeSQL {
            if c == ":" {
                if isOpened {
                    bindingQuery += "$"
                    bindingQuery += String(currentIndex)
                    if let binding = patterns[currentKey] {
                        currentBindings.append(binding)
                    }
                    else {
                        currentBindings.append(.null)
                    }

                    currentKey = ""
                    currentIndex += 1
                }
                isOpened = !isOpened
                continue
            }
            if isOpened {
                currentKey += String(c)
            }
            else {
                bindingQuery += String(c)
            }
        }
        if isOpened {  //} || currentIndex - 1 != patterns.count { // strict mode?
            throw HBDatabaseError.binding
        }
        return (bindingQuery, currentBindings)
    }

    func execute(_ queries: [HBDatabaseQuery]) async throws {
        try await run { connection in
            for query in queries {
                let q = try prepare(query: query)
                try await connection.query(
                    .init(unsafeSQL: q.0, binds: q.1),
                    logger: logger
                )
            }
        }
    }

    func execute<T: Decodable>(
        _ query: HBDatabaseQuery,
        rowType: T.Type
    ) async throws -> [T] {
        try await run { connection in
            let q = try prepare(query: query)
            let stream = try await connection.query(
                .init(unsafeSQL: q.0, binds: q.1),
                logger: logger
            )
            let decoder = PostgreSQLRowDecoder()
            var res: [T] = []
            for try await row in stream {
                let racRow = row.makeRandomAccess()
                let item = try decoder.decode(T.self, from: racRow)
                res.append(item)
            }
            return res
        }
    }
}
