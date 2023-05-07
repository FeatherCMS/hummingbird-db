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

        //        switch app.db.type {
        //        case .postgresql:
        //            print("postgresql")
        //        case .sqlite:
        //            print("sqlite")
        //        }

        var xs: [String] = []
        for _ in 1...10 {
            let id = UUID()
            let title = "random title"
            let url = "lorem ipusm"
            let order = 1

            let x =
                "INSERT INTO todos (id, title, url, \"order\") VALUES ('\(id)', '\(title)', '\(url)', \(order));"

            xs.append(x)
        }

        try await db.executeRaw([
            "DROP TABLE todos",

            """
            CREATE TABLE
                todos
            (
                "id" uuid PRIMARY KEY,
                "title" text NOT NULL,
                "order" integer,
                "url" text
            );
            """,

            """
            ALTER TABLE
                todos
            ADD COLUMN
                "completed" BOOLEAN
            DEFAULT FALSE;
            """,
        ])

        try await db.executeRaw(xs)

        let todos = try await db.execute(
            .init(
                unsafeSQL: "SELECT * FROM todos"
            ),
            rowType: Todo.self
        )

        XCTAssertEqual(todos.count, 10)

        let newTodo = Todo(
            id: .init(),
            title: "yeah",
            order: 420,
            url: "spacex.com",
            completed: true
        )

        try await app.db.execute([
            HBDatabaseQuery(
                unsafeSQL: """
                    INSERT INTO
                        todos (id, title, url, "order", completed)
                    VALUES
                        (:id:, :title:, :url:, :order:, :completed:)
                    """,
                bindings: newTodo
            )
        ])

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
