import HummingbirdDatabase
import NIOCore
import Logging

struct HBPostgreSQLDatabase: HBDatabase {
    
    let service: HBPostgreSQLDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

}
