import Hummingbird
import HummingbirdServices
import HummingbirdDatabase
import Logging
import SQLiteNIO

public extension HBApplication.Services {

    func setUpSQLiteDatabase(
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
