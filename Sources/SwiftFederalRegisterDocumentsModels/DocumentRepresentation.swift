/// Advertised full-text representations on FederalRegister.gov, independent of actual availability.
public enum DocumentRepresentation: String, Codable, Sendable {
  /// An HTML body fragment.
  case html
  /// A text endpoint, sometimes carrying the historical GPO HTML pre wrapper.
  case text
  /// A source XML document; no XML-to-JSON mapping is implied.
  case xml
}
