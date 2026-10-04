#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An open inspection-search field name. Unknown names are sent unchanged.
///
/// An empty selection preserves provider defaults. Nonempty selections include document number
/// and title so built-in responses retain their required identity. The provider may reject unknown names.
public struct PublicInspectionDocumentField: Codable, Hashable, RawRepresentable, Sendable {
  /// The provider's `agencies` field.
  public static let agencies = Self(rawValue: "agencies")
  /// The provider's `agency_letters` field.
  public static let agencyLetters = Self(rawValue: "agency_letters")
  /// The provider's `agency_names` field.
  public static let agencyNames = Self(rawValue: "agency_names")
  /// The provider's `docket_numbers` field.
  public static let docketNumbers = Self(rawValue: "docket_numbers")
  /// The provider's `document_number` field.
  public static let documentNumber = Self(rawValue: "document_number")
  /// The provider's `editorial_note` field.
  public static let editorialNote = Self(rawValue: "editorial_note")
  /// The provider's `excerpts` field.
  public static let excerpts = Self(rawValue: "excerpts")
  /// The provider's `filed_at` field.
  public static let filedAt = Self(rawValue: "filed_at")
  /// The provider's `filing_type` field.
  public static let filingType = Self(rawValue: "filing_type")
  /// The provider's `html_url` field.
  public static let htmlURL = Self(rawValue: "html_url")
  /// The provider's `json_url` field.
  public static let jsonURL = Self(rawValue: "json_url")
  /// The provider's `last_public_inspection_issue` field.
  public static let lastPublicInspectionIssue = Self(rawValue: "last_public_inspection_issue")
  /// The provider's `num_pages` field.
  public static let numPages = Self(rawValue: "num_pages")
  /// The provider's `page_views` field.
  public static let pageViews = Self(rawValue: "page_views")
  /// The provider's `pdf_file_name` field.
  public static let pdfFileName = Self(rawValue: "pdf_file_name")
  /// The provider's `pdf_file_size` field.
  public static let pdfFileSize = Self(rawValue: "pdf_file_size")
  /// The provider's `pdf_updated_at` field.
  public static let pdfUpdatedAt = Self(rawValue: "pdf_updated_at")
  /// The provider's `pdf_url` field.
  public static let pdfURL = Self(rawValue: "pdf_url")
  /// The provider's `publication_date` field.
  public static let publicationDate = Self(rawValue: "publication_date")
  /// The provider's `raw_text_url` field.
  public static let rawTextURL = Self(rawValue: "raw_text_url")
  /// The provider's `subject_1` field.
  public static let subject1 = Self(rawValue: "subject_1")
  /// The provider's `subject_2` field.
  public static let subject2 = Self(rawValue: "subject_2")
  /// The provider's `subject_3` field.
  public static let subject3 = Self(rawValue: "subject_3")
  /// The provider's `title` field.
  public static let title = Self(rawValue: "title")
  /// The provider's `toc_doc` field.
  public static let tocDoc = Self(rawValue: "toc_doc")
  /// The provider's `toc_subject` field.
  public static let tocSubject = Self(rawValue: "toc_subject")
  /// The provider's `type` field.
  public static let type = Self(rawValue: "type")

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
