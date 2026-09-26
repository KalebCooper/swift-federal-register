#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An extensible FederalRegister.gov document type label, such as `Rule` or `Presidential Document`.
///
/// Documents publish their type as a display label in the `type` field. The four static members
/// name the labels the provider documents today; any other label remains representable through
/// ``rawValue``. ``code`` maps only those four labels to their search codes and is nil for any other
/// label rather than guessing.
///
/// ```swift
/// if document.documentType == .proposedRule {
///   print(document.documentType?.code?.rawValue ?? "")
/// }
/// ```
public struct DocumentType: Codable, Hashable, RawRepresentable, Sendable {
  /// A notice, `Notice`.
  public static let notice = DocumentType(rawValue: "Notice")
  /// A presidential document, `Presidential Document`.
  public static let presidentialDocument = DocumentType(rawValue: "Presidential Document")
  /// A proposed rule, `Proposed Rule`.
  public static let proposedRule = DocumentType(rawValue: "Proposed Rule")
  /// A final rule, `Rule`.
  public static let rule = DocumentType(rawValue: "Rule")

  /// The exact label as FederalRegister.gov spells it.
  public let rawValue: String

  /// The search code for one of the four documented labels, or nil for any other label.
  public var code: DocumentTypeCode? {
    switch self {
    case .notice: .notice
    case .presidentialDocument: .presidentialDocument
    case .proposedRule: .proposedRule
    case .rule: .rule
    default: nil
    }
  }

  /// Creates a label without restricting future provider values.
  /// - Parameter rawValue: The exact label.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Decodes the exact label from a single JSON string.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` for a non-string value.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Encodes the exact label as a single JSON string.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
