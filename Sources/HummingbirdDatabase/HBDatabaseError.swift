public enum HBDatabaseError: Error {
    case unknown
    case binding
    case query(String)
}
