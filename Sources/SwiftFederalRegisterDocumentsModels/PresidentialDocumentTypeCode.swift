#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An open provider value; unknown spellings remain representable without normalization.
public struct PresidentialDocumentTypeCode: Codable, Hashable, RawRepresentable, Sendable {
  /// The provider value `determination`.
  public static let determination = Self(rawValue: "determination")
  /// The provider value `executive_order`.
  public static let executiveOrder = Self(rawValue: "executive_order")
  /// The provider value `memorandum`.
  public static let memorandum = Self(rawValue: "memorandum")
  /// The provider value `notice`.
  public static let notice = Self(rawValue: "notice")
  /// The provider value `other`.
  public static let other = Self(rawValue: "other")
  /// The provider value `presidential_order`.
  public static let presidentialOrder = Self(rawValue: "presidential_order")
  /// The provider value `proclamation`.
  public static let proclamation = Self(rawValue: "proclamation")

  /// The exact provider spelling.
  public let rawValue: String

  /// Creates an open value; request construction validates applicable input constraints.
  /// - Parameter rawValue: The original provider spelling.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Decodes the exact value from one JSON string.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Encodes the exact value as one JSON string.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
