import Hummingbird
import HummingbirdServices
import HummingbirdDatabaseService
import Logging
import SQLiteNIO

extension HBApplication.Services {

    public func setUpSQLiteDatabase(
        path: String,
        maxConnections: Int = 10,
        threadPool: NIOThreadPool,
        eventLoopGroup: EventLoopGroup,
        logger: Logger
    ) {
        db = HBSQLiteDatabaseService(
            path: path,
            maxConnections: maxConnections,
            threadPool: threadPool,
            eventLoopGroup: eventLoopGroup,
            logger: logger
        )
    }
}
