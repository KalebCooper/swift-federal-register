#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One public-inspection record, distinct from a published Federal Register document.
///
/// `fields["pdf_url"] == .null` distinguishes an explicit null from an omitted field.
/// Filing and intended publication dates remain distinct source strings. A scheduled date is not proof of publication. The publisher is OFR/NARA in partnership with GPO; the
/// FederalRegister.gov rendition is informational, and GPO publishes the official edition.
public struct PublicInspectionDocument: Codable, DocumentResponse, Hashable {
  /// The provider's document number, including historical prefixes.
  public let documentNumber: String
  /// Every published attribute, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]
  /// The source title, without normalization.
  public let title: String

  /// Source `agencies`, retained without normalization; nil for an incompatible kind.
  public var agencies: [DocumentAgency]? {
    fields["agencies"]?.objectArray?.map(DocumentAgency.init(fields:))
  }
  /// Source `docket_numbers`, retained without normalization; nil for an incompatible kind.
  public var docketNumbers: [String]? { fields["docket_numbers"]?.stringArray }
  /// Source `type`, retained without normalization; nil for an incompatible kind.
  public var documentType: DocumentType? {
    fields["type"]?.string.map(DocumentType.init(rawValue:))
  }
  /// Source `editorial_note`, retained without normalization; nil for an incompatible kind.
  public var editorialNote: String? { fields["editorial_note"]?.string }
  /// Source `filed_at`, retained without normalization; nil for an incompatible kind.
  public var filedAt: String? { fields["filed_at"]?.string }
  /// Source `filing_type`, retained without normalization; nil for an incompatible kind.
  public var filingType: PublicInspectionFilingType? {
    fields["filing_type"]?.string.map(PublicInspectionFilingType.init(rawValue:))
  }
  /// Source `html_url`, retained without normalization; nil for an incompatible kind.
  public var htmlURL: String? { fields["html_url"]?.string }
  /// Source `json_url`, retained without normalization; nil for an incompatible kind.
  public var jsonURL: String? { fields["json_url"]?.string }
  /// Source `last_public_inspection_issue`, retained without normalization; nil for an incompatible kind.
  public var lastPublicInspectionIssue: String? { fields["last_public_inspection_issue"]?.string }
  /// Source `num_pages`, retained without normalization; nil for an incompatible kind.
  public var numberOfPages: Int? { fields["num_pages"]?.int }
  /// Source `pdf_file_name`, retained without normalization; nil for an incompatible kind.
  public var pdfFileName: String? { fields["pdf_file_name"]?.string }
  /// Source `pdf_file_size`, retained without normalization; nil for an incompatible kind.
  public var pdfFileSize: Int? { fields["pdf_file_size"]?.int }
  /// Source `pdf_url`, retained without normalization; nil for an incompatible kind.
  public var pdfURL: String? { fields["pdf_url"]?.string }
  /// Source `pdf_updated_at`, retained without normalization; nil for an incompatible kind.
  public var pdfUpdatedAt: String? { fields["pdf_updated_at"]?.string }
  /// Source `publication_date`, retained without normalization; nil for an incompatible kind.
  public var publicationDate: String? { fields["publication_date"]?.string }
  /// Source `raw_text_url`, retained without normalization; nil for an incompatible kind.
  public var rawTextURL: String? { fields["raw_text_url"]?.string }
  /// Source `subject_1`, retained without normalization; nil for an incompatible kind.
  public var subject1: String? { fields["subject_1"]?.string }
  /// Source `subject_2`, retained without normalization; nil for an incompatible kind.
  public var subject2: String? { fields["subject_2"]?.string }
  /// Source `toc_doc`, retained without normalization; nil for an incompatible kind.
  public var tocDoc: String? { fields["toc_doc"]?.string }
  /// Source `toc_subject`, retained without normalization; nil for an incompatible kind.
  public var tocSubject: String? { fields["toc_subject"]?.string }
  /// Source `type`, retained without normalization; nil for an incompatible kind.
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
