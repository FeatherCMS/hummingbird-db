import PostgresNIO

struct PostgreSQLEncoder {
    var prefix: String? = nil
    var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    var nilEncodingStrategy: NilEncodingStrategy = .default

    init() {}

    func encode<E: Encodable>(
        _ encodable: E
    ) throws -> [(String, PostgresData)] {
        let encoder = _Encoder(options: options)
        try encodable.encode(to: encoder)
        return encoder.row
    }

    enum NilEncodingStrategy {
        /// Skips nilable columns with nil values during encoding.
        case `default`
        /// Encodes nilable columns with nil values as nil. Useful when using `SQLInsertBuilder` to insert `Codable` models without Fluent
        case asNil
    }

    enum KeyEncodingStrategy {
        /// A key encoding strategy that doesn't change key names during encoding.
        case useDefaultKeys
        /// A key encoding strategy that converts camel-case keys to snake-case keys.
        case convertToSnakeCase
        case custom(([CodingKey]) -> CodingKey)
    }

    fileprivate struct _Options {
        let prefix: String?
        let keyEncodingStrategy: KeyEncodingStrategy
        let nilEncodingStrategy: NilEncodingStrategy
    }

    /// The options set on the top-level decoder.
    fileprivate var options: _Options {
        _Options(
            prefix: prefix,
            keyEncodingStrategy: keyEncodingStrategy,
            nilEncodingStrategy: nilEncodingStrategy
        )
    }
}

private final class _Encoder: Encoder {
    fileprivate let options: PostgreSQLEncoder._Options

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    var row: [(String, PostgresData)]

    init(options: PostgreSQLEncoder._Options) {
        self.row = []
        self.options = options
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type)
        -> KeyedEncodingContainer<Key>
    {
        switch options.nilEncodingStrategy {
        case .asNil:
            return KeyedEncodingContainer(_NilColumnKeyedEncoder(self))
        case .default:
            return KeyedEncodingContainer(_KeyedEncoder(self))
        }
    }

    struct _NilColumnKeyedEncoder<Key: CodingKey>:
        KeyedEncodingContainerProtocol
    {
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
                encodedKey = _convertToSnakeCase(encodedKey)
            case .custom(let customKeyEncodingFunc):
                encodedKey = customKeyEncodingFunc([key]).stringValue
            }

            if let prefix = encoder.options.prefix {
                return prefix + encodedKey
            }
            return encodedKey
        }

        mutating func encodeNil(forKey key: Key) throws {
            encoder.row.append((column(for: key), .null))
        }

        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            let data = try PostgresDataEncoder().encode(value)
            encoder.row.append((column(for: key), data))
        }

        mutating func _encodeIfPresent<T: Encodable>(
            _ value: T?,
            forKey key: Key
        ) throws {
            if let value = value {
                try encode(value, forKey: key)
            }
            else {
                try encodeNil(forKey: key)
            }
        }

        mutating func encodeIfPresent<T: Encodable>(
            _ value: T?,
            forKey key: Key
        ) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws
        { try _encodeIfPresent(value, forKey: key) }

        mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws
        { try _encodeIfPresent(value, forKey: key) }

        mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws
        { try _encodeIfPresent(value, forKey: key) }

        mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws
        { try _encodeIfPresent(value, forKey: key) }

        mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
        }

        mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws
        { try _encodeIfPresent(value, forKey: key) }

        mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
            try _encodeIfPresent(value, forKey: key)
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
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }

    struct _KeyedEncoder<Key: CodingKey>: KeyedEncodingContainerProtocol {

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
                encodedKey = _convertToSnakeCase(encodedKey)
            case .custom(let customKeyEncodingFunc):
                encodedKey = customKeyEncodingFunc([key]).stringValue
            }

            if let prefix = encoder.options.prefix {
                return prefix + encodedKey
            }
            return encodedKey
        }

        mutating func encodeNil(forKey key: Key) throws {
            encoder.row.append((column(for: key), .null))
        }

        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            let data = try PostgresDataEncoder().encode(value)
            encoder.row.append((column(for: key), data))
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
}

extension _Encoder {

    fileprivate static func _convertToSnakeCase(_ stringKey: String) -> String {
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
