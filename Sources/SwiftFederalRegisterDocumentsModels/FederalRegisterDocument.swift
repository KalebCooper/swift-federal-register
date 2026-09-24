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
  /// The advertised HTML body link; a link does not establish availability.
  public var bodyHTMLURL: String? { fields["body_html_url"]?.string }
  /// The published Federal Register citation.
  public var citation: String? { fields["citation"]?.string }
  /// The provider narrative date evidence, without reconciliation.
  public var dates: String? { fields["dates"]?.string }
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
