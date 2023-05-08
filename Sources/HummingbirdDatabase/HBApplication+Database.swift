import Hummingbird
import HummingbirdServices
import Logging

extension HBApplication.Services {

    public var db: HBDatabaseService {
        get {
            get(\.services.db, "Database service is not configured")
        }
        nonmutating set {
            set(\.services.db, newValue) { service in
                try service.shutdown()
            }
        }
    }
}

extension HBApplication {

    public var db: HBDatabase {
        services.db.make(
            logger: logger,
            eventLoop: eventLoopGroup.next()
        )
    }
}

extension HBRequest {

    public var db: HBDatabase {
        application.services.db.make(
            logger: logger,
            eventLoop: eventLoop
        )
    }
}
