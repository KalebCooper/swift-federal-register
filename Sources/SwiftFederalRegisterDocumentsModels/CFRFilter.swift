#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A validated Code of Federal Regulations location for a general document search: a title, with
/// an optional part or inclusive part range.
///
/// The title is a positive integer. The part, when given, is a nonnegative integer written in
/// ASCII digits, or two such integers joined by a hyphen with the first no greater than the second,
/// with no sign, whitespace, or other characters. Input spelling is preserved exactly, leading
/// zeros included, and the range comparison is numeric with no width limit. No maximum title or
/// part is imposed because the provider documents none. A filter names a CFR location to search
/// for; it says nothing about whether that location exists or what it contains.
///
/// ```swift
/// let title = try CFRFilter(title: 40)
/// let part = try CFRFilter(part: "52", title: 40)
/// let parts = try CFRFilter(part: "1-50", title: 40)
/// ```
public struct CFRFilter: Hashable, Sendable {
  /// The CFR part or inclusive `lower-upper` part range exactly as given, or nil for the whole title.
  public let part: String?
  /// The CFR title number.
  public let title: Int

  /// Creates a validated CFR location filter.
  /// - Parameters:
  ///   - part: A nonnegative integer or an ascending inclusive `lower-upper` range in ASCII digits;
  ///     nil searches the whole title.
  ///   - title: A CFR title number of 1 or more.
  /// - Throws: `DocumentValidationError.invalidCFRFilter` carrying the offending title, rendered as
  ///   a string, or the offending part exactly as given.
  public init(part: String? = nil, title: Int) throws(DocumentValidationError) {
    guard title >= 1 else { throw .invalidCFRFilter(String(title)) }
    if let part, !Self.isValidPart(part) { throw .invalidCFRFilter(part) }
    self.part = part
    self.title = title
  }

  /// The `conditions[cfr][...]` items this filter contributes.
  var queryItems: [URLQueryItem] {
    var items = [URLQueryItem(name: "conditions[cfr][title]", value: String(title))]
    if let part { items.append(URLQueryItem(name: "conditions[cfr][part]", value: part)) }
    return items
  }

  private static func isDigits(_ value: Substring) -> Bool {
    !value.isEmpty && value.utf8.allSatisfy { (48...57).contains($0) }
  }

  /// Whether `lower` names a number no greater than `upper`, comparing digit strings of any length
  /// without leading zeros so that no integer overflow can occur.
  private static func isOrdered(_ lower: Substring, _ upper: Substring) -> Bool {
    let lowerDigits = lower.drop { $0 == "0" }
    let upperDigits = upper.drop { $0 == "0" }
    if lowerDigits.count != upperDigits.count { return lowerDigits.count < upperDigits.count }
    return lowerDigits <= upperDigits
  }

  private static func isValidPart(_ part: String) -> Bool {
    let bounds = part.split(separator: "-", omittingEmptySubsequences: false)
    switch bounds.count {
    case 1: return isDigits(bounds[0])
    case 2: return isDigits(bounds[0]) && isDigits(bounds[1]) && isOrdered(bounds[0], bounds[1])
    default: return false
    }
  }
}
