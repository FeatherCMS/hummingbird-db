import Foundation
import SQLiteNIO

struct SQLiteRowDecoder {

    enum KeyDecodingStrategy {
        case useDefaultKeys
        case convertFromSnakeCase
        case custom(([CodingKey]) -> CodingKey)
    }

    var prefix: String?
    var keyDecodingStrategy: KeyDecodingStrategy

    init(
        prefix: String? = nil,
        keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
    ) {
        self.prefix = prefix
        self.keyDecodingStrategy = keyDecodingStrategy
    }

    func decode<T: Decodable>(
        _ type: T.Type,
        from row: SQLiteRow
    ) throws -> T {
        try T.init(from: _Decoder(row: row, options: options))
    }

    private var options: _Options {
        .init(
            prefix: prefix,
            keyDecodingStrategy: keyDecodingStrategy
        )
    }
}

private struct _Options {
    let prefix: String?
    let keyDecodingStrategy: SQLiteRowDecoder.KeyDecodingStrategy
}

private enum _DecoderError: Error {
    case nesting
    case unkeyedContainer
    case singleValueContainer
}

private struct _Decoder: Decoder {

    let options: _Options
    let row: SQLiteRow
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    init(
        row: SQLiteRow,
        codingPath: [CodingKey] = [],
        options: _Options
    ) {
        self.options = options
        self.row = row
        self.codingPath = codingPath
    }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        .init(
            _KeyedDecodingContainer(
                referencing: self,
                row: row,
                codingPath: codingPath
            )
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw _DecoderError.unkeyedContainer
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw _DecoderError.singleValueContainer
    }
}

private struct _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let decoder: _Decoder
    let row: SQLiteRow
    var codingPath: [CodingKey] = []
    var allKeys: [Key] {
        row.columns.compactMap {
            Key.init(stringValue: $0.name)
        }
    }

    init(
        referencing decoder: _Decoder,
        row: SQLiteRow,
        codingPath: [CodingKey] = []
    ) {
        self.decoder = decoder
        self.row = row
    }

    func column(for key: Key) -> String {
        var decodedKey = key.stringValue
        switch decoder.options.keyDecodingStrategy {
        case .useDefaultKeys:
            break
        case .convertFromSnakeCase:
            decodedKey = _convertFromSnakeCase(decodedKey)
        case .custom(let customKeyDecodingFunc):
            decodedKey = customKeyDecodingFunc([key]).stringValue
        }

        if let prefix = decoder.options.prefix {
            return prefix + decodedKey
        }
        return decodedKey
    }

    func contains(_ key: Key) -> Bool {
        row.column(key.stringValue) != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        row.column(key.stringValue)?.isNull ?? false
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let data = row.column(key.stringValue) else {
            throw DecodingError.keyNotFound(
                key,
                .init(
                    codingPath: [key],
                    debugDescription: "Missing key \(key.stringValue)."
                )
            )
        }
        return try SQLiteDataDecoder().decode(T.self, from: data)
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        throw _DecoderError.nesting
    }

    func nestedUnkeyedContainer(
        forKey key: Key
    ) throws -> UnkeyedDecodingContainer {
        throw _DecoderError.nesting
    }

    func superDecoder() throws -> Decoder {
        _Decoder(
            row: row,
            codingPath: codingPath,
            options: decoder.options
        )
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        throw _DecoderError.nesting
    }

    func _convertFromSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        var words: [Range<String.Index>] = []
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

        while let upperCaseRange = stringKey.rangeOfCharacter(
            from: CharacterSet.uppercaseLetters,
            options: [],
            range: searchRange
        ) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard
                let lowerCaseRange = stringKey.rangeOfCharacter(
                    from: CharacterSet.lowercaseLetters,
                    options: [],
                    range: searchRange
                )
            else {
                wordStart = searchRange.lowerBound
                break
            }
            let nextCharacterAfterCapital = stringKey.index(
                after: upperCaseRange.lowerBound
            )
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                wordStart = upperCaseRange.lowerBound
            }
            else {
                let beforeLowerIndex = stringKey.index(
                    before: lowerCaseRange.lowerBound
                )
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result =
            words
            .map { stringKey[$0].lowercased() }
            .joined(separator: "_")
        return result
    }
}
