public protocol FeatherDatabase {

    var type: FeatherDatabaseType { get }

    func execute(_: FeatherDatabaseQuery...) async throws
    func execute(_: [FeatherDatabaseQuery]) async throws

    func execute<T: Decodable>(
        _ query: FeatherDatabaseQuery,
        rowType: T.Type
    ) async throws -> [T]
}

extension FeatherDatabase {
    public func execute(_ queries: FeatherDatabaseQuery...) async throws {
        try await execute(queries)
    }
}
