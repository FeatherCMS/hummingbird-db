import Hummingbird
import HummingbirdServices
import HummingbirdDatabase
import Logging


public extension HBApplication.Services {

    func setUpSQLiteDatabase(
        path: String
    ) {
        db = HBSQLiteDatabaseService(path: path)
    }
}
