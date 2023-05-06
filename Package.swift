// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "hummingbird-db",
    platforms: [
       .macOS(.v12),
    ],
    products: [
        .library(name: "HummingbirdDatabase", targets: ["HummingbirdDatabase"]),
        .library(name: "HummingbirdPostgreSQL", targets: ["HummingbirdPostgreSQL"]),
        .library(name: "HummingbirdSQLite", targets: ["HummingbirdSQLite"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "1.5.0"),
        .package(url: "https://github.com/feathercms/hummingbird-services", branch: "main"),
        .package(url: "https://github.com/vapor/postgres-nio", from: "1.14.0"),
        .package(url: "https://github.com/vapor/sqlite-nio", from: "1.5.0"),
    ],
    targets: [
        .target(name: "HummingbirdDatabase", dependencies: [
            .product(name: "Hummingbird", package: "hummingbird"),
            .product(name: "HummingbirdServices", package: "hummingbird-services"),
        ]),
        .target(name: "HummingbirdPostgreSQL", dependencies: [
            .target(name: "HummingbirdDatabase"),
            .product(name: "PostgresNIO", package: "postgres-nio"),
        ]),
        .target(name: "HummingbirdSQLite", dependencies: [
            .target(name: "HummingbirdDatabase"),
            .product(name: "SQLiteNIO", package: "sqlite-nio"),
        ]),
        .testTarget(name: "HummingbirdDatabaseTests", dependencies: [
            .target(name: "HummingbirdDatabase"),
        ]),
        .testTarget(name: "HummingbirdPostgreSQLTests", dependencies: [
            .target(name: "HummingbirdPostgreSQL"),
        ]),
        .testTarget(name: "HummingbirdSQLiteTests", dependencies: [
            .target(name: "HummingbirdSQLite"),
        ]),
    ]
)
