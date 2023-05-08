import Hummingbird
import HummingbirdDatabase
import HummingbirdSQLite
import Logging
import NIO
import XCTest

struct Todo: Codable {
    let id: UUID
    let title: String
    let order: Int?
    let url: String?
    let completed: Bool?
}

final class HummingbirdSQLiteTests: XCTestCase {

    private func createTestApp(path: String) -> HBApplication {
        let app = HBApplication()

        var logger = Logger(label: "sqlite-logger")
        logger.logLevel = .info

        app.services.setUpSQLiteDatabase(
            path: path,
            threadPool: app.threadPool,
            eventLoopGroup: app.eventLoopGroup,
            logger: logger
        )
        return app
    }

    private func runTest(_ block: (HBDatabase) async throws -> Void)
        async throws
    {
        let path = "/Users/tib/\(UUID().uuidString).sqlite"
        let app = createTestApp(path: path)
        do {
            try await block(app.db)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
        try app.shutdownApplication()
        try FileManager.default.removeItem(atPath: path)
    }

    func testExample() async throws {
        let path = "/Users/tib/\(UUID().uuidString).sqlite"
        let app = createTestApp(path: path)

        var xs: [HBDatabaseQuery] = []
        for _ in 0...10 {
            let id = UUID()
            let title = "random title"
            let url = "lorem ipusm"
            let order = 1

            xs.append(
                .init(
                    unsafeSQL:
                        """
                        INSERT INTO
                            todos (id, title, url, `order`)
                        VALUES
                            (:0:, :1:, :2:, :3:)
                        """,
                    bindings:
                        id,
                    title,
                    url,
                    order
                )
            )
        }

        try await app.db.execute([
            .init(
                unsafeSQL:
                    """
                    DROP TABLE IF EXISTS todos
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

        try await app.db.execute([
            HBDatabaseQuery(
                unsafeSQL:
                    #"CREATE TABLE "scores" ("score" INTEGER NOT NULL);"#,
                bindings: ["foo": 1, "bar": 2]
            ),
            HBDatabaseQuery(
                unsafeSQL: #"INSERT INTO scores (score) VALUES (:1:);"#,
                bindings: ["1": 1]
            ),
        ])

        try await app.db.execute(xs)

        try app.shutdownApplication()
        try FileManager.default.removeItem(atPath: path)
    }

    func testBindings() async throws {

        try await runTest { db in
            try await db.execute([
                .init(
                    unsafeSQL:
                        """
                        CREATE TABLE
                            todos
                        (
                            "id" text NOT NULL PRIMARY KEY,
                            "title" text NOT NULL,
                            "order" integer,
                            "url" text,
                            "completed" BOOLEAN DEFAULT FALSE
                        )
                        """
                ),
                .init(
                    unsafeSQL:
                        """
                        CREATE TABLE foo ("bar" integer)
                        """
                ),
            ])

            let newTodo = Todo(
                id: .init(),
                title: "yeah",
                order: 420,
                url: nil,
                completed: true
            )

            try await db.execute(
                .insert(
                    into: "todos",
                    keys: ["id", "title", "url", "order"],
                    bindings: UUID(),
                    "foo",
                    "bar",
                    42
                )
            )

            try await db.execute([
                .init(
                    unsafeSQL: """
                        INSERT INTO
                            `todos` (`id`, `title`, `url`, `order`)
                        VALUES
                            (:id:, :title:, :url:, :order:)
                        """,
                    bindings:
                        newTodo
                ),
                .init(
                    unsafeSQL: """
                        INSERT INTO
                            `todos` (`id`, `title`, `url`, `order`)
                        VALUES
                            (:0:, :title:, :url:, :3:)
                        """,
                    bindings:
                        UUID(),
                    "hello",
                    "valami",
                    12,
                    newTodo
                ),

                .init(
                    unsafeSQL: """
                        INSERT INTO
                            `foo` (`bar`)
                        VALUES
                            (:0:), (:1:)
                        """,
                    bindings:
                        23,
                    42
                ),
            ])
        }
    }

    func testJoin() async throws {
        let path = "/Users/tib/\(UUID().uuidString).sqlite"
        let app = createTestApp(path: path)

        try await app.db.execute([
            .init(
                unsafeSQL:
                    """
                    CREATE TABLE products(
                        product text NOT null
                    );
                    """
            ),
            .init(
                unsafeSQL:
                    """
                    INSERT INTO products(product)
                    VALUES('P1'),('P2'),('P3');
                    """
            ),
            .init(
                unsafeSQL:
                    """
                    CREATE TABLE calendars(
                        y int NOT NULL,
                        m int NOT NULL
                    );
                    """
            ),
            .init(
                unsafeSQL:
                    """
                    INSERT INTO calendars(y,m)
                    VALUES
                        (2019,1),
                        (2019,2),
                        (2019,3),
                        (2019,4),
                        (2019,5),
                        (2019,6),
                        (2019,7),
                        (2019,8),
                        (2019,9),
                        (2019,10),
                        (2019,11),
                        (2019,12);
                    """
            ),
        ])

        struct Joined: Decodable {
            let product: String
            let y: Int
            let m: Int
        }

        let res = try await app.db.execute(
            .init(
                unsafeSQL:
                    """
                    SELECT *
                    FROM products
                    CROSS JOIN calendars;
                    """
            ),
            rowType: Joined.self
        )

        XCTAssertEqual(res.count, 36)

        try app.shutdownApplication()
        try FileManager.default.removeItem(atPath: path)
    }

}
