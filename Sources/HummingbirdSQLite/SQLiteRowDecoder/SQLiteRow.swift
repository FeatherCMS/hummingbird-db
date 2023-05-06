import Foundation
import SQLiteNIO

struct MissingColumn: Error {
    let name: String
}

extension SQLiteRow {

    var allColumns: [String] {
        columns.map { $0.name }
    }

    func decodeNil(column name: String) throws -> Bool {
        guard let data = column(name) else {
            throw MissingColumn(name: name)
        }
        return data == .null
    }

    func contains(column name: String) -> Bool {
        column(name) != nil
    }

    func decode<D: Decodable>(column name: String, as type: D.Type) throws -> D
    {
        guard let data = column(name) else {
            throw MissingColumn(name: name)
        }
        return try SQLiteDataDecoder().decode(D.self, from: data)
    }
}
