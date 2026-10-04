#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Source groups of suggested searches; object order does not define section ranking.
/// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
public struct SuggestedSearchCatalog: Codable, DocumentResponse, Hashable, Sendable {
  /// Every source member, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// Grouped searches in original array order; nil if any group or element has an incompatible shape.
  public var searchesBySection: [String: [SuggestedSearch]]? {
    var result: [String: [SuggestedSearch]] = [:]
    for (key, value) in fields {
      guard let objects = value.objectArray else { return nil }
      result[key] = objects.map(SuggestedSearch.init(fields:))
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
