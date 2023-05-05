import NIO
import Logging
import Hummingbird
import HummingbirdDatabase
import SQLiteNIO

struct HBSQLiteDatabaseService: HBDatabaseService {
    
    let poolGroup: HBConnectionPoolGroup<HBSQLiteConnectionSource>
    
    init(
        storage: SQLiteConnection.Storage,
        maxConnections: Int,
        threadPool: NIOThreadPool,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.poolGroup = .init(
            source: .init(
                configuration: storage,
                threadPool: threadPool
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
        HBSQLiteDatabase(
            service: self,
            logger: logger,
            eventLoop: eventLoop
        )
    }

    func shutdown() throws {
        try poolGroup.close().wait()
    }
}
