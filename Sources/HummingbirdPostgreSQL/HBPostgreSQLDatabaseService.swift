import NIO
import Logging
import HummingbirdDatabase

struct HBPostgreSQLDatabaseService: HBDatabaseService {
    
    init(
        host: String,
        port: Int = 5432
    ) {
        // TODO
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
}
