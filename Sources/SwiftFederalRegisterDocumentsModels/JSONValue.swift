#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A JSON value retaining unknown fields and explicit nulls.
///
/// Use a document's `fields` dictionary to inspect provider attributes without losing new codes.
public enum JSONValue: Codable, Hashable, Sendable {
  /// An ordered JSON array.
  case array([JSONValue])
  /// A Boolean value.
  case bool(Bool)
  /// An explicit JSON null, distinct from an absent dictionary key.
  case null
  /// A decimal JSON number; original number spelling remains in response bytes.
  case number(Decimal)
  /// A JSON object with its original field names.
  case object([String: JSONValue])
  /// A string with no date or identifier normalization.
  case string(String)

  /// The string value, or nil for another JSON kind.
  public var string: String? {
    if case .string(let value) = self { return value }
    return nil
  }

  /// Decodes one JSON value, recursively retaining objects and arrays.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    // Each failed attempt costs a thrown DecodingError, so the most frequent Federal Register
    // kinds go first: strings, then objects and arrays. Bool stays ahead of Decimal, and neither
    // kind decodes from the other, so a number never becomes a Bool.
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([String: JSONValue].self) {
      self = .object(value)
    } else if let value = try? container.decode([JSONValue].self) {
      self = .array(value)
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else {
      self = .number(try container.decode(Decimal.self))
    }
  }

  /// Encodes the semantic value; use receipt bytes for byte-exact replay.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .array(let value): try container.encode(value)
    case .bool(let value): try container.encode(value)
    case .null: try container.encodeNil()
    case .number(let value): try container.encode(value)
    case .object(let value): try container.encode(value)
    case .string(let value): try container.encode(value)
    }
  }
}
