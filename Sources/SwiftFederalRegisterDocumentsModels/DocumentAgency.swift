#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One agency attribution on a Federal Register document, retaining every JSON field.
///
/// Documents list agencies as the provider attributed them at publication. ``rawName`` is the name
/// printed on the document; ``name`` and ``slug`` link it to the provider's current catalog when a
/// match exists. No key is required: an attribution carrying only a raw name decodes with every other
/// projection nil. A projection of an unexpected JSON kind is nil while ``fields`` keeps the raw
/// value. The attribution states nothing about the agency's hierarchy beyond ``parentID``.
///
/// ```swift
/// let agency = try JSONDecoder().decode(DocumentAgency.self, from: data)
/// print(agency.rawName ?? "", agency.slug?.rawValue ?? "unmatched")
/// ```
public struct DocumentAgency: Codable, Hashable, Sendable {
  /// Every published attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// The provider's numeric agency identifier.
  public var id: Int? { fields["id"]?.int }
  /// The advertised JSON link, retained as published.
  public var jsonURL: String? { fields["json_url"]?.string }
  /// The provider's current display name for the matched agency.
  public var name: String? { fields["name"]?.string }
  /// The numeric identifier of the provider's parent agency, or nil for a top-level agency.
  public var parentID: Int? { fields["parent_id"]?.int }
  /// The agency name as printed on the document, without normalization.
  public var rawName: String? { fields["raw_name"]?.string }
  /// The provider's agency slug for the matched agency.
  public var slug: AgencyIdentifier? {
    fields["slug"]?.string.map(AgencyIdentifier.init(rawValue:))
  }
  /// The informational FederalRegister.gov agency page link.
  public var url: String? { fields["url"]?.string }

  /// Decodes an agency attribution while retaining the entire source object.
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
