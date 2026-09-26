#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The logo links FederalRegister.gov advertises for one agency, retaining every JSON field.
///
/// Each link is the provider's string, including any cache-busting query, and is never fetched or
/// validated. A link of an unexpected JSON kind projects as nil while ``fields`` keeps the raw value.
///
/// ```swift
/// let agency = try FederalRegisterAgency.decode(data)
/// if let thumbnail = agency.logo?.thumbURL {
///   print(thumbnail)
/// }
/// ```
public struct AgencyLogo: Codable, Hashable, Sendable {
  /// Every published logo attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// The medium image link, exactly as published.
  public var mediumURL: String? { fields["medium_url"]?.string }
  /// The small image link, exactly as published.
  public var smallURL: String? { fields["small_url"]?.string }
  /// The thumbnail image link, exactly as published.
  public var thumbURL: String? { fields["thumb_url"]?.string }

  init(fields: [String: JSONValue]) { self.fields = fields }

  /// Decodes a logo object while retaining the entire source object.
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
