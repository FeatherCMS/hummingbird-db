import Foundation
import PostgresNIO

struct PostgresDataDecoder {

    enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedDataType(PostgresDataType, expected: String)
        case nestingNotSupported

        var description: String {
            switch self {
            case .unexpectedDataType(let type, let expected):
                return "Unexpected data type: \(type). Expected \(expected)."
            case .nestingNotSupported:
                return "Decoding nested containers is not supported."
            }
        }
    }

    let json: PostgresJSONDecoder

    init(json: PostgresJSONDecoder = _defaultJSONDecoder) {
        self.json = json
    }

    func decode<T: Decodable>(
        _ type: T.Type,
        from data: PostgresData
    ) throws -> T {
        if let convertible = T.self as? any PostgresDecodable.Type {
            var buffer: ByteBuffer? =
                data.bytes == nil ? nil : ByteBuffer(bytes: data.bytes!)
            let value = try convertible._decodeRaw(
                from: &buffer,
                type: data.type,
                format: data.formatCode,
                context: .default
            )
            return value as! T
        }
        do {
            return try T.init(
                from: _Decoder(decoder: self, data: data)
            )
        }
        catch DecodingError.dataCorrupted {
            guard let jsonData = data.jsonb ?? data.json else {
                throw Error.unexpectedDataType(
                    data.type,
                    expected: "jsonb/json"
                )
            }
            return try json.decode(T.self, from: jsonData)
        }
    }
}

final class _Decoder: Decoder, SingleValueDecodingContainer {
    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    let dataDecoder: PostgresDataDecoder
    let data: PostgresData

    init(decoder: PostgresDataDecoder, data: PostgresData) {
        self.dataDecoder = decoder
        self.data = data
    }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        throw DecodingError.dataCorruptedError(
            in: self,
            debugDescription: "Dictionary containers must be JSON-encoded"
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let array = data.array else {
            throw DecodingError.dataCorruptedError(
                in: self,
                debugDescription:
                    "Non-natively typed arrays must be JSON-encoded"
            )
        }
        return _UnkeyedDecodingContainer(data: array, dataDecoder: dataDecoder)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }

    func decodeNil() -> Bool {
        data.value == nil
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try dataDecoder.decode(T.self, from: data)
    }
}

struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let data: [PostgresData]
    let dataDecoder: PostgresDataDecoder
    var codingPath: [CodingKey] { [] }
    var count: Int? { data.count }
    var isAtEnd: Bool { currentIndex >= data.count }
    var currentIndex: Int = 0

    mutating func decodeNil() throws -> Bool {
        if data[currentIndex].value == nil {
            currentIndex += 1
            return true
        }
        return false
    }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let result = try dataDecoder.decode(
            T.self,
            from: data[currentIndex]
        )
        currentIndex += 1
        return result
    }

    mutating func nestedContainer<NewKey: CodingKey>(
        keyedBy _: NewKey.Type
    ) throws -> KeyedDecodingContainer<NewKey> {
        throw DecodingError.dataCorruptedError(
            in: self,
            debugDescription: "Data nesting is not supported"
        )
    }

    mutating func nestedUnkeyedContainer() throws
        -> UnkeyedDecodingContainer
    {
        throw DecodingError.dataCorruptedError(
            in: self,
            debugDescription: "Data nesting is not supported"
        )
    }

    mutating func superDecoder() throws -> Decoder {
        throw DecodingError.dataCorruptedError(
            in: self,
            debugDescription: "Data nesting is not supported"
        )
    }
}
