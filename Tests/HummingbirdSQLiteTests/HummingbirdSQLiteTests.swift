import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import XCTest

@testable import HummingbirdSQLite

final class HummingbirdSQLiteTests: XCTestCase {

    func testExample() async throws {
        let app = HBApplication()

        app.services.setUpSQLiteDatabase(
            storage: .memory,
            threadPool: app.threadPool,
            eventLoopGroup: app.eventLoopGroup,
            logger: app.logger
        )

        guard let db = app.db as? HBSQLiteDatabase else {
            return XCTFail()
        }

        struct SchemaDef: Codable {
            let type: String
            let name: String
            let tbl_name: String
            let rootpage: Int
            let sql: String
        }
        struct Version: Codable {
            let version: String
        }

//
//        try await db.execute { connection in
//
//            try await connection.query(
//                """
//                CREATE TABLE groups (
//                    group_id INTEGER PRIMARY KEY,
//                    name TEXT NOT NULL
//                );
//                """
//            )
//            try await connection.query(
//                """
//                CREATE TABLE contacts (
//                    contact_id INTEGER PRIMARY KEY,
//                    first_name TEXT NOT NULL,
//                    last_name TEXT NOT NULL,
//                    email TEXT NOT NULL UNIQUE,
//                    phone TEXT NOT NULL UNIQUE
//                );
//                """
//            )
//            //            let v = try await connection.query("select sqlite_version() as version;").get()
//            let v = try await connection.query(
//                "select * from sqlite_schema WHERE type ='table' AND name NOT LIKE 'sqlite_%';"
//            ).get()
//
//            for i in v {
//                print(i)
//                let ver = try SQLiteRowDecoder().decode(SchemaDef.self, from: i)
//                print(ver)
//            }
//            //            let ver = try v[0].decode(model: Version.self, with: SQLRowDecoder())
//        }

        try app.shutdownApplication()
    }
}
