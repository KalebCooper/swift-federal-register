#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One Code of Federal Regulations location a Federal Register document affects, retaining every
/// JSON field.
///
/// The provider publishes the CFR title as a number and the part as a string; both are kept in the
/// source's kind without normalization. A projection of an unexpected JSON kind is nil while
/// ``fields`` keeps the raw value. The chapter has no typed projection because no recorded response
/// supplies a non-null chapter; read `fields["chapter"]` for it. A reference states which CFR
/// location the document names, not the text or effective state of that location.
///
/// ```swift
/// for reference in document.cfrReferences ?? [] {
///   print(reference.title.map(String.init) ?? "?", reference.part ?? "?")
/// }
/// ```
public struct CFRReference: Codable, Hashable, Sendable {
  /// Every published attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// The advertised link to the cited CFR location, retained as published.
  public var citationURL: String? { fields["citation_url"]?.string }
  /// The CFR part exactly as the provider spells it.
  public var part: String? { fields["part"]?.string }
  /// The CFR title number.
  public var title: Int? { fields["title"]?.int }

  init(fields: [String: JSONValue]) { self.fields = fields }

  /// Decodes a CFR reference while retaining the entire source object.
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
