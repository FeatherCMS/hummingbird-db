public protocol HBDatabase {

    func typedQueryBuilder(_ block: ((HBDatabaseType) -> String)) -> String
}
