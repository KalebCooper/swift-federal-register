#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An open published-document field name. Unknown names are sent unchanged.
///
/// An empty selection preserves provider defaults. Nonempty selections include document number
/// and title so built-in responses retain their required identity. The provider may reject unknown names.
public struct DocumentField: Codable, Hashable, RawRepresentable, Sendable {
  /// The provider's `abstract` field.
  public static let abstract = Self(rawValue: "abstract")
  /// The provider's `action` field.
  public static let action = Self(rawValue: "action")
  /// The provider's `agencies` field.
  public static let agencies = Self(rawValue: "agencies")
  /// The provider's `agency_names` field.
  public static let agencyNames = Self(rawValue: "agency_names")
  /// The provider's `amendatory_instructions` field.
  public static let amendatoryInstructions = Self(rawValue: "amendatory_instructions")
  /// The provider's `body_html_url` field.
  public static let bodyHTMLURL = Self(rawValue: "body_html_url")
  /// The provider's `cfr_references` field.
  public static let cfrReferences = Self(rawValue: "cfr_references")
  /// The provider's `cfr_topics` field.
  public static let cfrTopics = Self(rawValue: "cfr_topics")
  /// The provider's `citation` field.
  public static let citation = Self(rawValue: "citation")
  /// The provider's `comments_close_on` field.
  public static let commentsCloseOn = Self(rawValue: "comments_close_on")
  /// The provider's `comment_url` field.
  public static let commentURL = Self(rawValue: "comment_url")
  /// The provider's `correction_of` field.
  public static let correctionOf = Self(rawValue: "correction_of")
  /// The provider's `corrections` field.
  public static let corrections = Self(rawValue: "corrections")
  /// The provider's `dates` field.
  public static let dates = Self(rawValue: "dates")
  /// The provider's `disposition_notes` field.
  public static let dispositionNotes = Self(rawValue: "disposition_notes")
  /// The provider's `docket_id` field.
  public static let docketID = Self(rawValue: "docket_id")
  /// The provider's `docket_ids` field.
  public static let docketIDs = Self(rawValue: "docket_ids")
  /// The provider's `dockets` field.
  public static let dockets = Self(rawValue: "dockets")
  /// The provider's `document_number` field.
  public static let documentNumber = Self(rawValue: "document_number")
  /// The provider's `effective_on` field.
  public static let effectiveOn = Self(rawValue: "effective_on")
  /// The provider's `end_page` field.
  public static let endPage = Self(rawValue: "end_page")
  /// The provider's `excerpts` field.
  public static let excerpts = Self(rawValue: "excerpts")
  /// The provider's `executive_order_notes` field.
  public static let executiveOrderNotes = Self(rawValue: "executive_order_notes")
  /// The provider's `executive_order_number` field.
  public static let executiveOrderNumber = Self(rawValue: "executive_order_number")
  /// The provider's `explanation` field.
  public static let explanation = Self(rawValue: "explanation")
  /// The provider's `full_text_xml_url` field.
  public static let fullTextXMLURL = Self(rawValue: "full_text_xml_url")
  /// The provider's `html_url` field.
  public static let htmlURL = Self(rawValue: "html_url")
  /// The provider's `images` field.
  public static let images = Self(rawValue: "images")
  /// The provider's `images_metadata` field.
  public static let imagesMetadata = Self(rawValue: "images_metadata")
  /// The provider's `json_url` field.
  public static let jsonURL = Self(rawValue: "json_url")
  /// The provider's `mods_url` field.
  public static let modsURL = Self(rawValue: "mods_url")
  /// The provider's `not_received_for_publication` field.
  public static let notReceivedForPublication = Self(rawValue: "not_received_for_publication")
  /// The provider's `page_length` field.
  public static let pageLength = Self(rawValue: "page_length")
  /// The provider's `page_views` field.
  public static let pageViews = Self(rawValue: "page_views")
  /// The provider's `pdf_url` field.
  public static let pdfURL = Self(rawValue: "pdf_url")
  /// The provider's `president` field.
  public static let president = Self(rawValue: "president")
  /// The provider's `presidential_document_number` field.
  public static let presidentialDocumentNumber = Self(rawValue: "presidential_document_number")
  /// The provider's `proclamation_number` field.
  public static let proclamationNumber = Self(rawValue: "proclamation_number")
  /// The provider's `publication_date` field.
  public static let publicationDate = Self(rawValue: "publication_date")
  /// The provider's `public_inspection_pdf_url` field.
  public static let publicInspectionPDFURL = Self(rawValue: "public_inspection_pdf_url")
  /// The provider's `raw_text_url` field.
  public static let rawTextURL = Self(rawValue: "raw_text_url")
  /// The provider's `regulation_id_number_info` field.
  public static let regulationIDNumberInfo = Self(rawValue: "regulation_id_number_info")
  /// The provider's `regulation_id_numbers` field.
  public static let regulationIDNumbers = Self(rawValue: "regulation_id_numbers")
  /// The provider's `regulations_dot_gov_info` field.
  public static let regulationsDotGovInfo = Self(rawValue: "regulations_dot_gov_info")
  /// The provider's `regulations_dot_gov_url` field.
  public static let regulationsDotGovURL = Self(rawValue: "regulations_dot_gov_url")
  /// The provider's `related_documents` field.
  public static let relatedDocuments = Self(rawValue: "related_documents")
  /// The provider's `significant` field.
  public static let significant = Self(rawValue: "significant")
  /// The provider's `signing_date` field.
  public static let signingDate = Self(rawValue: "signing_date")
  /// The provider's `start_page` field.
  public static let startPage = Self(rawValue: "start_page")
  /// The provider's `subtype` field.
  public static let subtype = Self(rawValue: "subtype")
  /// The provider's `title` field.
  public static let title = Self(rawValue: "title")
  /// The provider's `toc_doc` field.
  public static let tocDoc = Self(rawValue: "toc_doc")
  /// The provider's `toc_subject` field.
  public static let tocSubject = Self(rawValue: "toc_subject")
  /// The provider's `topics` field.
  public static let topics = Self(rawValue: "topics")
  /// The provider's `type` field.
  public static let type = Self(rawValue: "type")
  /// The provider's `volume` field.
  public static let volume = Self(rawValue: "volume")

  /// The exact provider field name.
  public let rawValue: String

  /// Creates an open name; request construction validates empty and control-character values.
  /// - Parameter rawValue: The exact field name.
  public init(rawValue: String) { self.rawValue = rawValue }

  /// Decodes a single field-name string.
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  /// Encodes a single field-name string.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  static func queryItems(_ fields: [Self]) throws(DocumentValidationError) -> [URLQueryItem] {
    for field in fields where !DocumentSearchQuery.isUsable(field.rawValue) {
      throw .emptyFilterValue("fields")
    }
    guard !fields.isEmpty else { return [] }
    var effective = fields
    for required in [Self.documentNumber, .title] where !effective.contains(required) {
      effective.append(required)
    }
    return effective.map { URLQueryItem(name: "fields[]", value: $0.rawValue) }
      .sorted { ($0.value ?? "") < ($1.value ?? "") }
  }
}
