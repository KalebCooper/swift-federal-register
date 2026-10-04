#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Keyed provider facet buckets; object order does not imply ranking.
/// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
public struct DocumentFacetCounts: Codable, DocumentResponse, Hashable, Sendable {
  /// Every source member, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// All buckets, or nil if any bucket has an incompatible shape. An empty object stays empty.
  public var buckets: [String: DocumentFacetBucket]? {
    var result: [String: DocumentFacetBucket] = [:]
    for (key, value) in fields {
      guard let object = value.object else { return nil }
      result[key] = DocumentFacetBucket(fields: object)
    }
    return result
  }

  init(fields: [String: JSONValue]) { self.fields = fields }

  /// Decodes the complete source object.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
  }

  /// Encodes the complete source object without normalizing projected values.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
