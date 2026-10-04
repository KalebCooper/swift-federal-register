#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An open provider value; unknown spellings remain representable without normalization.
public struct PublicInspectionFilingType: Codable, Hashable, RawRepresentable, Sendable {
  /// A regular filing.
  public static let regular = Self(rawValue: "regular")
  /// A special filing.
  public static let special = Self(rawValue: "special")

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
