import NIO
import Logging
import Hummingbird
import HummingbirdDatabase

struct HBPostgreSQLDatabaseService: HBDatabaseService {
    
    let poolGroup: HBConnectionPoolGroup<HBPostgreSQLConnectionSource>
    
    init(
        host: String,
        port: Int,
        user: String,
        pass: String,
        database: String,
        maxConnections: Int,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.poolGroup = .init(
            source: .init(
                configuration: .init(
                    host: host,
                    port: port,
                    username: "postgres",
                    password: "nincs",
                    database: "",
                    tls: .disable
                )
            ),
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
