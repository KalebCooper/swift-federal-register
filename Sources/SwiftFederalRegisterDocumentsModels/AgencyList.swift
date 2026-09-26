#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The complete FederalRegister.gov agency list, in provider order.
///
/// `/api/v1/agencies.json` returns a bare top-level JSON array with no envelope and no pagination.
/// This value decodes that array and encodes it back as an array. Order and duplicates are the
/// provider's; the list is a snapshot of the current catalog and makes no completeness or stability
/// promise. An element that is not a JSON object fails decoding; a missing or incompatible field
/// inside an element does not.
///
/// ```swift
/// let list = try AgencyList.decode(data)
/// let epa = list.agencies.first { $0.slug == .environmentalProtectionAgency }
/// ```
public struct AgencyList: Codable, DocumentResponse, Hashable {
  /// The agencies, in the order the provider returned them.
  public let agencies: [FederalRegisterAgency]

  /// Decodes the provider's top-level agency array.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when the value is not an array of JSON objects.
  public init(from decoder: any Decoder) throws {
    agencies = try decoder.singleValueContainer().decode([FederalRegisterAgency].self)
  }

  /// Encodes the agencies as a bare top-level array, with no invented envelope.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(agencies)
  }
}
