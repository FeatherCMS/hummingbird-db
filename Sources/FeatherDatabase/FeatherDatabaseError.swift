public enum FeatherDatabaseError: Error {
    case unknown
    case binding
    case query(String)
}
