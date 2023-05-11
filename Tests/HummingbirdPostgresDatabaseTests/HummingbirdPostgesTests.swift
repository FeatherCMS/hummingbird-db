import Hummingbird
import HummingbirdPostgresDatabase
import XCTest
import PostgresNIO
import Logging

struct Todo: Codable {
    var id: UUID
    var title: String
    var order: Int?
    var url: String
    var completed: Bool?
}

final class HummingbirdPostgresTests: XCTestCase {

    func testExample() async throws {
        let env = ProcessInfo.processInfo.environment
        let app = HBApplication()

        var port = 5432
        if let rawPort = env["PG_PORT"],
            let customPort = Int(rawPort)
        {
            port = customPort
        }

        app.services.setUpPostgresDatabase(
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

        do {

//        switch app.db.type {
//        case .postgres:
//            print("postgres")
//        case .sqlite:
//            print("sqlite")
//        }

            try await app.db.execute([
                .init(
                    unsafeSQL:
                        """
                        DROP TABLE todos
                        """
                ),
                .init(
                    unsafeSQL:
                        """
                        CREATE TABLE
                            todos
                        (
                            "id" uuid PRIMARY KEY,
                            "title" text NOT NULL,
                            "order" integer,
                            "url" text
                        );
                        """
                ),
                .init(
                    unsafeSQL:
                        """
                        ALTER TABLE
                            todos
                        ADD COLUMN
                            "completed" BOOLEAN
                        DEFAULT FALSE;
                        """
                ),
            ])
            
            try await app.db.execute("""
                INSERT INTO
                    todos (id, title)
                VALUES
                    (\(UUID()), \("foo")
                """
            )
            let todos = try await app.db.execute(
                "SELECT * FROM todos",
                rowType: Todo.self
            )

            XCTAssertEqual(todos.count, 1)

            let newTodo = Todo(
                id: .init(),
                title: "yeah",
                order: 420,
                url: "spacex.com",
                completed: true
            )

            try await app.db.execute([
                .init(
                    unsafeSQL:
                        """
                        INSERT INTO
                            todos (id, title, url, "order", completed)
                        VALUES
                            (:id:, :title:, :url:, :order:, :completed:)
                        """,
                    bindings:
                        newTodo
                ),
                .init(
                    unsafeSQL:
                        """
                        INSERT INTO
                            todos (id, title, url, "order", completed)
                        VALUES
                            (:0:, :1:, :2:, :3:, :4:)
                        """,
                    bindings:
                        UUID(),
                    "foo"
                ),
            ])
        }
        catch let error as PSQLError {
            print(error.serverInfo ?? "Not a server info")
        }

        try app.shutdownApplication()
    }
}

