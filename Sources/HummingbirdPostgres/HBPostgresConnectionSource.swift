import Hummingbird
import Logging
import PostgresNIO

extension PostgresConnection: HBAsyncConnection {}

struct HBPostgresConnectionSource: HBAsyncConnectionSource {
    typealias Connection = PostgresConnection

    let configuration: Connection.Configuration

    func makeConnection(
        on eventLoop: EventLoop,
        logger: Logger
    ) async throws -> Connection {
        let connection = try await PostgresConnection.connect(
            on: eventLoop,
            configuration: configuration,
            id: 0,
            logger: logger
        )
        return connection
    }
}
