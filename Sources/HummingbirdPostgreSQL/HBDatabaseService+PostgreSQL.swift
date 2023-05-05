import Hummingbird
import HummingbirdServices
import HummingbirdDatabase
import Logging
import NIOCore
import PostgresNIO

public extension HBApplication.Services {

    func setUpPostgreSQLDatabase(
        configuration: PostgresConnection.Configuration,
        maxConnections: Int = 100,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        db = HBPostgreSQLDatabaseService(
            configuration: configuration,
            maxConnections: maxConnections,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }
}
