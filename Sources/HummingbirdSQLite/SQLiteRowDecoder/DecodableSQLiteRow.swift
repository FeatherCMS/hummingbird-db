protocol DecodableSQLiteRow {
    var allColumns: [String] { get }
    func contains(column: String) -> Bool
    func decodeNil(column: String) throws -> Bool
    func decode<D: Decodable>(column: String, as type: D.Type) throws -> D
}
