import Hummingbird
import HummingbirdDatabase
import HummingbirdSQLiteDatabase
import Logging
import NIO
import XCTest

final class HummingbirdSQLiteTests: XCTestCase {

    private func runTest(
        _ block: (HBDatabase) async throws -> Void
    ) async throws {
        let path = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
            .absoluteString
        
        let app = HBApplication()

        var logger = Logger(label: "sqlite-logger")
        logger.logLevel = .info

        app.services.setUpSQLiteDatabase(
            path: path,
            threadPool: app.threadPool,
            eventLoopGroup: app.eventLoopGroup,
            logger: logger
        )
        
        try await block(app.db)
        try app.shutdownApplication()
    }

    func testExample() async throws {
        try await runTest { db in
            try await db.execute([
                .init(
                    unsafeSQL:
                        #"CREATE TABLE "scores" ("score" INTEGER NOT NULL);"#,
                    bindings: ["foo": 1, "bar": 2]
                ),
                .init(
                    unsafeSQL: #"INSERT INTO scores (score) VALUES (:1:);"#,
                    bindings: ["1": 1]
                ),
            ])
        }
    }
}
