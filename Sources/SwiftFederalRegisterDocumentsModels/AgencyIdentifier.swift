/// An extensible FederalRegister.gov agency slug.
///
/// Known slugs are the generated catalog members in `AgencyIdentifier+Catalog.swift`, one per agency
/// in the recorded `/api/v1/agencies.json` snapshot. A slug the catalog does not name remains
/// representable through ``rawValue``. Construction performs no validation and no lookup; an
/// identifier is checked only when it is placed into a request path.
///
/// ```swift
/// let epa = AgencyIdentifier.environmentalProtectionAgency
/// let future = AgencyIdentifier(rawValue: "future-agency")
/// ```
public struct AgencyIdentifier: Codable, Hashable, RawRepresentable, Sendable {
  /// The exact slug as FederalRegister.gov spells it.
  public let rawValue: String

  /// Creates an identifier from a consumer-defined String-backed value.
  /// - Parameter value: The value whose raw string to retain.
  public init<Value>(_ value: Value) where Value: RawRepresentable, Value.RawValue == String {
    self.init(rawValue: value.rawValue)
  }

  /// Creates an identifier without restricting future provider slugs.
  /// - Parameter rawValue: The exact slug.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Decodes the exact slug from a single JSON string.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` for a non-string value.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Encodes the exact slug as a single JSON string.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
