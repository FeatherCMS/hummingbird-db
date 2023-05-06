public protocol HBDatabaseQueryExpression {
    var query: String { get }
}

//public enum HBDatabaseQueryExpression {}

extension String: HBDatabaseQueryExpression {
    public var query: String { self }
}
