#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An open provider value; unknown spellings remain representable without normalization.
public struct SectionIdentifier: Codable, Hashable, RawRepresentable, Sendable {
  /// The provider value `business-and-industry`.
  public static let businessAndIndustry = Self(rawValue: "business-and-industry")
  /// The provider value `environment`.
  public static let environment = Self(rawValue: "environment")
  /// The provider value `health-and-public-welfare`.
  public static let healthAndPublicWelfare = Self(rawValue: "health-and-public-welfare")
  /// The provider value `money`.
  public static let money = Self(rawValue: "money")
  /// The provider value `science-and-technology`.
  public static let scienceAndTechnology = Self(rawValue: "science-and-technology")
  /// The provider value `world`.
  public static let world = Self(rawValue: "world")

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
