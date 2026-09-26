#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One FederalRegister.gov agency record, retaining every JSON field.
///
/// The same shape appears as an element of `/api/v1/agencies.json` and as the body of
/// `/api/v1/agencies/{slug}.json`. No key is required: a record missing its slug or name still
/// decodes, so no catalog entry is dropped. Every typed property is a projection of ``fields`` and
/// is nil when the key is absent, explicitly null, or of an unexpected JSON kind; inspect ``fields``
/// to tell those apart. Array projections are all or nothing: one incompatible element makes the
/// whole projection nil. Links remain the provider's strings, including `http` scheme and numeric
/// `json_url` paths, and are never fetched or rewritten. The agency list and its hierarchy describe
/// the provider's current catalog, not the agency that published a historical document.
///
/// ```swift
/// let agency = try FederalRegisterAgency.decode(data)
/// print(agency.name ?? "Unnamed", agency.shortName ?? "", agency.childSlugs ?? [])
/// print(agency.fields["parent_id"] == .null)
/// ```
public struct FederalRegisterAgency: Codable, DocumentResponse, Hashable {
  /// Every published attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// The agency's own website link; FederalRegister.gov publishes empty and null values for some
  /// agencies.
  public var agencyURL: String? { fields["agency_url"]?.string }
  /// The numeric identifiers of the provider's child agencies, in provider order.
  public var childIDs: [Int]? { fields["child_ids"]?.intArray }
  /// The slugs of the provider's child agencies, in provider order.
  public var childSlugs: [AgencyIdentifier]? {
    fields["child_slugs"]?.stringArray?.map(AgencyIdentifier.init(rawValue:))
  }
  /// The provider's narrative description, with its original line breaks.
  public var description: String? { fields["description"]?.string }
  /// The provider's numeric agency identifier.
  public var id: Int? { fields["id"]?.int }
  /// The advertised JSON link, retained as published; the detail route omits it.
  public var jsonURL: String? { fields["json_url"]?.string }
  /// The advertised logo links; many agencies publish a null logo.
  public var logo: AgencyLogo? { fields["logo"]?.object.map(AgencyLogo.init(fields:)) }
  /// The provider's display name.
  public var name: String? { fields["name"]?.string }
  /// The numeric identifier of the provider's parent agency; nil for a top-level agency and when the
  /// key is absent, null, or of another JSON kind.
  public var parentID: Int? { fields["parent_id"]?.int }
  /// The advertised link to the agency's recent documents, retained as published.
  public var recentArticlesURL: String? { fields["recent_articles_url"]?.string }
  /// The provider's abbreviation, when one is published.
  public var shortName: String? { fields["short_name"]?.string }
  /// The provider's agency slug.
  public var slug: AgencyIdentifier? {
    fields["slug"]?.string.map(AgencyIdentifier.init(rawValue:))
  }
  /// The informational FederalRegister.gov agency page link.
  public var url: String? { fields["url"]?.string }

  /// Decodes an agency while retaining the entire source object.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when the value is not a JSON object.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
  }

  /// Encodes all original fields, including explicit nulls and unrecognized attributes.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
