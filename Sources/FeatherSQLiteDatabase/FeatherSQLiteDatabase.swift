import FeatherDatabase
import Logging
import NIOCore
import SQLiteNIO

public struct FeatherSQLiteDatabase: FeatherDatabase {

    public let type: FeatherDatabaseType = .sqlite
    let connection: SQLiteConnection
    let logger: Logger
    let eventLoop: EventLoop
    
    public init(
        connection: SQLiteConnection,
        logger: Logger,
        eventLoop: EventLoop
    ) {
        self.connection = connection
        self.logger = logger
        self.eventLoop = eventLoop
    }

    private func prepare(
        query: FeatherDatabaseQuery
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

        var index = 0
        for c in query.unsafeSQL {
            if c == "?" {
                bindingQuery += "?"
                if query.bindings.indices.contains(index) {
                    let b = query.bindings[index]
                    let v = try encoder.encode(b)
                    if let binding = v.first?.1 {
                        currentBindings.append(binding)
                    }
                    else {
                        currentBindings.append(.null)
                    }
                    index += 1
                }
                else {
                    currentBindings.append(.null)
                    index += 1
                }
                continue
            }
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
            throw FeatherDatabaseError.binding
        }
        return (bindingQuery, currentBindings)
    }

    public func execute(_ queries: [FeatherDatabaseQuery]) async throws {
        for query in queries {
            let q = try prepare(query: query)
            _ = try await connection.query(q.0, q.1).get()
        }
    }

    public func execute<T: Decodable>(
        _ query: FeatherDatabaseQuery,
        rowType: T.Type
    ) async throws -> [T] {
        let decoder = SQLiteRowDecoder()
        let q = try prepare(query: query)
        return try await connection.query(q.0, q.1).get().map {
            try decoder.decode(T.self, from: $0)
        }
    }
}
