import Hummingbird
import Logging
import SQLiteNIO

extension SQLiteConnection: HBAsyncConnection {

    public func close() async throws {
        let future: EventLoopFuture<Void> = self.close()
        try await future.get()
    }
}

struct HBSQLiteConnectionSource: HBAsyncConnectionSource {
    typealias Connection = SQLiteConnection

    let configuration: Connection.Storage
    let threadPool: NIOThreadPool

    func makeConnection(
        on eventLoop: EventLoop,
        logger: Logger
    ) async throws -> Connection {
        let connection = try await SQLiteConnection.open(
            storage: configuration,
            threadPool: threadPool,
            logger: logger,
            on: eventLoop
        )
        .get()
        return connection
    }
}
