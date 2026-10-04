#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One inspection search response, preserving counts and its next link independently.
///
/// `totalPages` can be capped even while `nextPageURL` continues. It is never a traversal limit.
/// A zero-match response carries only `description` and `count`; it decodes as an empty page with
/// nil `totalPages` and nil `nextPageURL`.
public struct PublicInspectionPage: Codable, DocumentResponse, Hashable {
  /// The reported number of matching documents, not a stable snapshot guarantee.
  public let count: Int
  /// Every original page field, including unknown metadata and explicit nulls.
  public let fields: [String: JSONValue]
  /// The next link as published; nil ends traversal, while an empty link is invalid.
  public let nextPageURL: String?
  /// Documents in provider order, including duplicates.
  public let results: [PublicInspectionDocument]
  /// The reported page total, or nil when the provider omits it, as it does for zero matches.
  ///
  /// Recorded captures report 50 at `per_page=2` for 10000 matches, so this is a capped figure and
  /// never a traversal limit. The provider does not promise that pages beyond its depth cap exist.
  public let totalPages: Int?

  private enum CodingKeys: String, CodingKey {
    case count
    case nextPageURL = "next_page_url"
    case results
    case totalPages = "total_pages"
  }

  /// Decodes a page and retains its complete original JSON object.
  ///
  /// An absent `results` key decodes as an empty page only when `count` is 0. A null `results`,
  /// or an absent one beside a nonzero count, is a decoding error.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    count = try container.decode(Int.self, forKey: .count)
    nextPageURL = try container.decodeIfPresent(String.self, forKey: .nextPageURL)
    if count == 0, !container.contains(.results) {
      results = []
    } else {
      results = try container.decode([PublicInspectionDocument].self, forKey: .results)
    }
    totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
  }

  /// Encodes all source metadata without recomputing counts or continuation.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
