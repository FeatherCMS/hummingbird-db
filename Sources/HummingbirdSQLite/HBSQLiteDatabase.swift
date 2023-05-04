import HummingbirdDatabase
import NIOCore
import Logging

struct HBSQLiteDatabase: HBDatabase {
    
    let service: HBSQLiteDatabaseService
    let logger: Logger
    let eventLoop: EventLoop

}
