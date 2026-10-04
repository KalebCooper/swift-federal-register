#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A typed single HTTP operation on the FederalRegister.gov origin.
///
/// ```swift
/// let endpoint = try Endpoint<FederalRegisterDocument>.document("93-32104")
/// ```
public struct Endpoint<Response>: Hashable, Sendable {
  /// The Accept header value.
  public let accept: String
  /// A validated absolute path and optional query, relative to the fixed provider origin.
  public let path: String

  /// Creates an endpoint from an official link, rejecting credentials, fragments, and other origins.
  /// - Parameters:
  ///   - accept: The requested media type.
  ///   - link: An absolute HTTPS FederalRegister.gov link in a supported API or full-text route.
  public init?(accept: String = "application/json", link: String) {
    guard let parts = URLComponents(string: link), parts.scheme == "https",
      parts.host == "www.federalregister.gov", parts.port == nil || parts.port == 443,
      parts.user == nil, parts.password == nil, parts.fragment == nil
    else { return nil }
    self.init(
      accept: accept,
      path: parts.percentEncodedPath + (parts.percentEncodedQuery.map { "?" + $0 } ?? ""))
  }

  /// Creates a custom typed endpoint in the document, agency, or full-text routes.
  ///
  /// Agency routes are the catalog, `/api/v1/agencies.json`, and a detail path with exactly one
  /// segment after `/api/v1/agencies/`.
  /// - Parameters:
  ///   - accept: A nonempty media type without control characters.
  ///   - path: A root-relative path with no authority, fragments, dot segments, or encoded separators.
  public init?(accept: String = "application/json", path: String) {
    guard !accept.isEmpty,
      !accept.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
      path.hasPrefix("/"), !path.hasPrefix("//"),
      !path.unicodeScalars.contains(where: {
        $0.value <= 32 || $0.value >= 127 || $0 == "\\" || $0 == "#"
      }),
      let parts = URLComponents(string: "https://www.federalregister.gov" + path),
      parts.percentEncodedPath == String(path.split(separator: "?", maxSplits: 1)[0]),
      let decoded = URLComponents(string: "https://www.federalregister.gov" + path)?.path,
      !decoded.contains("%"), !decoded.contains("\\"),
      !decoded.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
      !decoded.split(separator: "/", omittingEmptySubsequences: false).dropFirst().contains(where: {
        $0.isEmpty || $0 == "." || $0 == ".."
      }),
      decoded == parts.percentEncodedPath,
      Self.isIssuePath(decoded) || decoded == "/api/v1/documents"
        || decoded == "/api/v1/documents.json"
        || decoded.hasPrefix("/api/v1/documents/") || decoded.hasPrefix("/documents/full_text/")
        || decoded == "/api/v1/agencies.json"
        || (decoded.hasPrefix("/api/v1/agencies/")
          && !decoded.dropFirst("/api/v1/agencies/".count).contains("/"))
    else { return nil }
    self.accept = accept
    self.path = path
  }

  static func builtIn(accept: String = "application/json", path: String) -> Self {
    guard let endpoint = Self(accept: accept, path: path) else {
      preconditionFailure("Fixed provider paths and encoded query items form valid endpoints.")
    }
    return endpoint
  }

  /// Encodes query items for the provider's form parser, which reads `+` as a space.
  ///
  /// Every UTF-8 byte outside the RFC 3986 unreserved characters becomes an uppercase `%XX`
  /// escape, so `+`, `&`, `=`, `;`, `?`, `#`, `%`, spaces, and non-ASCII text arrive exactly as given.
  static func formEncodedQuery(_ items: [URLQueryItem]) -> String {
    items.map { formEncoded($0.name) + "=" + formEncoded($0.value ?? "") }.joined(separator: "&")
  }

  private static func formEncoded(_ text: String) -> String {
    var encoded = ""
    for byte in text.utf8 {
      switch byte {
      case 45, 46, 48...57, 65...90, 95, 97...122, 126:
        encoded.unicodeScalars.append(Unicode.Scalar(byte))
      default:
        let hex = String(byte, radix: 16, uppercase: true)
        encoded += (hex.count == 1 ? "%0" : "%") + hex
      }
    }
    return encoded
  }

  private static func isIssuePath(_ path: String) -> Bool {
    let prefix = "/api/v1/issues/"
    guard path.hasPrefix(prefix), path.hasSuffix(".json") else { return false }
    return GregorianDate.isValid(String(path.dropFirst(prefix.count).dropLast(5)))
  }

  /// Whether a provider identifier can form one path segment: nonempty ASCII letters, digits, and hyphens.
  static func isPathSegment(_ value: String) -> Bool {
    !value.isEmpty
      && value.utf8.allSatisfy {
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45
      }
  }
}

extension Endpoint where Response == AgencyList {
  /// Describes the complete agency catalog lookup.
  ///
  /// The provider answers with every agency in one response; there is no continuation.
  /// - Returns: The independent catalog endpoint.
  public static func agencies() -> Self {
    builtIn(path: "/api/v1/agencies.json")
  }
}

