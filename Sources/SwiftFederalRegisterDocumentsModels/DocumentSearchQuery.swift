#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Validated filters for a general document search, with no implicit document-type condition.
///
/// Every filter is optional and sent only when given. A query never adds a condition of its own,
/// so an empty query asks for every document in the provider's default projection; the
/// presidential-only ``DocumentQuery`` is the one that inserts `conditions[type][]=PRESDOCU`.
/// Strings are kept exactly as given, without trimming, case changes, or interpretation of the
/// provider's full-text syntax. Repeated agencies and types are sent as repeated parameters with
/// their multiplicity intact; the provider does not document how it combines them, and this type
/// promises no AND, OR, or parent-agency expansion. Unknown agency slugs and type codes are valid
/// inputs. Results are newest first with 20 per page unless `order` and `pageSize` say otherwise.
///
/// ```swift
/// let search = try DocumentSearchQuery(
///   agencies: [.environmentalProtectionAgency],
///   cfr: CFRFilter(part: "1-50", title: 40),
///   publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
///   term: "water",
///   types: [.proposedRule, .rule])
/// ```
public struct DocumentSearchQuery: Hashable, Sendable {
  /// Publishing agencies, sent as repeated `conditions[agencies][]` values.
  public let agencies: [AgencyIdentifier]
  /// The CFR location, sent as `conditions[cfr][title]` and, when present, `conditions[cfr][part]`.
  public let cfr: CFRFilter?
  /// One opaque docket identifier, sent as `conditions[docket_id]`.
  public let docketID: String?
  /// The effective-date condition, sent under `conditions[effective_date]`.
  public let effectiveDate: DocumentDateFilter?
  /// The requested chronological order.
  public let order: DocumentQuery.Order
  /// Number of results per response; the API documents 20 by default and 1000 maximum.
  public let pageSize: Int
  /// The publication-date condition, sent under `conditions[publication_date]`.
  public let publicationDate: DocumentDateFilter?
  /// One Regulation Identifier Number, sent as `conditions[regulation_id_number]`.
  public let regulationIDNumber: String?
  /// The full-text search expression, sent as `conditions[term]` exactly as given.
  public let term: String?
  /// Document types, sent as repeated `conditions[type][]` codes.
  public let types: [DocumentTypeCode]

  /// Creates validated immutable filters; no request is sent.
  /// - Parameters:
  ///   - agencies: Agency slugs; each must be nonempty without control characters.
  ///   - cfr: A validated CFR title and optional part.
  ///   - docketID: A docket identifier; nonempty without control characters when given.
  ///   - effectiveDate: A validated effective-date condition.
  ///   - order: Chronological order, defaulting to newest first.
  ///   - pageSize: A value in 1...1000; defaults to the API's 20.
  ///   - publicationDate: A validated publication-date condition.
  ///   - regulationIDNumber: A Regulation Identifier Number; nonempty without control characters
  ///     when given.
  ///   - term: A full-text expression; nonempty without control characters when given.
  ///   - types: Document type codes; each must be nonempty without control characters.
  /// - Throws: `DocumentValidationError.invalidPageSize` for a page size outside 1...1000, or
  ///   `DocumentValidationError.emptyFilterValue` naming the parameter (`agencies`, `docketID`,
  ///   `regulationIDNumber`, `term`, or `types`) whose value is empty or contains a control
  ///   character.
  public init(
    agencies: [AgencyIdentifier] = [], cfr: CFRFilter? = nil, docketID: String? = nil,
    effectiveDate: DocumentDateFilter? = nil, order: DocumentQuery.Order = .newest,
    pageSize: Int = 20, publicationDate: DocumentDateFilter? = nil,
    regulationIDNumber: String? = nil, term: String? = nil, types: [DocumentTypeCode] = []
  ) throws(DocumentValidationError) {
    for agency in agencies where !Self.isUsable(agency.rawValue) {
      throw .emptyFilterValue("agencies")
    }
    if let docketID, !Self.isUsable(docketID) { throw .emptyFilterValue("docketID") }
    guard (1...1000).contains(pageSize) else { throw .invalidPageSize(pageSize) }
    if let regulationIDNumber, !Self.isUsable(regulationIDNumber) {
      throw .emptyFilterValue("regulationIDNumber")
    }
    if let term, !Self.isUsable(term) { throw .emptyFilterValue("term") }
    for type in types where !Self.isUsable(type.rawValue) { throw .emptyFilterValue("types") }
    self.agencies = agencies
    self.cfr = cfr
    self.docketID = docketID
    self.effectiveDate = effectiveDate
    self.order = order
    self.pageSize = pageSize
    self.publicationDate = publicationDate
    self.regulationIDNumber = regulationIDNumber
    self.term = term
    self.types = types
  }

  /// Every query item this search sends, with raw values, sorted by name and then by value so the
  /// same filters always produce the same sequence.
  package var queryItems: [URLQueryItem] {
    var items: [URLQueryItem] = []
    for agency in agencies {
      items.append(URLQueryItem(name: "conditions[agencies][]", value: agency.rawValue))
    }
    if let cfr { items += cfr.queryItems }
    if let docketID { items.append(URLQueryItem(name: "conditions[docket_id]", value: docketID)) }
    if let effectiveDate { items += effectiveDate.queryItems(forKey: "effective_date") }
    items.append(URLQueryItem(name: "order", value: order.rawValue))
    items.append(URLQueryItem(name: "per_page", value: String(pageSize)))
    if let publicationDate { items += publicationDate.queryItems(forKey: "publication_date") }
    if let regulationIDNumber {
      items.append(
        URLQueryItem(name: "conditions[regulation_id_number]", value: regulationIDNumber))
    }
    if let term { items.append(URLQueryItem(name: "conditions[term]", value: term)) }
    for type in types {
      items.append(URLQueryItem(name: "conditions[type][]", value: type.rawValue))
    }
    return items.sorted { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
  }

  /// Whether a filter string is nonempty and free of Unicode control characters.
  private static func isUsable(_ value: String) -> Bool {
    !value.isEmpty && !value.unicodeScalars.contains { $0.properties.generalCategory == .control }
  }
}
