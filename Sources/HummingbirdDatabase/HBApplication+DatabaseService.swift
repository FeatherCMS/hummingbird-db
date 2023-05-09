import Hummingbird
import HummingbirdServices
import FeatherDatabase
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

    public var db: FeatherDatabase {
        services.db.make(
            logger: logger,
            eventLoop: eventLoopGroup.next()
        )
    }
}

extension HBRequest {

    public var db: FeatherDatabase {
        application.services.db.make(
            logger: logger,
            eventLoop: eventLoop
        )
    }
}
