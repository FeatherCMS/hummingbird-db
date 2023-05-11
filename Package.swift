// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "hummingbird-db",
    platforms: [
       .macOS(.v12),
    ],
    products: [
        .library(name: "HummingbirdDatabase", targets: ["HummingbirdDatabase"]),
        .library(name: "HummingbirdPostgresDatabase", targets: ["HummingbirdPostgresDatabase"]),
        .library(name: "HummingbirdSQLiteDatabase", targets: ["HummingbirdSQLiteDatabase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "1.5.0"),
        .package(url: "https://github.com/feathercms/hummingbird-services", branch: "main"),
        .package(url: "https://github.com/feathercms/feather-database", branch: "main"),
    ],
    targets: [
        .target(name: "HummingbirdDatabase", dependencies: [
            .product(name: "Hummingbird", package: "hummingbird"),
            .product(name: "HummingbirdServices", package: "hummingbird-services"),
            .product(name: "FeatherDatabase", package: "feather-database"),
        ]),
        .target(name: "HummingbirdPostgresDatabase", dependencies: [
            .target(name: "HummingbirdDatabase"),
            .product(name: "FeatherPostgresDatabase", package: "feather-database"),
        ]),
        .target(name: "HummingbirdSQLiteDatabase", dependencies: [
            .target(name: "HummingbirdDatabase"),
            .product(name: "FeatherSQLiteDatabase", package: "feather-database"),
        ]),
        .testTarget(name: "HummingbirdPostgresDatabaseTests", dependencies: [
            .target(name: "HummingbirdPostgresDatabase"),
        ]),
        .testTarget(name: "HummingbirdSQLiteDatabaseTests", dependencies: [
            .target(name: "HummingbirdSQLiteDatabase"),
        ]),
    ]
)
