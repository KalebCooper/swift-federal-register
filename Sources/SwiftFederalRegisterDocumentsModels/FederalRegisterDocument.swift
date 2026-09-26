#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One Federal Register document or list result, retaining every JSON field.
///
/// `fields["pdf_url"] == .null` distinguishes an explicit null from an omitted field.
/// Dates remain source strings. The publisher is OFR/NARA in partnership with GPO; the
/// FederalRegister.gov rendition is informational, and GPO publishes the official edition.
public struct FederalRegisterDocument: Codable, DocumentResponse, Hashable {
  /// The provider's document number, including historical prefixes.
  public let documentNumber: String
  /// Every published attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]
  /// The source title, without normalization.
  public let title: String

  /// The provider abstract, including its absence.
  public var abstract: String? { fields["abstract"]?.string }
  /// The provider's action statement, such as `Final rule.`, without normalization.
  public var action: String? { fields["action"]?.string }
  /// The agency attributions in source order.
  ///
  /// Nil when the field is absent or is not an array whose every element is a JSON object. Within
  /// an attribution, a property of an unexpected JSON kind is nil while its raw value stays in
  /// ``DocumentAgency/fields``, so one unusual attribute never removes the list.
  public var agencies: [DocumentAgency]? {
    fields["agencies"]?.array?.objects?.map(DocumentAgency.init(fields:))
  }
  /// The advertised HTML body link; a link does not establish availability.
  public var bodyHTMLURL: String? { fields["body_html_url"]?.string }
  /// The Code of Federal Regulations locations the document names, in source order.
  ///
  /// Nil when the field is absent, is not an array of JSON objects, or any reference carries a
  /// `title` that is not an integral number or a `part` or `citation_url` that is not a string.
  /// Absent and null values of those keys are accepted. An empty array stays empty. The raw value
  /// remains in ``fields`` in every case.
  public var cfrReferences: [CFRReference]? {
    guard let objects = fields["cfr_references"]?.array?.objects,
      objects.allSatisfy({ reference in
        reference["citation_url"].isAbsentNullOr(\.string)
          && reference["part"].isAbsentNullOr(\.string)
          && reference["title"].isAbsentNullOr(\.int)
      })
    else { return nil }
    return objects.map(CFRReference.init(fields:))
  }
  /// The published Federal Register citation.
  public var citation: String? { fields["citation"]?.string }
  /// The advertised Regulations.gov comment link, retained as published.
  public var commentURL: String? { fields["comment_url"]?.string }
  /// The source comment-period closing date string, distinct from publication and effective dates.
  public var commentsCloseOn: String? { fields["comments_close_on"]?.string }
  /// The provider narrative date evidence, without reconciliation.
  public var dates: String? { fields["dates"]?.string }
  /// The source `docket_id` string, which is independent of ``docketIDs`` and often absent.
  public var docketID: String? { fields["docket_id"]?.string }
  /// The source docket identifiers in order, nil unless every element is a string.
  public var docketIDs: [String]? { fields["docket_ids"]?.stringArray }
  /// The open provider document type label, read from the same `type` field as ``type``.
  public var documentType: DocumentType? {
    fields["type"]?.string.map(DocumentType.init(rawValue:))
  }
  /// The source effective-date string.
  public var effectiveOn: String? { fields["effective_on"]?.string }
  /// The source executive-order number, when supplied.
  public var executiveOrderNumber: String? { fields["executive_order_number"]?.string }
  /// The advertised XML link; historical nulls remain nil.
  public var fullTextXMLURL: String? { fields["full_text_xml_url"]?.string }
  /// The informational FederalRegister.gov page link.
  public var htmlURL: String? { fields["html_url"]?.string }
  /// The source JSON link, retained as published.
  public var jsonURL: String? { fields["json_url"]?.string }
  /// The advertised GPO metadata link.
  public var modsURL: String? { fields["mods_url"]?.string }
  /// The advertised GPO official-edition PDF link; no URL is synthesized.
  public var pdfURL: String? { fields["pdf_url"]?.string }
  /// The provider presidential-document number.
  public var presidentialDocumentNumber: String? { fields["presidential_document_number"]?.string }
  /// The publication date, independent of the signing date.
  public var publicationDate: String? { fields["publication_date"]?.string }
  /// The advertised text link, which can serve an HTML pre wrapper.
  public var rawTextURL: String? { fields["raw_text_url"]?.string }
  /// The Unified Agenda details keyed by Regulation Identifier Number.
  ///
  /// Nil when the field is absent or is not an object whose every value is a JSON object. Within
  /// one entry, a property of an unexpected JSON kind is nil while its raw value stays in
  /// ``RegulationIDNumberInfo/fields``. An empty object stays empty.
  public var regulationIDNumberInfo: [String: RegulationIDNumberInfo]? {
    guard let members = fields["regulation_id_number_info"]?.object else { return nil }
    var entries: [String: RegulationIDNumberInfo] = [:]
    entries.reserveCapacity(members.count)
    for (number, value) in members {
      guard let info = value.object else { return nil }
      entries[number] = RegulationIDNumberInfo(fields: info)
    }
    return entries
  }
  /// The Regulation Identifier Numbers in source order, nil unless every element is a string.
  public var regulationIDNumbers: [String]? { fields["regulation_id_numbers"]?.stringArray }
  /// The advertised Regulations.gov document link, retained as published.
  public var regulationsDotGovURL: String? { fields["regulations_dot_gov_url"]?.string }
  /// The provider's significance flag; nil for an explicit null, an absent field, or another kind.
  public var significant: Bool? {
    if case .bool(let value) = fields["significant"] { return value }
    return nil
  }
  /// The signing date exactly as asserted, even when descriptive fields disagree.
  public var signingDate: String? { fields["signing_date"]?.string }
  /// The open provider subtype, including future values.
  public var subtype: String? { fields["subtype"]?.string }
  /// The source table-of-contents description, including conflicting date evidence.
  public var tocDoc: String? { fields["toc_doc"]?.string }
  /// The source table-of-contents subject.
  public var tocSubject: String? { fields["toc_subject"]?.string }
  /// The open provider document classification.
  public var type: String? { fields["type"]?.string }

  /// Decodes a document while retaining the entire source object.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    fields = try container.decode([String: JSONValue].self)
    guard let identifier = fields["document_number"]?.string,
      let heading = fields["title"]?.string
    else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "A document requires document_number and title strings.")
    }
    documentNumber = identifier
    title = heading
  }

  /// Encodes all original fields, including explicit nulls and unrecognized attributes.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}

// Nested projections accept an element only in the kinds below; anything else makes the whole
// projection nil while the document's raw fields keep the value.
extension [JSONValue] {
  /// Every element's members, or nil when any element is not a JSON object.
  fileprivate var objects: [[String: JSONValue]]? {
    var values: [[String: JSONValue]] = []
    values.reserveCapacity(count)
    for element in self {
      guard let value = element.object else { return nil }
      values.append(value)
    }
    return values
  }
}

extension JSONValue? {
  /// Whether the member is absent, an explicit null, or a kind the projection reads.
  fileprivate func isAbsentNullOr<Value>(_ projection: (JSONValue) -> Value?) -> Bool {
    switch self {
    case .none, .null: true
    case .some(let value): projection(value) != nil
    }
  }
}
