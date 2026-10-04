/// The ten supported provider facet routes. Returned bucket keys remain open strings.
public enum DocumentFacet: String, CaseIterable, Codable, Sendable {
  /// Groups source matches by agency.
  case agency
  /// Groups source matches by daily.
  case daily
  /// Groups source matches by monthly.
  case monthly
  /// Groups source matches by quarterly.
  case quarterly
  /// Groups source matches by section.
  case section
  /// Groups source matches by subtype.
  case subtype
  /// Groups source matches by topic.
  case topic
  /// Groups source matches by type.
  case type
  /// Groups source matches by weekly.
  case weekly
  /// Groups source matches by yearly.
  case yearly
}
