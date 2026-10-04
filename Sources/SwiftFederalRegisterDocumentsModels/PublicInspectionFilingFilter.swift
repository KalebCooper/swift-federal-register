/// A bounded inspection search condition, separate from the open response filing label.
public enum PublicInspectionFilingFilter: String, Codable, Sendable {
  /// Regular filings, encoded as 0.
  case regular = "0"
  /// Special filings, encoded as 1.
  case special = "1"
}
