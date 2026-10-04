#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Source partial errors from a successful batch response; missing records are not retried.
public struct BatchLookupErrors: Codable, Hashable, Sendable {
  /// All error members, including unknown keys and explicit nulls.
  public let fields: [String: JSONValue]

  /// Missing identifiers in source order; nil for absent, null, or incompatible values.
  public var notFound: [String]? { fields["not_found"]?.stringArray }

  init(fields: [String: JSONValue]) { self.fields = fields }

  /// Decodes the untouched error object.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
  }

  /// Encodes the untouched error object.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
