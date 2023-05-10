import FeatherDatabase
import Logging
import NIOCore
import PostgresNIO

public struct FeatherPostgresDatabase: FeatherDatabase {

    public let type: FeatherDatabaseType = .postgres

    let connection: PostgresConnection
    let logger: Logger
    let eventLoop: EventLoop
    
    public init(
        connection: PostgresConnection,
        logger: Logger,
        eventLoop: EventLoop
    ) {
        self.connection = connection
        self.logger = logger
        self.eventLoop = eventLoop
    }

    private func prepare(
        query: FeatherDatabaseQuery
    ) throws -> (String, PostgresBindings) {
        var patterns: [String: PostgresData] = [:]

        let encoder = PostgresRowEncoder()
        for b in query.bindings {
            let res = try encoder.encode(b)
            for item in res {
                patterns[item.0] = item.1
            }
        }
                
        var bindingQuery = ""
        var isOpened = false
        var currentKey = ""
        var currentIndex = 0
        var currentBindings = PostgresBindings()

        var index = 0
        for c in query.unsafeSQL {
            if c == "?" {
                bindingQuery += "$\(index + 1)"
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
                    bindingQuery += "$\(currentIndex + 1)"
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
            try await connection.query(
                .init(unsafeSQL: q.0, binds: q.1),
                logger: logger
            )
        }
    }

    public func execute<T: Decodable>(
        _ query: FeatherDatabaseQuery,
        rowType: T.Type
    ) async throws -> [T] {
        let q = try prepare(query: query)
        let stream = try await connection.query(
            .init(unsafeSQL: q.0, binds: q.1),
            logger: logger
        )
        let decoder = PostgresRowDecoder()
        var res: [T] = []
        for try await row in stream {
            let racRow = row.makeRandomAccess()
            let item = try decoder.decode(T.self, from: racRow)
            res.append(item)
        }
        return res
    }
}
