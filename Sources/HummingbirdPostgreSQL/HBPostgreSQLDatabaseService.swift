import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import PostgresNIO

struct HBPostgreSQLDatabaseService: HBDatabaseService {

    let poolGroup: HBConnectionPoolGroup<HBPostgreSQLConnectionSource>

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
    ) -> HBDatabase {
        HBPostgreSQLDatabase(
            service: self,
            logger: logger,
            eventLoop: eventLoop
        )
    }

    func shutdown() throws {
        try poolGroup.close().wait()
    }
}
