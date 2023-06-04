import Hummingbird
import HummingbirdDatabase
import HummingbirdServices
import Logging
import SQLiteNIO

extension HBApplication.Services {

    public func setUpSQLiteDatabase(
        storage: SQLiteConnection.Storage,
        maxConnections: Int = 10,
        threadPool: NIOThreadPool,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        db = HBSQLiteDatabaseService(
            storage: storage,
            maxConnections: maxConnections,
            threadPool: threadPool,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }
}
