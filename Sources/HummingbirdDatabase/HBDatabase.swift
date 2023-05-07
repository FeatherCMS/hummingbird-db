public protocol HBDatabase {

    var type: HBDatabaseType { get }

    func execute(_: HBDatabaseQuery...) async throws
    func execute(_: [HBDatabaseQuery]) async throws

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
}

extension HBDatabase {
    public func execute(_ queries: HBDatabaseQuery...) async throws {
        try await execute(queries)
    }
}
