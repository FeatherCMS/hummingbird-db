public protocol HBDatabaseQueryInterface {
    associatedtype B: Encodable
    var unsafeSQL: String { get }
    var bindings: B? { get }
}

public struct HBDatabaseQuery<B: Encodable>: HBDatabaseQueryInterface {
    public let unsafeSQL: String
    public let bindings: B?
    
    public init(unsafeSQL: String, bindings: B? = nil) {
        self.unsafeSQL = unsafeSQL
        self.bindings = bindings
    }
}

public protocol HBDatabase {

    var type: HBDatabaseType { get }

    func executeRaw(_: [String]) async throws
    func execute(_: [any HBDatabaseQueryInterface]) async throws
    func execute(_: any HBDatabaseQueryInterface...) async throws

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
}

public extension HBDatabase {
    func execute(_ queries: any HBDatabaseQueryInterface...) async throws {
        try await execute(queries)
    }
}
