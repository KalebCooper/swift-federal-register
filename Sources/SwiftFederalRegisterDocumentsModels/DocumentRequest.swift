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
    /// An inspection search following only validated increasing page-number links.
    case publicInspectionSearch(Endpoint<Response>)
  }

  /// The underlying independently executable endpoint.
  public var endpoint: Endpoint<Response> {
    switch resolution {
    case .documentSearch(let endpoint), .endpoint(let endpoint),
      .presidentialDocuments(let endpoint), .publicInspectionSearch(let endpoint):
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

extension DocumentRequest where Response == DocumentBatch {
  /// Describes a single batch operation in provider order.
  /// - Parameters:
  ///   - numbers: Nonempty original identifiers.
  ///   - fields: Empty preserves defaults; nonempty includes document number and title.
  /// - Returns: A reusable request with no automatic continuation or missing-record retry.
  /// - Throws: `DocumentValidationError` for empty input, unsafe identifiers, or invalid fields.
  public static func documents(numbered numbers: [String], fields: [DocumentField] = [])
    throws(DocumentValidationError) -> Self
  {
    Self(endpoint: try .documents(numbered: numbers, fields: fields))
  }
}

extension DocumentRequest where Response == DocumentFacetCounts {
  /// Describes one condition-only facet request.
  /// - Parameters:
  ///   - facet: Provider grouping.
  ///   - query: Search conditions; presentation parameters are excluded.
  /// - Returns: One reusable request with no continuation.
  public static func documentFacets(_ facet: DocumentFacet, matching query: DocumentSearchQuery)
    -> Self
  {
    Self(endpoint: .documentFacets(facet, matching: query))
  }
}

extension DocumentRequest where Response == IssueTableOfContents {
  /// Describes one daily issue without fetching its referenced documents.
  /// - Parameter date: A real Gregorian YYYY-MM-DD date.
  /// - Returns: One reusable request.
  /// - Throws: `DocumentValidationError.invalidDate` for invalid input.
  public static func issueTableOfContents(on date: String) throws(DocumentValidationError) -> Self {
    Self(endpoint: try .issueTableOfContents(on: date))
  }
}

extension DocumentRequest where Response == PublicInspectionBatch {
  /// Describes one inspection operation without continuation or automatic hydration.
  /// - Parameter numbers: The original nonempty identifiers.
  /// - Returns: One reusable source request.
  /// - Throws: `DocumentValidationError` for invalid input.
  public static func publicInspectionDocuments(numbered numbers: [String])
    throws(DocumentValidationError) -> Self
  {
    Self(endpoint: try .publicInspectionDocuments(numbered: numbers))
  }
}

extension DocumentRequest where Response == PublicInspectionDocument {
  /// Describes one inspection operation without continuation or automatic hydration.
  /// - Parameter number: The original provider identifier.
  /// - Returns: One reusable source request.
  /// - Throws: `DocumentValidationError` for invalid input.
  public static func publicInspectionDocument(_ number: String) throws(DocumentValidationError)
    -> Self
  {
    Self(endpoint: try .publicInspectionDocument(number))
  }
}

extension DocumentRequest where Response == PublicInspectionListing {
  /// Describes one inspection operation without continuation or automatic hydration.
  /// - Returns: One reusable source request.
  public static func currentPublicInspectionDocuments() -> Self {
    Self(endpoint: .currentPublicInspectionDocuments())
  }
}

extension DocumentRequest where Response == PublicInspectionListing {
  /// Describes one inspection operation without continuation or automatic hydration.
  /// - Parameter date: A real Gregorian YYYY-MM-DD date.
  /// - Returns: One reusable source request.
  /// - Throws: `DocumentValidationError` for invalid input.
  public static func publicInspectionDocuments(availableOn date: String)
    throws(DocumentValidationError) -> Self
  {
    Self(endpoint: try .publicInspectionDocuments(availableOn: date))
  }
}

extension DocumentRequest where Response == PublicInspectionPage {
  /// Describes an inspection search with validated lazy continuation.
  /// - Parameter query: Validated inspection filters.
  /// - Returns: A reusable request; single-value execution fetches only the first page.
  public static func searchPublicInspectionDocuments(matching query: PublicInspectionQuery) -> Self
  {
    Self(resolution: .publicInspectionSearch(.searchPublicInspectionDocuments(matching: query)))
  }
}
