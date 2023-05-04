import NIO
import Logging
import HummingbirdDatabase

struct HBSQLiteDatabaseService: HBDatabaseService {
    
    init(
        path: String
    ) {
        // TODO
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
}
