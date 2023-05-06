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

    func execute(_ queries: [String]) async throws {
        fatalError()
    }

    func executeWithBindings(_ queries: [String]) async throws {
        fatalError()
    }

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
    {
        fatalError()
    }

    //    func query<T: Decodable>(_ sql: String) async throws -> [T] {
    //        try await execute { connection in
    //
    //            let res = try await connection.query(sql).get()
    //            for row in res {
    //                //                row.decode(model: <#T##Decodable.Protocol#>, with: <#T##SQLRowDecoder#>)
    //
    //            }
    //            return []
    //        }
    //    }

    //    let stream = try await connection.query(
    //        #"SELECT "id", "title", "order", "url", "completed" FROM todospostgres"#,
    //        logger: request.logger
    //    )
    //    var todos: [Todo] = []
    //    for try await (id, title, order, url, completed) in stream.decode(
    //        (UUID, String, Int?, String, Bool?).self,
}
