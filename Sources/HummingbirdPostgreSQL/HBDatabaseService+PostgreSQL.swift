import Hummingbird
import HummingbirdServices
import HummingbirdDatabase
import Logging


public extension HBApplication.Services {

    func setUpPostgreSQLDatabase(
        host: String,
        port: Int = 5432
    ) {
        db = HBPostgreSQLDatabaseService(
            host: host,
            port: port
        )
    }
}
