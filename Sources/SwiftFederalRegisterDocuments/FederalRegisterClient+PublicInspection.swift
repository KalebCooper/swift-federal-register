import HTTPCore
import SwiftFederalRegisterDocumentsModels

extension FederalRegisterClient {
  /// Retrieves one inspection response, preserving source dates and partial errors.
  /// - Returns: The original source value; no PDF or referenced document is fetched.
  /// - Throws: `FederalRegisterError` for execution failures.
  public func currentPublicInspectionDocuments() async throws(FederalRegisterError)
    -> PublicInspectionListing
  {
    try await value(for: .currentPublicInspectionDocuments())
  }

  /// Retrieves one inspection response, preserving source dates and partial errors.
  /// - Parameter number: The original provider identifier.
  /// - Returns: The original source value; no PDF or referenced document is fetched.
  /// - Throws: `FederalRegisterError` for validation or execution failures.
  public func publicInspectionDocument(_ number: String) async throws(FederalRegisterError)
    -> PublicInspectionDocument
  {
    let request: DocumentRequest<PublicInspectionDocument>
    do { request = try .publicInspectionDocument(number) } catch { throw .validation(error) }
    return try await value(for: request)
  }

  /// Retrieves one inspection response, preserving source dates and partial errors.
  /// - Parameter date: A real Gregorian YYYY-MM-DD date.
  /// - Returns: The original source value; no PDF or referenced document is fetched.
  /// - Throws: `FederalRegisterError` for validation or execution failures.
  public func publicInspectionDocuments(availableOn date: String) async throws(FederalRegisterError)
    -> PublicInspectionListing
  {
    let request: DocumentRequest<PublicInspectionListing>
    do { request = try .publicInspectionDocuments(availableOn: date) } catch {
      throw .validation(error)
    }
    return try await value(for: request)
  }

  /// Creates a lazy inspection traversal; custom endpoint requests remain single-page.
  /// - Parameter request: A reusable search or custom endpoint request.
  /// - Returns: Independent iterators with no construction I/O or prefetch.
  public func publicInspectionDocuments(for request: DocumentRequest<PublicInspectionPage>)
    -> PublicInspectionSequence
  {
    PublicInspectionSequence(pages: publicInspectionPages(for: request))
  }

  /// Retrieves one inspection response, preserving source dates and partial errors.
  /// - Parameter numbers: The original nonempty identifiers.
  /// - Returns: The original source value; no PDF or referenced document is fetched.
  /// - Throws: `FederalRegisterError` for validation or execution failures.
  public func publicInspectionDocuments(numbered numbers: [String])
    async throws(FederalRegisterError) -> PublicInspectionBatch
  {
    let request: DocumentRequest<PublicInspectionBatch>
    do { request = try .publicInspectionDocuments(numbered: numbers) } catch {
      throw .validation(error)
    }
    return try await value(for: request)
  }

  /// Creates a lazy inspection search traversal preserving source order and duplicates.
  /// - Parameter query: Validated inspection filters.
  /// - Returns: A demand-driven sequence; cancellation is checked on every next call.
  public func publicInspectionDocuments(searching query: PublicInspectionQuery)
    -> PublicInspectionSequence
  {
    publicInspectionDocuments(for: .searchPublicInspectionDocuments(matching: query))
  }

  /// Creates a lazy inspection traversal; custom endpoint requests remain single-page.
  /// - Parameter request: A reusable search or custom endpoint request.
  /// - Returns: Independent iterators with no construction I/O or prefetch.
  public func publicInspectionPages(for request: DocumentRequest<PublicInspectionPage>)
    -> PublicInspectionPageSequence<PublicInspectionPage>
  {
    inspectionSequence(for: request, transform: { $0.value })
  }

  /// Creates a lazy inspection search traversal preserving source order and duplicates.
  /// - Parameter query: Validated inspection filters.
  /// - Returns: A demand-driven sequence; cancellation is checked on every next call.
  public func publicInspectionPages(searching query: PublicInspectionQuery)
    -> PublicInspectionPageSequence<PublicInspectionPage>
  {
    publicInspectionPages(for: .searchPublicInspectionDocuments(matching: query))
  }

  /// Creates a lazy inspection traversal; custom endpoint requests remain single-page.
  /// - Parameter request: A reusable search or custom endpoint request.
  /// - Returns: Independent iterators with no construction I/O or prefetch.
  public func publicInspectionResponses(for request: DocumentRequest<PublicInspectionPage>)
    -> PublicInspectionPageSequence<SourceResponse<PublicInspectionPage>>
  {
    inspectionSequence(for: request, transform: { $0 })
  }

  /// Creates a lazy inspection search traversal preserving source order and duplicates.
  /// - Parameter query: Validated inspection filters.
  /// - Returns: A demand-driven sequence; cancellation is checked on every next call.
  public func publicInspectionResponses(searching query: PublicInspectionQuery)
    -> PublicInspectionPageSequence<SourceResponse<PublicInspectionPage>>
  {
    publicInspectionResponses(for: .searchPublicInspectionDocuments(matching: query))
  }

  /// Retrieves only the first inspection search page.
  /// - Parameter query: Validated inspection filters.
  /// - Returns: The source search envelope.
  /// - Throws: `FederalRegisterError` for execution failures.
  public func searchPublicInspectionDocuments(matching query: PublicInspectionQuery)
    async throws(FederalRegisterError) -> PublicInspectionPage
  {
    try await value(for: .searchPublicInspectionDocuments(matching: query))
  }

  private func inspectionSequence<Value: Sendable>(
    for request: DocumentRequest<PublicInspectionPage>,
    transform: @escaping @Sendable (SourceResponse<PublicInspectionPage>) -> Value
  ) -> PublicInspectionPageSequence<Value> {
    let followsLinks: Bool
    switch request.resolution {
    case .publicInspectionSearch: followsLinks = true
    case .documentSearch, .endpoint, .presidentialDocuments: followsLinks = false
    }
    let base = client.pages(
      self.request(for: request.endpoint), as: SourceResponse<PublicInspectionPage>.self,
      decode: { response in try self.decode(response, as: PublicInspectionPage.self, path: "") }
    ) { page, sent in
      guard followsLinks, let endpoint = Endpoint<PublicInspectionPage>(path: sent.path),
        let following = try? page.value.value.continuation(after: endpoint)
      else { return nil }
      return .request(self.request(for: following))
    }
    return PublicInspectionPageSequence(
      base: base, endpoint: request.endpoint, followsLinks: followsLinks, transform: transform)
  }
}
