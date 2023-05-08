import Foundation
import SQLiteNIO

struct SQLiteRowEncoder {

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

    func encode<E: Encodable>(_ encodable: E) throws -> [(String, SQLiteData)] {
        let encoder = _Encoder(
            options: options,
            index: indexCounter.index
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

    var bindings: [(String, SQLiteData)]

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    let options: SQLiteRowEncoder._Options
    let index: Int

    init(options: SQLiteRowEncoder._Options, index: Int) {
        self.bindings = []
        self.options = options
        self.index = index
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type)
        -> KeyedEncodingContainer<Key>
    {
        KeyedEncodingContainer(_KeyedEncoder(self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Unkeyed containers are not supported.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        self
    }

    func encodeNil() throws {
        bindings.append((String(index), .null))
    }

    func encode<T: Encodable>(_ value: T) throws {
        let data = try SQLiteDataEncoder().encode(value)
        bindings.append((String(index), data))
    }

    func _convertToSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

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

    func resolvedKey(for key: Key) -> String {
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
        encoder.bindings.append((resolvedKey(for: key), .null))
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        guard
            let value = value as? SQLiteDataConvertible,
            let data = value.sqliteData
        else {
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: [key], debugDescription: "Invalid value")
            )
        }
        encoder.bindings.append((resolvedKey(for: key), data))
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        fatalError("Nested keyed container is not supported.")
    }

    mutating func nestedUnkeyedContainer(forKey key: Key)
        -> UnkeyedEncodingContainer
    {
        fatalError("Nested unkeyed container is not supported.")
    }

    mutating func superEncoder() -> Encoder {
        encoder
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        encoder
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Unkeyed container is not supported.")
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Single value container is not supported.")
    }
}
