import Foundation
import SQLiteNIO

extension UUID: SQLiteDataConvertible {

    public init?(sqliteData: SQLiteData) {
        guard let text = sqliteData.string else {
            return nil
        }
        self.init(uuidString: text)
    }

    public var sqliteData: SQLiteData? {
        .text(uuidString)
    }
}
