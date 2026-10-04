#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A reusable, inspectable document operation; construction performs no I/O.
///
/// ```swift
/// let request = try DocumentRequest.document("93-32104")
/// ```
public struct DocumentRequest<Response>: Hashable, Sendable {
  /// A transport-free resolution containing only endpoint values and continuation policy.
  public enum Resolution: Hashable, Sendable {
    /// A library-created general search whose sequence follows validated cursor or page-number links.
    case documentSearch(Endpoint<Response>)
    /// One endpoint, with no automatic continuation.
    case endpoint(Endpoint<Response>)
    /// A library-created presidential search whose sequence follows validated cursor or page-number
    /// links, the same rule as every library-created sequence.
    case presidentialDocuments(Endpoint<Response>)
  }

  /// The underlying independently executable endpoint.
  public var endpoint: Endpoint<Response> {
    switch resolution {
    case .documentSearch(let endpoint), .endpoint(let endpoint),
      .presidentialDocuments(let endpoint):
      return endpoint
    }
  }

  /// The complete value description available to custom executors.
  public let resolution: Resolution

  /// Creates a single-operation request, including a consumer-defined response.
  /// - Parameter endpoint: The endpoint to execute once.
  public init(endpoint: Endpoint<Response>) { resolution = .endpoint(endpoint) }

  private init(resolution: Resolution) { self.resolution = resolution }

}

extension DocumentRequest where Response == AgencyList {
  /// Describes the complete agency catalog lookup.
  /// - Returns: A reusable single-operation request with no continuation.
  public static func agencies() -> Self {
    Self(endpoint: .agencies())
  }
}

extension DocumentRequest where Response == FederalRegisterAgency {
  /// Describes one agency detail lookup by slug.
  /// - Parameter identifier: The agency slug, known or not yet cataloged.
  /// - Returns: A reusable single-operation request.
  /// - Throws: `DocumentValidationError.invalidAgencyIdentifier` for invalid path input.
  public static func agency(_ identifier: AgencyIdentifier) throws(DocumentValidationError) -> Self
  {
    Self(endpoint: try .agency(identifier))
  }
}

extension DocumentRequest where Response == FederalRegisterDocument {
  /// Describes one document detail lookup.
  /// - Parameter number: The original provider document number.
  /// - Returns: A reusable detail request.
  /// - Throws: `DocumentValidationError.invalidDocumentNumber` for invalid input.
  public static func document(_ number: String) throws(DocumentValidationError) -> Self {
    try document(number, fields: [])
  }

  /// Describes a selected document detail with required identity and title.
  /// - Parameters:
  ///   - number: The original provider number.
  ///   - fields: Empty preserves defaults; nonempty adds document number and title.
  /// - Returns: A single-operation request.
  /// - Throws: `DocumentValidationError` for invalid input.
  public static func document(_ number: String, fields: [DocumentField])
    throws(DocumentValidationError) -> Self
  {
    Self(endpoint: try .document(number, fields: fields))
  }
}

extension DocumentRequest where Response == DocumentPage {
  /// Describes a presidential search for lazy sequence execution.
  ///
  /// A sequence follows the validated cursor or page-number links the provider publishes, the same
  /// rule as every library-created sequence; recorded presidential responses publish cursors.
  /// - Parameter query: Immutable validated filters.
  /// - Returns: A request whose single-value execution still retrieves only its first page.
  public static func presidentialDocuments(matching query: DocumentQuery) -> Self {
    Self(resolution: .presidentialDocuments(.presidentialDocuments(matching: query)))
  }

  /// Describes a general document search whose lazy sequence follows the provider's next links.
  ///
  /// The provider continues most searches by an opaque `search_after_cursor` and a term search by a
  /// page number; a sequence follows whichever a validated next link carries. The reported
  /// `total_pages` is capped, 50 at `per_page=2` in recorded captures, and the provider does not
  /// promise that pages beyond its depth cap exist. Only published links are followed.
  ///
  /// ```swift
  /// let request = DocumentRequest.searchDocuments(
  ///   matching: try DocumentSearchQuery(agencies: [.environmentalProtectionAgency]))
  /// ```
  /// - Parameter query: Immutable validated general search filters.
  /// - Returns: A request whose single-value execution still retrieves only its first page.
  public static func searchDocuments(matching query: DocumentSearchQuery) -> Self {
    Self(resolution: .documentSearch(.searchDocuments(matching: query)))
  }
}