extension Endpoint where Response == FederalRegisterAgency {
  /// Describes an agency detail lookup by slug.
  ///
  /// Any slug is accepted, including one the generated catalog does not name; the provider decides
  /// whether it exists.
  /// - Parameter identifier: A slug containing only ASCII letters, digits, and hyphens.
  /// - Returns: The independent detail endpoint.
  /// - Throws: `DocumentValidationError.invalidAgencyIdentifier` for an empty slug or one with any other character.
  public static func agency(_ identifier: AgencyIdentifier) throws(DocumentValidationError) -> Self
  {
    guard isPathSegment(identifier.rawValue) else {
      throw .invalidAgencyIdentifier(identifier.rawValue)
    }
    return builtIn(path: "/api/v1/agencies/" + identifier.rawValue + ".json")
  }
}

extension Endpoint where Response == FederalRegisterDocument {
  /// Describes a document detail lookup.
  /// - Parameter number: A nonempty provider document number containing ASCII letters, digits, and hyphens.
  /// - Returns: The independent detail endpoint.
  /// - Throws: `DocumentValidationError.invalidDocumentNumber` for invalid path input.
  public static func document(_ number: String) throws(DocumentValidationError) -> Self {
    try document(number, fields: [])
  }

  /// Describes a selected document detail, retaining required identity and title.
  /// - Parameters:
  ///   - number: Original provider number, with letters, digits, and hyphens only.
  ///   - fields: Empty preserves defaults; nonempty adds document number and title.
  /// - Returns: One independent endpoint.
  /// - Throws: `DocumentValidationError` for invalid number or field names.
  public static func document(_ number: String, fields: [DocumentField])
    throws(DocumentValidationError) -> Self
  {
    guard isPathSegment(number) else { throw .invalidDocumentNumber(number) }
    let items = try DocumentField.queryItems(fields)
    return builtIn(
      path: "/api/v1/documents/" + number + ".json"
        + (items.isEmpty ? "" : "?" + formEncodedQuery(items)))
  }
}

extension Endpoint where Response == DocumentPage {
  /// Describes the first presidential-document search page.
  /// - Parameter query: Validated filters and page size.
  /// - Returns: A single-page endpoint. Sequence execution uses the separate request's continuation policy.
  public static func presidentialDocuments(matching query: DocumentQuery) -> Self {
    var components = URLComponents()
    components.queryItems = query.queryItems
    return builtIn(path: "/api/v1/documents.json?" + (components.percentEncodedQuery ?? ""))
  }

  /// Describes the first page of a general document search.
  ///
  /// Query values are percent-encoded outside the RFC 3986 unreserved characters, so a term
  /// containing `+`, `&`, `=`, or `%` reaches the provider exactly as stored in the query. No
  /// document-type condition is added.
  ///
  /// ```swift
  /// let endpoint = Endpoint<DocumentPage>.searchDocuments(
  ///   matching: try DocumentSearchQuery(term: "clean water"))
  /// ```
  /// - Parameter query: Validated general search filters, order, and page size.
  /// - Returns: A single-page endpoint. Sequence execution uses the separate request's continuation policy.
  public static func searchDocuments(matching query: DocumentSearchQuery) -> Self {
    builtIn(path: "/api/v1/documents.json?" + formEncodedQuery(query.queryItems))
  }
}

extension Endpoint where Response == DocumentBatch {
  /// Describes one batch lookup, with no chunking, reordering, or retry.
  /// - Parameters:
  ///   - numbers: Nonempty original identifiers, each validated before joining with commas.
  ///   - fields: Empty preserves defaults; nonempty includes document number and title.
  /// - Returns: One endpoint; singleton responses retain their detail representation.
  /// - Throws: `DocumentValidationError` for empty input, unsafe identifiers, or invalid field names.
  public static func documents(numbered numbers: [String], fields: [DocumentField] = [])
    throws(DocumentValidationError) -> Self
  {
    guard !numbers.isEmpty else { throw .emptyDocumentNumbers }
    for number in numbers where !isPathSegment(number) { throw .invalidDocumentNumber(number) }
    let items = try DocumentField.queryItems(fields)
    return builtIn(
      path: "/api/v1/documents/" + numbers.joined(separator: ",") + ".json"
        + (items.isEmpty ? "" : "?" + formEncodedQuery(items)))
  }
}

extension Endpoint where Response == DocumentFacetCounts {
  /// Describes facet counts using search conditions only.
  /// - Parameters:
  ///   - facet: The provider grouping.
  ///   - query: Conditions to count; fields, order, and page size are excluded.
  /// - Returns: One response of keyed buckets, with no automatic continuation.
  public static func documentFacets(_ facet: DocumentFacet, matching query: DocumentSearchQuery)
    -> Self
  {
    let conditions = formEncodedQuery(query.conditionItems)
    return builtIn(
      path: "/api/v1/documents/facets/" + facet.rawValue
        + (conditions.isEmpty ? "" : "?" + conditions))
  }
}

extension Endpoint where Response == IssueTableOfContents {
  /// Describes one daily issue lookup; a nonpublication-day HTTP failure remains a failure.
  /// - Parameter date: A real Gregorian YYYY-MM-DD date.
  /// - Returns: One independent issue endpoint.
  /// - Throws: `DocumentValidationError.invalidDate` for invalid input.
  public static func issueTableOfContents(on date: String) throws(DocumentValidationError) -> Self {
    guard GregorianDate.isValid(date) else { throw .invalidDate(date) }
    return builtIn(path: "/api/v1/issues/" + date + ".json")
  }
}
