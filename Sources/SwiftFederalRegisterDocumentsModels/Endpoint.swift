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

  /// Creates a custom typed endpoint in the document API or full-text routes.
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
      decoded == "/api/v1/documents" || decoded == "/api/v1/documents.json"
        || decoded.hasPrefix("/api/v1/documents/") || decoded.hasPrefix("/documents/full_text/")
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
}

extension Endpoint where Response == FederalRegisterDocument {
  /// Describes a document detail lookup.
  /// - Parameter number: A nonempty provider document number containing ASCII letters, digits, and hyphens.
  /// - Returns: The independent detail endpoint.
  /// - Throws: `DocumentValidationError.invalidDocumentNumber` for invalid path input.
  public static func document(_ number: String) throws(DocumentValidationError) -> Self {
    guard !number.isEmpty,
      number.utf8.allSatisfy({
        (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45
      })
    else { throw .invalidDocumentNumber(number) }
    return builtIn(path: "/api/v1/documents/" + number + ".json")
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
}
