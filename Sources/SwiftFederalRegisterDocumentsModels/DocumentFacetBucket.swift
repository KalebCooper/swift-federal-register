#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One facet bucket, without assumptions about overlapping buckets or coverage.
/// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
public struct DocumentFacetBucket: Codable, Hashable, Sendable {
  /// Every source member, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// The reported integral count, or nil for absent, null, or incompatible values.
  public var count: Int? { fields["count"]?.int }
  /// The source display name, unchanged.
  public var name: String? { fields["name"]?.string }

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
