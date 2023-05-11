import FeatherDatabase
import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import PostgresNIO

struct HBPostgresDatabaseService: HBDatabaseService {

    let poolGroup: HBConnectionPoolGroup<HBPostgresConnectionSource>

    init(
        configuration: PostgresConnection.Configuration,
        maxConnections: Int,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.poolGroup = .init(
            source: .init(configuration: configuration),
            maxConnections: maxConnections,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }

    func make(
        logger: Logger,
        eventLoop: EventLoop
    ) -> FeatherDatabase {
        HBPostgresDatabase(
            service: self,
            logger: logger,
            eventLoop: eventLoop
        )
    }

    func shutdown() throws {
        try poolGroup.close().wait()
    }
}
