import FeatherDatabase
import Logging
import NIOCore

public protocol HBDatabaseService {

    func make(
        logger: Logger,
        eventLoop: EventLoop
    ) -> FeatherDatabase

    func shutdown() throws
}
