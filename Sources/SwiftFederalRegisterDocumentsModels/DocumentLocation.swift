#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A provider geographic condition, preserving location text and an optional radius.
/// No device location, geocoding, or local distance calculation occurs.
public struct DocumentLocation: Hashable, Sendable {
  /// ZIP or city/state text, unchanged.
  public let location: String
  /// Requested radius in miles, or nil to leave the provider default unspecified.
  public let withinMiles: Int?

  /// Validates geographic input without sending a request.
  /// - Parameters:
  ///   - location: Nonempty location text without control characters.
  ///   - withinMiles: An optional integer in 1...200.
  /// - Throws: `DocumentValidationError.emptyFilterValue` or `DocumentValidationError.invalidDistanceMiles`.
  public init(location: String, withinMiles: Int? = nil) throws(DocumentValidationError) {
    guard DocumentSearchQuery.isUsable(location) else { throw .emptyFilterValue("location") }
    if let withinMiles, !(1...200).contains(withinMiles) {
      throw .invalidDistanceMiles(withinMiles)
    }
    self.location = location
    self.withinMiles = withinMiles
  }
}
