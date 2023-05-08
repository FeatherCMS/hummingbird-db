import Foundation
import PostgresNIO

struct PostgreSQLRowEncoder {

    enum KeyEncodingStrategy {
        /// A key encoding strategy that doesn't change key names during encoding.
        case useDefaultKeys
        /// A key encoding strategy that converts camel-case keys to snake-case keys.
        case convertToSnakeCase
        case custom(([CodingKey]) -> CodingKey)
    }

    struct _Options {
        let prefix: String?
        let keyEncodingStrategy: KeyEncodingStrategy
    }

    /// The options set on the top-level decoder.
    var options: _Options {
        _Options(
            prefix: prefix,
            keyEncodingStrategy: keyEncodingStrategy
        )
    }

    private var indexCounter = _IndexCounter()
    var prefix: String? = nil
    var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys

    init() {}

    func encode<E: Encodable>(
        _ encodable: E
    ) throws -> [(String, PostgresData)] {
        var data: PostgresData?
        if let e = encodable as? PostgresEncodable {
            var buffer: ByteBuffer = .init()
            try e.encode(into: &buffer, context: .default)
            let type = type(of: e)
            data = .init(
                type: type.psqlType,
                typeModifier: nil,
                formatCode: type.psqlFormat,
                value: buffer
            )
        }
        let encoder = _Encoder(
            options: options,
            index: indexCounter.index,
            data: data
        )
        try encodable.encode(to: encoder)
        indexCounter.index += 1
        return encoder.bindings
    }
}

private final class _IndexCounter {
    var index: Int = 0
}

private final class _Encoder: Encoder, SingleValueEncodingContainer {

    let options: PostgreSQLRowEncoder._Options
    let index: Int
    let data: PostgresData?

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    var bindings: [(String, PostgresData)]

    init(
        options: PostgreSQLRowEncoder._Options,
        index: Int,
        data: PostgresData?
    ) {
        self.bindings = []
        self.options = options
        self.index = index
        self.data = data
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type)
        -> KeyedEncodingContainer<Key>
    {
        KeyedEncodingContainer(_KeyedEncoder(self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Unkeyed container is not supported.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }

    func encodeNil() throws {
        bindings.append((String(index), .null))
    }

    func encode<T: Encodable>(_ value: T) throws {
        if let originalData = data {
            bindings.append((String(index), originalData))
        }
        else {
            let data = try PostgresDataEncoder().encode(value)
            bindings.append((String(index), data))
        }
    }

    func _convertToSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else {
            return stringKey
        }

        enum Status {
            case uppercase
            case lowercase
            case number
        }

        var status = Status.lowercase
        var snakeCasedString = ""
        var i = stringKey.startIndex
        while i < stringKey.endIndex {
            let nextIndex = stringKey.index(i, offsetBy: 1)

            if stringKey[i].isUppercase {
                switch status {
                case .uppercase:
                    if nextIndex < stringKey.endIndex {
                        if stringKey[nextIndex].isLowercase {
                            snakeCasedString.append("_")
                        }
                    }
                case .lowercase,
                    .number:
                    if i != stringKey.startIndex {
                        snakeCasedString.append("_")
                    }
                }
                status = .uppercase
                snakeCasedString.append(stringKey[i].lowercased())
            }
            else {
                status = .lowercase
                snakeCasedString.append(stringKey[i])
            }

            i = nextIndex
        }
        return snakeCasedString
    }

}

private struct _KeyedEncoder<Key: CodingKey>: KeyedEncodingContainerProtocol {

    var codingPath: [CodingKey] { [] }
    let encoder: _Encoder

    init(_ encoder: _Encoder) {
        self.encoder = encoder
    }

    func column(for key: Key) -> String {
        var encodedKey = key.stringValue
        switch encoder.options.keyEncodingStrategy {
        case .useDefaultKeys:
            break
        case .convertToSnakeCase:
            encodedKey = encoder._convertToSnakeCase(encodedKey)
        case .custom(let customKeyEncodingFunc):
            encodedKey = customKeyEncodingFunc([key]).stringValue
        }

        if let prefix = encoder.options.prefix {
            return prefix + encodedKey
        }
        return encodedKey
    }

    mutating func encodeNil(forKey key: Key) throws {
        encoder.bindings.append((column(for: key), .null))
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let data = try PostgresDataEncoder().encode(value)
        encoder.bindings.append((column(for: key), data))
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        fatalError()
    }

    mutating func nestedUnkeyedContainer(forKey key: Key)
        -> UnkeyedEncodingContainer
    {
        fatalError()
    }

    mutating func superEncoder() -> Encoder {
        encoder
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        encoder
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
}
