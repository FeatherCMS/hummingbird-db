import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import SQLiteNIO

struct HBSQLiteDatabaseService: HBDatabaseService {

    let poolGroup: HBConnectionPoolGroup<HBSQLiteConnectionSource>

    init(
        path: String,
        maxConnections: Int,
        threadPool: NIOThreadPool,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        self.poolGroup = .init(
            source: .init(
                configuration: .file(path: path),
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
