// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "hummingbird-db",
    platforms: [
       .macOS(.v12),
    ],
    products: [
        .library(name: "FeatherDatabase", targets: ["FeatherDatabase"]),
        .library(name: "FeatherPostgresDatabase", targets: ["FeatherPostgresDatabase"]),
        .library(name: "FeatherSQLiteDatabase", targets: ["FeatherSQLiteDatabase"]),

        .library(name: "HummingbirdDatabase", targets: ["HummingbirdDatabase"]),
        .library(name: "HummingbirdPostgres", targets: ["HummingbirdPostgres"]),
        .library(name: "HummingbirdSQLite", targets: ["HummingbirdSQLite"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "1.5.0"),
        .package(url: "https://github.com/feathercms/hummingbird-services", branch: "main"),
        .package(url: "https://github.com/vapor/postgres-nio", from: "1.14.0"),
        .package(url: "https://github.com/vapor/sqlite-nio", from: "1.5.0"),
    ],
    targets: [
        .target(name: "FeatherDatabase", dependencies: [
        ]),
        .target(name: "FeatherPostgresDatabase", dependencies: [
            .target(name: "FeatherDatabase"),
            .product(name: "PostgresNIO", package: "postgres-nio"),
        ]),
        .target(name: "FeatherSQLiteDatabase", dependencies: [
            .target(name: "FeatherDatabase"),
            .product(name: "SQLiteNIO", package: "sqlite-nio"),
        ]),
        
        .target(name: "HummingbirdDatabase", dependencies: [
            .product(name: "Hummingbird", package: "hummingbird"),
            .product(name: "HummingbirdServices", package: "hummingbird-services"),
            .target(name: "FeatherDatabase"),
        ]),
        .target(name: "HummingbirdPostgres", dependencies: [
            .target(name: "HummingbirdDatabase"),
            .target(name: "FeatherPostgresDatabase"),
        ]),
        .target(name: "HummingbirdSQLite", dependencies: [
            .target(name: "HummingbirdDatabase"),
            .target(name: "FeatherSQLiteDatabase"),
        ]),
        .testTarget(name: "HummingbirdDatabaseTests", dependencies: [
            .target(name: "HummingbirdDatabase"),
        ]),
        .testTarget(name: "HummingbirdPostgresTests", dependencies: [
            .target(name: "HummingbirdPostgres"),
        ]),
        .testTarget(name: "HummingbirdSQLiteTests", dependencies: [
            .target(name: "HummingbirdSQLite"),
        ]),
        
        .testTarget(name: "FeatherDatabaseTests", dependencies: [
            .target(name: "FeatherDatabase"),
        ]),
        .testTarget(name: "FeatherPostgresDatabaseTests", dependencies: [
            .target(name: "FeatherPostgresDatabase"),
        ]),
        .testTarget(name: "FeatherSQLiteDatabaseTests", dependencies: [
            .target(name: "FeatherSQLiteDatabase"),
        ]),
    ]
)
