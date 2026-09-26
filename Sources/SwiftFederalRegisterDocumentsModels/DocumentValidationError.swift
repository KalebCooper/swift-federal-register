/// Invalid input for a document operation.
public enum DocumentValidationError: Error, Hashable, Sendable {
  /// An agency slug is empty or contains characters outside letters, digits, and hyphens.
  case invalidAgencyIdentifier(String)
  /// A date is not a real Gregorian YYYY-MM-DD date.
  case invalidDate(String)
  /// A document number contains characters outside letters, digits, and hyphens.
  case invalidDocumentNumber(String)
  /// Page size lies outside 1 through 1000.
  case invalidPageSize(Int)
  /// The lower publication-date bound is after the upper bound.
  case reversedDates
}
