import HummingbirdDatabase
import Logging
import NIOCore
import SQLiteNIO

// NOTE: total hack for now
private struct NoBinding: Encodable {}

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

    private func prepare(
        query: any HBDatabaseQueryInterface
    ) throws -> (String, [SQLiteData]) {
        var patterns: [String: SQLiteData] = [:]

        let encoder = SQLiteRowEncoder()
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
        var currentBindings: [SQLiteData] = []

        for c in query.unsafeSQL {
            if c == ":" {
                if isOpened {
                    bindingQuery += "?"
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

        //        print(patterns, bindingQuery, currentBindings)

        return (bindingQuery, currentBindings)
    }

    func executeRaw(_ queries: [String]) async throws {
        try await execute(
            queries.map { HBDatabaseQuery<NoBinding>(unsafeSQL: $0) }
        )
    }

    func execute(_ queries: [any HBDatabaseQueryInterface]) async throws {
        try await run { connection in
            for query in queries {
                let q = try prepare(query: query)
                _ = try await connection.query(q.0, q.1).get()
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
