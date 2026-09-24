#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One search response, preserving counts and its cursor link independently.
///
/// `totalPages` can be capped even while `nextPageURL` continues. It is never a traversal limit.
public struct DocumentPage: Codable, DocumentResponse, Hashable {
  /// The reported number of matching documents, not a stable snapshot guarantee.
  public let count: Int
  /// Every original page field, including unknown metadata and explicit nulls.
  public let fields: [String: JSONValue]
  /// The next link as published; nil ends traversal, while an empty link is invalid.
  public let nextPageURL: String?
  /// Documents in provider order, including duplicates.
  public let results: [FederalRegisterDocument]
  /// The reported, potentially capped page total.
  public let totalPages: Int

  private enum CodingKeys: String, CodingKey {
    case count
    case nextPageURL = "next_page_url"
    case results
    case totalPages = "total_pages"
  }

  /// Decodes a page and retains its complete original JSON object.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    count = try container.decode(Int.self, forKey: .count)
    nextPageURL = try container.decodeIfPresent(String.self, forKey: .nextPageURL)
    results = try container.decode([FederalRegisterDocument].self, forKey: .results)
    totalPages = try container.decode(Int.self, forKey: .totalPages)
  }

  /// Encodes all source metadata without recomputing counts or continuation.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
