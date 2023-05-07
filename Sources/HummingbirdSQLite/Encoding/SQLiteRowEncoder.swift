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
    
    private var singleValueCounter = _SingleValueCounter()
    var prefix: String? = nil
    var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys

    init() {}

    func encode<E: Encodable>(_ encodable: E) throws -> [(String, SQLiteData)] {
        let encoder = _Encoder(
            options: options,
            singleValueIndex: singleValueCounter.index
        )
        try encodable.encode(to: encoder)
        singleValueCounter.index += 1
        return encoder.bindings
    }
}

private final class _SingleValueCounter {
    var index: Int = 0
}

private final class _Encoder: Encoder, SingleValueEncodingContainer {

    let options: SQLiteRowEncoder._Options
    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    var singleValueIndex: Int
    var bindings: [(String, SQLiteData)]

    init(options: SQLiteRowEncoder._Options, singleValueIndex: Int) {
        self.bindings = []
        self.options = options
        self.singleValueIndex = singleValueIndex
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
        bindings.append((String(singleValueIndex), .null))
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        let data = try SQLiteDataEncoder().encode(value)
        bindings.append((String(singleValueIndex), data))
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
        else {
            return encodedKey
        }
    }

    mutating func encodeNil(forKey key: Key) throws {
        encoder.bindings.append((column(for: key), .null))
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        if let value = value as? SQLiteDataConvertible,
            let data = value.sqliteData
        {
            encoder.bindings.append((column(for: key), data))
        }
        else {
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: [key], debugDescription: "Invalid value")
            )
        }
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
