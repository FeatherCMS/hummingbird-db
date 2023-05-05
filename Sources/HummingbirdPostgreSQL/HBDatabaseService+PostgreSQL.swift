import Hummingbird
import HummingbirdServices
import HummingbirdDatabase
import Logging
import NIOCore

public extension HBApplication.Services {

    func setUpPostgreSQLDatabase(
        host: String = "localhost",
        port: Int = 5432,
        user: String = "postgres",
        pass: String = "nincs",
        database: String = "postgres",
        maxConnections: Int = System.coreCount,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        db = HBPostgreSQLDatabaseService(
            host: host,
            port: port,
            user: user,
            pass: pass,
            database: database,
            maxConnections: maxConnections,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }
}
