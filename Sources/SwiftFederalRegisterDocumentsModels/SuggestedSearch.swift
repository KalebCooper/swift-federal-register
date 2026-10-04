#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Discovery metadata only; source search conditions are never converted or executed.
/// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
public struct SuggestedSearch: Codable, DocumentResponse, Hashable, Sendable {
  /// Every source member, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// Source description markup, retained without rendering.
  public var description: String? { fields["description"]?.string }
  /// Reported documents in the last year, without a coverage guarantee.
  public var documentsInLastYear: Int? { fields["documents_in_last_year"]?.int }
  /// Reported documents with open comment periods.
  public var documentsWithOpenCommentPeriods: Int? {
    fields["documents_with_open_comment_periods"]?.int
  }
  /// Source catalog position, absent in detail responses.
  public var position: Int? { fields["position"]?.int }
  /// Exact source conditions, including internal agency IDs and incomplete geographic inputs.
  public var searchConditions: JSONValue? { fields["search_conditions"] }
  /// The open source section slug.
  public var section: SectionIdentifier? {
    fields["section"]?.string.map(SectionIdentifier.init(rawValue:))
  }
  /// The open source search slug.
  public var slug: SuggestedSearchIdentifier? {
    fields["slug"]?.string.map(SuggestedSearchIdentifier.init(rawValue:))
  }
  /// The source title, unchanged.
  public var title: String? { fields["title"]?.string }

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
