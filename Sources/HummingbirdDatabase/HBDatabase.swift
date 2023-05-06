public protocol HBDatabase {

    var type: HBDatabaseType { get }

    func execute(_ queries: [String]) async throws
    func executeWithBindings(_ queries: [String]) async throws

    func execute<T: Decodable>(_ query: String, as: T.Type) async throws -> [T]
}
