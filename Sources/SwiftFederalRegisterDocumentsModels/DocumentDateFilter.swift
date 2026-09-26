#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A validated date condition for a general document search, in exactly one of the provider's
/// three forms: a single date, an inclusive range, or a calendar year.
///
/// Every value comes from a throwing factory, so a stored filter is always well formed: dates are
/// real Gregorian `YYYY-MM-DD` dates, a range has at least one bound and its bounds are ordered,
/// and a year lies in 1 through 9999. The filter keeps the exact strings it was given; it never
/// converts a date to an instant or a time zone. Which document date the condition applies to is
/// decided by the query parameter that carries it, such as `publicationDate` or `effectiveDate`.
///
/// ```swift
/// let year = try DocumentDateFilter.inYear(2025)
/// let day = try DocumentDateFilter.on("2024-12-31")
/// let range = try DocumentDateFilter.range(from: "2024-01-01", through: nil)
/// ```
public struct DocumentDateFilter: Hashable, Sendable {
  /// The provider's date-condition forms.
  public enum Form: Hashable, Sendable {
    /// One Gregorian `YYYY-MM-DD` date, sent as the `is` condition.
    case exact(String)
    /// Inclusive Gregorian `YYYY-MM-DD` bounds, sent as the `gte` and `lte` conditions; a nil
    /// bound is not sent.
    case range(from: String?, through: String?)
    /// A calendar year, sent as the `year` condition.
    case year(Int)
  }

  /// The validated form and its exact values.
  public let form: Form

  private init(form: Form) { self.form = form }

  /// Creates a filter matching every date in one calendar year.
  /// - Parameter year: A year in 1 through 9999.
  /// - Returns: A filter whose ``form`` is `.year`.
  /// - Throws: `DocumentValidationError.invalidYear` for a year outside 1 through 9999.
  public static func inYear(_ year: Int) throws(DocumentValidationError) -> Self {
    guard (1...9999).contains(year) else { throw .invalidYear(year) }
    return Self(form: .year(year))
  }

  /// Creates a filter matching one date.
  /// - Parameter date: A Gregorian `YYYY-MM-DD` date.
  /// - Returns: A filter whose ``form`` is `.exact`.
  /// - Throws: `DocumentValidationError.invalidDate` when the string is not a real date.
  public static func on(_ date: String) throws(DocumentValidationError) -> Self {
    guard GregorianDate.isValid(date) else { throw .invalidDate(date) }
    return Self(form: .exact(date))
  }

  /// Creates a filter matching every date within inclusive bounds.
  /// - Parameters:
  ///   - from: The inclusive Gregorian `YYYY-MM-DD` lower bound, or nil for an open lower bound.
  ///   - through: The inclusive Gregorian `YYYY-MM-DD` upper bound, or nil for an open upper bound.
  /// - Returns: A filter whose ``form`` is `.range`.
  /// - Throws: `DocumentValidationError.invalidDate` when a bound is not a real date, or
  ///   `DocumentValidationError.invalidDateRange` when both bounds are nil or the lower bound is
  ///   after the upper bound.
  public static func range(from: String?, through: String?) throws(DocumentValidationError) -> Self
  {
    for date in [from, through].compactMap({ $0 }) {
      guard GregorianDate.isValid(date) else { throw .invalidDate(date) }
    }
    guard from != nil || through != nil else { throw .invalidDateRange }
    if let from, let through, from > through { throw .invalidDateRange }
    return Self(form: .range(from: from, through: through))
  }

  /// The `conditions[<key>][...]` items this filter contributes for one document date.
  func queryItems(forKey key: String) -> [URLQueryItem] {
    switch form {
    case .exact(let date):
      return [URLQueryItem(name: "conditions[\(key)][is]", value: date)]
    case .range(let from, let through):
      var items: [URLQueryItem] = []
      if let from { items.append(URLQueryItem(name: "conditions[\(key)][gte]", value: from)) }
      if let through { items.append(URLQueryItem(name: "conditions[\(key)][lte]", value: through)) }
      return items
    case .year(let year):
      return [URLQueryItem(name: "conditions[\(key)][year]", value: String(year))]
    }
  }
}

/// Gregorian `YYYY-MM-DD` validation shared by every date input in this module.
enum GregorianDate {
  /// Whether `value` is exactly ten ASCII characters naming a real proleptic Gregorian date with a
  /// year in 1 through 9999, leap days included.
  static func isValid(_ value: String) -> Bool {
    let parts = value.split(separator: "-", omittingEmptySubsequences: false)
    guard value.utf8.count == 10, parts.count == 3, parts[0].count == 4,
      parts[1].count == 2, parts[2].count == 2,
      parts.allSatisfy({ $0.utf8.allSatisfy { (48...57).contains($0) } }),
      let year = Int(parts[0]), year > 0, let month = Int(parts[1]), (1...12).contains(month),
      let day = Int(parts[2])
    else { return false }
    let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    let days = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return (1...days[month - 1]).contains(day)
  }
}
