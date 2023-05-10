///
/// Thanks to [Joannis Orlandos](https://github.com/joannis) for the Component & interpolation implementation.
///
enum Component: CustomStringConvertible {
    case literal(String)
    case variable(any Encodable)

    var description: String {
        switch self {
        case .literal(let literal):
            return literal
        case .variable:
            return "?"
        }
    }
}

private extension [Component] {
    var unsafeSQL: String {
        reduce(into: "") { $0 += $1.description }
    }
    
    var bindings: [any Encodable] {
        compactMap {
            if case let .variable(encodable) = $0 {
                return encodable
            }
            return nil
        }
    }
}

public struct FeatherDatabaseQuery {
    
    public let unsafeSQL: String
    public let bindings: [any Encodable]

    public init(unsafeSQL: String, bindings: any Encodable...) {
        self.init(unsafeSQL: unsafeSQL, bindings: bindings)
    }

    public init(unsafeSQL: String, bindings: [any Encodable]) {
        self.unsafeSQL = unsafeSQL
        self.bindings = bindings
    }
}

extension FeatherDatabaseQuery: ExpressibleByStringInterpolation {

    public struct Interpolation: StringInterpolationProtocol {
        var components = [Component]()

        public init(literalCapacity: Int, interpolationCount: Int) {
            components.reserveCapacity(literalCapacity + interpolationCount)
        }

        public mutating func appendLiteral(_ literal: String) {
            components.append(.literal(literal))
        }

        public mutating func appendInterpolation<E: Encodable>(_ value: E) {
            components.append(.variable(value))
        }
    }

    public init(stringInterpolation: Interpolation) {
        self.init(
            unsafeSQL: stringInterpolation.components.unsafeSQL,
            bindings: stringInterpolation.components.bindings
        )
    }

    public init(stringLiteral value: String) {
        let components: [Component] = [.literal(value)]
        self.init(
            unsafeSQL: components.unsafeSQL,
            bindings: components.bindings
        )
    }
}
