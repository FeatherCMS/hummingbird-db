import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import XCTest

@testable import HummingbirdSQLite

final class HummingbirdSQLiteTests: XCTestCase {

    func testExample() async throws {
        let app = HBApplication()
        
        var logger = Logger(label: "sqlite-logger")
        logger.logLevel = .info

        app.services.setUpSQLiteDatabase(
            storage: .memory,
            threadPool: app.threadPool,
            eventLoopGroup: app.eventLoopGroup,
            logger: logger
        )

        guard let db = app.db as? HBSQLiteDatabase else {
            return XCTFail()
        }

        var xs: [String] = []
        for _ in 0...10 {
            let id = UUID()
            let title = "random title"
            let url = "lorem ipusm"
            let order = 1

            let x =
                "INSERT INTO todos (id, title, url, \"order\") VALUES ('\(id)', '\(title)', '\(url)', \(order));"

            xs.append(x)
        }

        try await db.executeRaw(
            queries: [
                "DROP TABLE IF EXISTS todos",

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
            ]
        )
        
        try await app.db.execute(queries: [
            HBDatabaseQuery(
                unsafeSQL: #"CREATE TABLE "scores" ("score" INTEGER NOT NULL);"#,
                bindings: [:]
            ),
            HBDatabaseQuery(
                unsafeSQL: #"INSERT INTO scores (score) VALUES (:1:);"#,
                bindings: ["1": 1]
            ),
        ])

        let newTodo = Todo(
            id: .init(),
            title: "yeah",
            order: 420,
            url: "spacex.com",
            completed: true
        )
        
        /// must re-create table, in-memory db messes up this...
        try await app.db.execute(queries: [
            HBDatabaseQuery(
                unsafeSQL: """
                CREATE TABLE
                    todos
                (
                    "id" uuid PRIMARY KEY,
                    "title" text NOT NULL,
                    "order" integer,
                    "url" text
                );
                """,
                bindings: newTodo
            ),
            HBDatabaseQuery(
                unsafeSQL: """
                INSERT INTO
                    `todos` (`id`, `title`, `url`, `order`)
                VALUES
                    (:id:, :title:, :url:, :order:)
                """,
                bindings: newTodo
            ),
        ])
        
        try await db.executeRaw(
            queries: xs
        )

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
