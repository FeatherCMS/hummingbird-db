import Foundation
import SQLiteNIO

struct SQLiteDataDecoder {

    init() {}

    func decode<T: Decodable>(
        _ type: T.Type,
        from data: SQLiteData
    ) throws -> T {
        if let type = type as? SQLiteDataConvertible.Type {
            guard let value = type.init(sqliteData: data) else {
                throw DecodingError.typeMismatch(
                    T.self,
                    .init(
                        codingPath: [],
                        debugDescription:
                            "Could not initialize \(T.self) from \(data)."
                    )
                )
            }
            return value as! T
        }
        return try T.init(from: _Decoder(data: data))
    }
}

private struct _DecoderBox: Decodable {

    let decoder: Decoder

    init(from decoder: Decoder) {
        self.decoder = decoder
    }
}

private final class _Decoder: Decoder {

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    let data: SQLiteData

    init(data: SQLiteData) {
        self.data = data
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try jsonDecoder().unkeyedContainer()
    }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        try jsonDecoder().container(keyedBy: Key.self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        _SingleValueDecodingContainer(self)
    }
    
    private func jsonDecoder() throws -> Decoder {
        let data: Data
        switch self.data {
        case .blob(let buffer):
            data = Data(buffer.readableBytesView)
        case .text(let string):
            data = Data(string.utf8)
        default:
            data = .init()
        }
        return try JSONDecoder()
            .decode(_DecoderBox.self, from: data)
            .decoder
    }
}

private struct _SingleValueDecodingContainer: SingleValueDecodingContainer {

    var codingPath: [CodingKey] {
        decoder.codingPath
    }

    let decoder: _Decoder

    init(_ decoder: _Decoder) {
        self.decoder = decoder
    }

    func decodeNil() -> Bool {
        decoder.data == .null
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try SQLiteDataDecoder().decode(T.self, from: decoder.data)
    }
}

