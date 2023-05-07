public struct HBDatabaseQuery {
    public let unsafeSQL: String
    public let bindings: [any Encodable]

    public init(unsafeSQL: String, bindings: any Encodable...) {
        self.unsafeSQL = unsafeSQL
        self.bindings = bindings
    }
}

public protocol HBDatabase {

    var type: HBDatabaseType { get }

    func executeRaw(_: [String]) async throws
    func execute(_: [HBDatabaseQuery]) async throws
    func execute(_: HBDatabaseQuery...) async throws

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
}

extension HBDatabase {
    public func execute(_ queries: HBDatabaseQuery...) async throws {
        try await execute(queries)
    }
}
