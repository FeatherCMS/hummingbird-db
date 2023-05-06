import HummingbirdDatabase
import Logging
import NIOCore
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

    func typedQueryBuilder(_ block: ((HBDatabaseType) -> String)) -> String {
        block(.sqlite)
    }

    func query<T: Decodable>(_ sql: String) async throws -> [T] {
        try await execute { connection in

            let res = try await connection.query(sql).get()
            for row in res {
                //                row.decode(model: <#T##Decodable.Protocol#>, with: <#T##SQLRowDecoder#>)

            }
            return []
        }
    }

    //    let stream = try await connection.query(
    //        #"SELECT "id", "title", "order", "url", "completed" FROM todospostgres"#,
    //        logger: request.logger
    //    )
    //    var todos: [Todo] = []
    //    for try await (id, title, order, url, completed) in stream.decode(
    //        (UUID, String, Int?, String, Bool?).self,
}
