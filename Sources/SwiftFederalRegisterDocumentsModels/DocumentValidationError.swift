/// Invalid input for a document operation.
public enum DocumentValidationError: Error, Hashable, Sendable {
  /// A batch lookup requires at least one document number.
  case emptyDocumentNumbers
  /// A search filter value is empty or contains a control character; the associated value names
  /// the `DocumentSearchQuery` parameter (`agencies`, `docketID`, `regulationIDNumber`, `term`, or
  /// `types`).
  case emptyFilterValue(String)
  /// An agency slug is empty or contains characters outside letters, digits, and hyphens.
  case invalidAgencyIdentifier(String)
  /// A CFR title is below 1 or a CFR part is not a nonnegative integer or ascending integer range in
  /// ASCII digits; the associated value is the offending title as a string or the part as given.
  case invalidCFRFilter(String)
  /// A date is not a real Gregorian YYYY-MM-DD date.
  case invalidDate(String)
  /// A search date range has no bound or a lower bound after its upper bound.
  case invalidDateRange
  /// A geographic radius lies outside 1...200 miles.
  case invalidDistanceMiles(Int)
  /// A document number contains characters outside letters, digits, and hyphens.
  case invalidDocumentNumber(String)
  /// Page size lies outside 1 through 1000.
  case invalidPageSize(Int)
  /// A suggested-search slug contains characters outside letters, digits, and hyphens.
  case invalidSuggestedSearchIdentifier(String)
  /// A search year lies outside 1 through 9999.
  case invalidYear(Int)
  /// The lower publication-date bound is after the upper bound.
  case reversedDates
}
