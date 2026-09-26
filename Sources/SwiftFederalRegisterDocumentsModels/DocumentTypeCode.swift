#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An extensible FederalRegister.gov document type code, such as `RULE` or `PRESDOCU`.
///
/// Codes are the values the search API accepts in `conditions[type][]`. The four static members name
/// the codes the provider documents today; any other code remains representable through
/// ``rawValue``. Construction performs no validation.
///
/// ```swift
/// let code = DocumentTypeCode.proposedRule
/// let future = DocumentTypeCode(rawValue: "FUTURE")
/// ```
public struct DocumentTypeCode: Codable, Hashable, RawRepresentable, Sendable {
  /// A notice, `NOTICE`.
  public static let notice = DocumentTypeCode(rawValue: "NOTICE")
  /// A presidential document, `PRESDOCU`.
  public static let presidentialDocument = DocumentTypeCode(rawValue: "PRESDOCU")
  /// A proposed rule, `PRORULE`.
  public static let proposedRule = DocumentTypeCode(rawValue: "PRORULE")
  /// A final rule, `RULE`.
  public static let rule = DocumentTypeCode(rawValue: "RULE")

  /// The exact code as FederalRegister.gov spells it.
  public let rawValue: String

  /// Creates a code without restricting future provider values.
  /// - Parameter rawValue: The exact code.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Decodes the exact code from a single JSON string.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` for a non-string value.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Encodes the exact code as a single JSON string.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
