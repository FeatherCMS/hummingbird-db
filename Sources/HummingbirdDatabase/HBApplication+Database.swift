import Hummingbird
import HummingbirdServices
import Logging

public extension HBApplication.Services {

    var db: HBDatabaseService {
        get {
            get(\.services.db, "Database service is not configured")
        }
        nonmutating set {
            set(\.services.db, newValue)
        }
    }
}

public extension HBApplication {

    var db: HBDatabase {
        services.db.make(
            logger: logger,
            eventLoop: eventLoopGroup.next()
        )
    }
}

public extension HBRequest {

    var db: HBDatabase {
        application.services.db.make(
            logger: logger,
            eventLoop: eventLoop
        )
    }
}
