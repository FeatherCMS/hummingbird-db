import FeatherDatabase
@testable import FeatherPostgresDatabase
import Logging
import NIO
import XCTest
import PostgresNIO

struct Todo: Codable {
    let id: UUID
    let title: String
    let order: Int?
    let url: String?
    let completed: Bool?
}

extension FeatherDatabaseQuery {

    static func insert(
        into table: String,
        keys: [String],
        bindings: any Encodable...
    ) -> FeatherDatabaseQuery {
        let t = #""\#(table)""#
        let k = keys.map { #""\#($0)""# }.joined(separator: ",")
        let b = (0..<keys.count).map { ":\($0):" }.joined(separator: ",")
        let sql = "INSERT INTO \(t) (\(k)) VALUES (\(b))"
        return .init(unsafeSQL: sql, bindings: bindings)
    }
}

final class FeatherSQLiteDatabaseTests: XCTestCase {

    private func runTest(
        _ block: (FeatherDatabase) async throws -> Void
    ) async throws {
        let logger = Logger(label: "test-logger")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let eventLoop = eventLoopGroup.any()
        let env = ProcessInfo.processInfo.environment

        var port = 5432
        if let rawPort = env["PG_PORT"],
            let customPort = Int(rawPort)
        {
            port = customPort
        }
            
        let config = PostgresConnection.Configuration(
            host: env["PG_HOST"] ?? "127.0.0.1",
            port: port,
            username: env["PG_USER"] ?? "postgres",
            password: env["PG_PASS"]!,
            database: env["PG_DATABASE"]!,
            tls: .disable
        )

        let conn = try await PostgresConnection.connect(
            on: eventLoop,
            configuration: config,
            id: 0,
            logger: logger
        )
        
        let db = FeatherPostgresDatabase(
            connection: conn,
            logger: logger,
            eventLoop: eventLoop
        )
        print(conn)
        print(db.connection)
        
        do {
            try await block(db)
        }
        catch let error as PSQLError {
            XCTFail(error.serverInfo.debugDescription)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
        try await conn.close().get()
        try await eventLoopGroup.shutdownGracefully()
    }

    func testExample() async throws {
        try await runTest { db in
            var xs: [FeatherDatabaseQuery] = []
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
                            todos (id, title, url, "order")
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
            
            try await db.execute([
                .init(
                    unsafeSQL:
                    """
                    DROP TABLE IF EXISTS todos
                    """
                ),
                .init(
                    unsafeSQL:
                    """
                    CREATE TABLE IF NOT EXISTS
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
            
            try await db.execute([
                .init(
                    unsafeSQL:
                        #"CREATE TABLE IF NOT EXISTS "scores" ("score" INTEGER NOT NULL);"#
                ),
                .init(
                    unsafeSQL: #"INSERT INTO scores (score) VALUES (:1:);"#,
                    bindings: ["1": 1]
                ),
            ])
            try await db.execute(xs)
        }
    }

    func testBindings() async throws {
        try await runTest { db in
            try await db.execute([
                .init(
                    unsafeSQL:
                        """
                        CREATE TABLE IF NOT EXISTS
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
                        CREATE TABLE IF NOT EXISTS foo ("bar" integer)
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
                            "todos" ("id", "title", "url", "order")
                        VALUES
                            (:id:, :title:, :url:, :order:)
                        """,
                    bindings:
                        newTodo
                ),
                .init(
                    unsafeSQL: """
                        INSERT INTO
                            "todos" ("id", "title", "url", "order")
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
                            "foo" ("bar")
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
        try await runTest { db in
            
            try await db.execute([
                .init(
                    unsafeSQL:
                    """
                    DROP TABLE IF EXISTS products
                    """
                ),
                .init(
                    unsafeSQL:
                    """
                    DROP TABLE IF EXISTS calendars
                    """
                ),
                .init(
                    unsafeSQL:
                    """
                    CREATE TABLE IF NOT EXISTS products(
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
                    CREATE TABLE IF NOT EXISTS calendars(
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
            
            let res = try await db.execute(
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
        }
    }

}