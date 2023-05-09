import Hummingbird
import FeatherDatabase
import HummingbirdServices
import Logging
import NIOCore
import PostgresNIO

extension HBApplication.Services {

    public func setUpPostgresDatabase(
        configuration: PostgresConnection.Configuration,
        maxConnections: Int = 100,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        db = HBPostgresDatabaseService(
            configuration: configuration,
            maxConnections: maxConnections,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }
}
