#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A single current or dated inspection listing, without pagination or publication inference.
public struct PublicInspectionListing: Codable, DocumentResponse, Hashable {
  /// The reported snapshot count.
  public let count: Int
  /// Every original source field.
  public let fields: [String: JSONValue]
  /// Records in provider order, retaining duplicates.
  public let results: [PublicInspectionDocument]

  /// Source update time, independent of filing and intended publication dates.
  public var regularFilingsUpdatedAt: String? { fields["regular_filings_updated_at"]?.string }
  /// Source special-filing update time, without synthesized defaults.
  public var specialFilingsUpdatedAt: String? { fields["special_filings_updated_at"]?.string }

  private enum CodingKeys: String, CodingKey {
    case count
    case results
  }

  /// Decodes the listing and retains all original values.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    count = try container.decode(Int.self, forKey: .count)
    results = try container.decode([PublicInspectionDocument].self, forKey: .results)
  }

  /// Encodes the original object without manufacturing update times.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
