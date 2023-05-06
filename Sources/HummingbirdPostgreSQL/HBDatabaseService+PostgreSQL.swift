import Hummingbird
import HummingbirdDatabase
import HummingbirdServices
import Logging
import NIOCore
import PostgresNIO

extension HBApplication.Services {

    public func setUpPostgreSQLDatabase(
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
