public struct HBDatabaseQuery {
    public let unsafeSQL: String
    public let bindings: [any Encodable]

    public init(unsafeSQL: String, bindings: any Encodable...) {
        self.unsafeSQL = unsafeSQL
        self.bindings = bindings
    }

    public init(unsafeSQL: String, bindings: [any Encodable]) {
        self.unsafeSQL = unsafeSQL
        self.bindings = bindings
    }
}

extension HBDatabaseQuery {

    public static func insert(
        into table: String,
        keys: [String],
        bindings: any Encodable...
    ) -> HBDatabaseQuery {
        let t = "`\(table)`"
        let k = keys.map { "`\($0)`" }.joined(separator: ",")
        let b = (0..<keys.count).map { ":\($0):" }.joined(separator: ",")
        let sql = "INSERT INTO \(t) (\(k)) VALUES (\(b))"
        return .init(unsafeSQL: sql, bindings: bindings)
    }
}
