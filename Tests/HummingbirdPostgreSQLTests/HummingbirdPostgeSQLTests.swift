import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import XCTest

@testable import HummingbirdPostgreSQL

final class HummingbirdPostgreSQLTests: XCTestCase {

    func testExample() async throws {
        let env = ProcessInfo.processInfo.environment
        let app = HBApplication()

        var port = 5432
        if let rawPort = env["PG_PORT"],
            let customPort = Int(rawPort)
        {
            port = customPort
        }

        app.services.setUpPostgreSQLDatabase(
            configuration: .init(
                host: env["PG_HOST"] ?? "127.0.0.1",
                port: port,
                username: env["PG_USER"] ?? "postgres",
                password: env["PG_PASS"]!,
                database: env["PG_DATABASE"]!,
                tls: .disable
            ),
            eventLoopGroup: app.eventLoopGroup,
            logger: app.logger
        )

        guard let db = app.db as? HBPostgreSQLDatabase else {
            return XCTFail()
        }

        switch app.db.type {
        case .postgresql:
            print("postgresql")
        case .sqlite:
            print("sqlite")
        }

        let id = UUID()
        let title = "random title"
        let url = "lorem ipusm"
        let order = 1

        let x =
            "INSERT INTO todospostgres (id, title, url, \"order\") VALUES ('\(id)', '\(title)', '\(url)', \(order));"

        try await db.execute([
            "DROP TABLE todospostgres",

            """
            CREATE TABLE
                todospostgres
            (
                "id" uuid PRIMARY KEY,
                "title" text NOT NULL,
                "order" integer,
                "url" text
            );
            """,

            """
            ALTER TABLE
                todospostgres
            ADD COLUMN
                "completed" BOOLEAN
            DEFAULT FALSE;
            """,
            x,
        ])

        //        try await app.db.executeWithBindings([x])

        let todos = try await db.execute(
            #"SELECT "id", "title", "order", "url", "completed" FROM todospostgres"#,
            as: Todo.self
        )

        print(todos)

        //                    for try await (id, title, order, url, completed) in stream.decode(
        //                        (UUID, String, Int?, String, Bool?).self,
        //                        context: .default
        //                    ) {
        //                        print(id)
        //                    }
        //                    print(stream)

        try app.shutdownApplication()
    }
}

struct Todo: Codable {
    var id: UUID
    var title: String
    var order: Int?
    var url: String
    var completed: Bool?
}
