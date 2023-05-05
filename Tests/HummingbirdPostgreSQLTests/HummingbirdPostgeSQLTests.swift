import XCTest
import NIO
import Hummingbird
import HummingbirdDatabase
import HummingbirdPostgreSQL
import Logging

final class HummingbirdPostgreSQLTests: XCTestCase {
    
    func testExample() async throws {
        let env = ProcessInfo.processInfo.environment
        let app = HBApplication()

        var port = 5432
        if
            let rawPort = env["PG_PORT"],
            let customPort = Int(rawPort)
        {
            port = customPort
        }

        // TODO: force unwrap for real tests
        app.services.setUpPostgreSQLDatabase(
            configuration: .init(
                host: env["PG_HOST"] ?? "localhost",
                port: port,
                username: env["PG_USER"] ?? "postgres",
                password: env["PG_PASS"] ?? "",
                database: env["PG_DATABASE"] ?? "postgres",
                tls: .disable
            ),
            eventLoopGroup: app.eventLoopGroup,
            logger: app.logger
        )

        try app.shutdownApplication()
    }
}
