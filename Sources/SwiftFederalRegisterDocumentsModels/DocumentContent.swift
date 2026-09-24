#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A lossless UTF-8 source representation, including markup and conflicting date statements.
///
/// This codec preserves source text rather than rendering HTML or interpreting XML elements.
/// Historical `.txt` responses can contain HTML. The source is never silently stripped or relabeled.
public struct DocumentContent: DocumentResponse, Hashable {
  /// The exact UTF-8 text, including any HTML wrapper or XML markup.
  public let source: String

  /// Decodes a UTF-8 representation without stripping markup or resolving external entities.
  /// - Parameter data: Bytes retrieved from a verified full-text route.
  /// - Returns: The unmodified source text.
  /// - Throws: `DocumentContentError.invalidUTF8` for an unsupported character encoding.
  public static func decode(_ data: Data) throws(DocumentContentError) -> Self {
    guard let source = String(data: data, encoding: .utf8) else { throw .invalidUTF8 }
    return Self(source: source)
  }
}

/// A content decoding or representation-selection failure.
public enum DocumentContentError: Error, Hashable, Sendable {
  /// The advertised link is outside the expected source representation route.
  case invalidLink(String)
  /// The body is not valid UTF-8; no lossy replacement is performed.
  case invalidUTF8
  /// The provider did not advertise the requested representation.
  case unavailable(DocumentRepresentation)
}

extension Endpoint where Response == DocumentContent {
  /// Describes an advertised full-text representation without assuming that it exists remotely.
  /// - Parameters:
  ///   - representation: The representation to request.
  ///   - document: The source document whose link is used exactly as supplied.
  /// - Returns: A typed UTF-8 content endpoint; PDF and GPO metadata are source links only.
  /// - Throws: `DocumentContentError` for a missing or invalid link.
  public static func content(
    _ representation: DocumentRepresentation, for document: FederalRegisterDocument
  )
    throws(DocumentContentError) -> Self
  {
    let accept: String
    let link: String?
    let route: String
    switch representation {
    case .html: accept = "text/html"; link = document.bodyHTMLURL; route = "html"
    case .text: accept = "text/plain"; link = document.rawTextURL; route = "text"
    case .xml: accept = "text/xml"; link = document.fullTextXMLURL; route = "xml"
    }
    guard let link else { throw .unavailable(representation) }
    guard let endpoint = Self(accept: accept, link: link),
      endpoint.path.hasPrefix("/documents/full_text/" + route + "/")
    else { throw .invalidLink(link) }
    return endpoint
  }
}

extension DocumentRequest where Response == DocumentContent {
  /// Describes a source representation using its advertised link.
  /// - Parameters:
  ///   - representation: The desired textual representation.
  ///   - document: A previously decoded document.
  /// - Returns: A reusable content operation.
  /// - Throws: `DocumentContentError` for absent or invalid links.
  public static func content(
    _ representation: DocumentRepresentation, for document: FederalRegisterDocument
  )
    throws(DocumentContentError) -> Self
  {
    Self(endpoint: try .content(representation, for: document))
  }
}
