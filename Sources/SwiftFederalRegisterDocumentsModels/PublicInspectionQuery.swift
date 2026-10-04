#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Immutable inspection search filters, with no implicit type or filing condition.
/// A dated complete listing is separate because available_on bypasses search filters.
public struct PublicInspectionQuery: Hashable, Sendable {
  /// Open agency slugs, sent repeatedly.
  public let agencies: [AgencyIdentifier]
  /// Exact docket identifier.
  public let docketID: String?
  /// Selected fields; nonempty selections include identity and title.
  public let fields: [PublicInspectionDocumentField]
  /// Results per page, 1...1000.
  public let pageSize: Int
  /// Optional regular or special filing condition.
  public let specialFiling: PublicInspectionFilingFilter?
  /// Exact provider full-text expression.
  public let term: String?
  /// Open document type codes, sent repeatedly.
  public let types: [DocumentTypeCode]

  /// Creates validated filters without I/O.
  /// - Parameters:
  ///   - agencies: Nonempty slugs without controls.
  ///   - docketID: Optional nonempty docket text without controls.
  ///   - fields: Open names; empty preserves provider defaults.
  ///   - pageSize: A value in 1...1000, default 20.
  ///   - specialFiling: Optional filing condition.
  ///   - term: Optional nonempty text without controls.
  ///   - types: Nonempty codes without controls.
  /// - Throws: `DocumentValidationError` for an invalid page size or empty/control input.
  public init(
    agencies: [AgencyIdentifier] = [], docketID: String? = nil,
    fields: [PublicInspectionDocumentField] = [], pageSize: Int = 20,
    specialFiling: PublicInspectionFilingFilter? = nil, term: String? = nil,
    types: [DocumentTypeCode] = []
  ) throws(DocumentValidationError) {
    for agency in agencies where !DocumentSearchQuery.isUsable(agency.rawValue) {
      throw .emptyFilterValue("agencies")
    }
    if let docketID, !DocumentSearchQuery.isUsable(docketID) { throw .emptyFilterValue("docketID") }
    _ = try PublicInspectionDocumentField.queryItems(fields)
    guard (1...1000).contains(pageSize) else { throw .invalidPageSize(pageSize) }
    if let term, !DocumentSearchQuery.isUsable(term) { throw .emptyFilterValue("term") }
    for type in types where !DocumentSearchQuery.isUsable(type.rawValue) {
      throw .emptyFilterValue("types")
    }
    self.agencies = agencies
    self.docketID = docketID
    self.fields = fields
    self.pageSize = pageSize
    self.specialFiling = specialFiling
    self.term = term
    self.types = types
  }

  var queryItems: [URLQueryItem] {
    var items = agencies.map { URLQueryItem(name: "conditions[agencies][]", value: $0.rawValue) }
    if let docketID { items.append(URLQueryItem(name: "conditions[docket_id]", value: docketID)) }
    if let specialFiling {
      items.append(URLQueryItem(name: "conditions[special_filing]", value: specialFiling.rawValue))
    }
    if let term { items.append(URLQueryItem(name: "conditions[term]", value: term)) }
    items += types.map { URLQueryItem(name: "conditions[type][]", value: $0.rawValue) }
    items += (try? PublicInspectionDocumentField.queryItems(fields)) ?? []
    items.append(URLQueryItem(name: "per_page", value: String(pageSize)))
    return items.sorted { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
  }
}
