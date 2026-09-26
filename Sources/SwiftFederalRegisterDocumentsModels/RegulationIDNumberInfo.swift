#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The Unified Agenda details FederalRegister.gov publishes for one Regulation Identifier Number,
/// retaining every JSON field.
///
/// A document keys these details by RIN in
/// ``FederalRegisterDocument/regulationIDNumberInfo``. The issue is the agenda edition exactly as
/// published, such as `"202410"`, and is not converted to a date. Links are never fetched or
/// validated. A projection of an unexpected JSON kind is nil while ``fields`` keeps the raw value.
///
/// ```swift
/// if let info = document.regulationIDNumberInfo?["2060-AS35"] {
///   print(info.priorityCategory ?? "", info.issue ?? "")
/// }
/// ```
public struct RegulationIDNumberInfo: Codable, Hashable, Sendable {
  /// Every published attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// The informational FederalRegister.gov page link for the RIN.
  public var htmlURL: String? { fields["html_url"]?.string }
  /// The Unified Agenda edition exactly as published.
  public var issue: String? { fields["issue"]?.string }
  /// The agenda priority category exactly as published.
  public var priorityCategory: String? { fields["priority_category"]?.string }
  /// The agenda title of the rulemaking, without normalization.
  public var title: String? { fields["title"]?.string }
  /// The advertised agenda XML link, retained as published.
  public var xmlURL: String? { fields["xml_url"]?.string }

  init(fields: [String: JSONValue]) { self.fields = fields }

  /// Decodes RIN details while retaining the entire source object.
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
