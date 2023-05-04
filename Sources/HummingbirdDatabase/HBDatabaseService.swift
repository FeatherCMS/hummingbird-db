import NIOCore
import Logging

public protocol HBDatabaseService {
    
    func make(
        logger: Logger,
        eventLoop: EventLoop
    ) -> HBDatabase
}
