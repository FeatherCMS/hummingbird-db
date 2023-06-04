import FeatherDatabase
import FeatherSQLiteDatabase
import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
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
    ) -> FeatherDatabase {
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
