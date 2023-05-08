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
