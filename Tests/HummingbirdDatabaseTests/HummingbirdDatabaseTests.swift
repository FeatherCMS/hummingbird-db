import Hummingbird
import HummingbirdDatabase
import Logging
import NIO
import XCTest

final class HummingbirdDatabaseTests: XCTestCase {

    func testBindings() async throws {

        let string = "hello :name: Swi :bar: ft"

        let patterns = [
            "name": "hey",
            "bar": "foo",
                //    "lol": "asdf",
        ]

        var bindingQuery = ""
        var isOpened = false
        var currentKey = ""
        var currentIndex = 1
        var currentBindings: [String] = []

        for c in string {
            if c == ":" {
                if isOpened {

                    // SQLite
                    //            newString += "?"
                    // Postgres
                    bindingQuery += "$"
                    bindingQuery += String(currentIndex)

                    currentBindings.append(currentKey)

                    currentKey = ""
                    currentIndex += 1
                }
                isOpened = !isOpened
                continue
            }
            if isOpened {
                currentKey += String(c)
            }
            else {
                bindingQuery += String(c)
            }
        }

        if isOpened || currentIndex - 1 != patterns.count {  // strict mode?
            XCTFail("invalid sql query")
        }
    }
}
