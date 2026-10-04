#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTypes
import SwiftFederalRegisterDocumentsModels

/// A Federal Register client with equivalent everyday, request, and endpoint operations.
///
/// No API key is needed. Application identity is explicit. Requests are sent once, with no
/// automatic redirects or retries. HTTP failures retain response bytes and Retry-After headers.
public struct FederalRegisterClient: Sendable {
  /// Maximum buffered body accepted for decoding and receipt retention, in bytes.
  /// This is checked after transport buffering; it is not a streaming download limit.
  public let maximumResponseBytes: Int
  /// The explicit application identity sent with each request.
  public let userAgent: String

  let client: HTTPClient
  private let retrievalTime: @Sendable () -> Date?

  /// Creates a client over a supplied transport.
  /// - Parameters:
  ///   - maximumResponseBytes: Positive decoding/receipt limit, defaulting to 8 MiB.
  ///   - retrievalTime: Optional caller clock for receipt instants; defaults to no timestamp.
  ///   - transport: The shared networking transport.
  ///   - userAgent: Your application identity and contact information.
  public init(
    maximumResponseBytes: Int = 8 * 1024 * 1024,
    retrievalTime: @escaping @Sendable () -> Date? = { nil }, transport: any Transport,
    userAgent: String
  ) {
    precondition(maximumResponseBytes > 0, "The response limit must be positive.")
    self.maximumResponseBytes = maximumResponseBytes
    self.retrievalTime = retrievalTime
    self.userAgent = userAgent
    self.client = HTTPClient(baseURL: Self.baseURL, redirectPolicy: .never, transport: transport)
  }

  /// Retrieves an advertised textual representation without inferring missing formats.
  /// - Parameters:
  ///   - representation: HTML, text, or XML source text.
  ///   - document: The document whose advertised link to request.
  /// - Returns: Lossless UTF-8 source, including markup where present.
  /// - Throws: `FederalRegisterError.content` for unavailable/invalid content, or execution failures.
  public func content(
    _ representation: DocumentRepresentation, for document: FederalRegisterDocument
  )
    async throws(FederalRegisterError) -> DocumentContent
  {
    let request: DocumentRequest<DocumentContent>
    do { request = try .content(representation, for: document) } catch { throw .content(error) }
    return try await value(for: request)
  }

  /// Retrieves one current or historical document by its original identifier.
  /// - Parameter number: The Federal Register document number.
  /// - Returns: Source fields, dates, and representation links without normalization.
  /// - Throws: `FederalRegisterError.validation` for invalid input, or execution failures.
  public func document(_ number: String) async throws(FederalRegisterError)
    -> FederalRegisterDocument
  {
    try await document(number, fields: [])
  }

  /// Retrieves selected source fields, including required identity and title.
  /// - Parameters:
  ///   - number: The original provider number.
  ///   - fields: Empty preserves defaults; nonempty adds document number and title.
  /// - Returns: Source fields without invented values.
  /// - Throws: `FederalRegisterError.validation` for invalid input, or execution failures.
  public func document(_ number: String, fields: [DocumentField])
    async throws(FederalRegisterError) -> FederalRegisterDocument
  {
    let request: DocumentRequest<FederalRegisterDocument>
    do { request = try .document(number, fields: fields) } catch { throw .validation(error) }
    return try await value(for: request)
  }

  /// Creates lazy pages for a reusable request; custom endpoint requests yield one page only.
  ///
  /// Library-created general and presidential search requests follow the provider's validated
  /// next links, by opaque cursor or by strictly increasing page number. A request created with
  /// `DocumentRequest.init(endpoint:)` yields its first page only, whatever its next link says.
  /// - Parameter request: A general search from `DocumentRequest.searchDocuments(matching:)`, a
  ///   presidential search from `DocumentRequest.presidentialDocuments(matching:)`, or a custom
  ///   single-page endpoint.
  /// - Returns: Independent demand-driven page traversals.
  public func documentPages(for request: DocumentRequest<DocumentPage>) -> DocumentPageSequence<
    DocumentPage
  > {
    sequence(for: request, transform: { $0.value })
  }

  /// Creates lazy presidential-document pages in provider order.
  /// - Parameter query: Validated filters and page size.
  /// - Returns: Pages fetched only on demand, without a capped-total stopping rule.
  public func documentPages(matching query: DocumentQuery) -> DocumentPageSequence<DocumentPage> {
    documentPages(for: .presidentialDocuments(matching: query))
  }

  /// Creates lazy page receipts with bytes corresponding to exactly the decoded response.
  ///
  /// Continuation follows the same rules as `documentPages(for:)`.
  /// - Parameter request: A general or presidential search request, or a custom single-page
  ///   endpoint.
  /// - Returns: Complete receipts without a duplicate fetch or prefetch.
  public func documentResponses(for request: DocumentRequest<DocumentPage>) -> DocumentPageSequence<
    SourceResponse<DocumentPage>
  > {
    sequence(for: request, transform: { $0 })
  }

  /// Creates lazy page receipts for a presidential query.
  /// - Parameter query: Validated presidential-document filters.
  /// - Returns: Original response bytes and metadata for every yielded page.
  public func documentResponses(matching query: DocumentQuery) -> DocumentPageSequence<
    SourceResponse<DocumentPage>
  > {
    documentResponses(for: .presidentialDocuments(matching: query))
  }

  /// Creates a lazy item view of a reusable request.
  ///
  /// Continuation follows the same rules as `documentPages(for:)`.
  /// - Parameter request: A general or presidential search request, or a custom single-page
  ///   endpoint.
  /// - Returns: Documents in source order, preserving duplicates.
  public func documents(for request: DocumentRequest<DocumentPage>) -> DocumentSequence {
    DocumentSequence(pages: documentPages(for: request))
  }

  /// Creates a lazy item traversal for presidential documents.
  /// - Parameter query: Validated filters and page size.
  /// - Returns: Documents drained from one page at a time, without prefetch.
  public func documents(matching query: DocumentQuery) -> DocumentSequence {
    documents(for: .presidentialDocuments(matching: query))
  }

  /// Retrieves one batch response, preserving provider order and partial errors.
  /// - Parameters:
  ///   - numbers: Nonempty original identifiers; duplicates are sent unchanged.
  ///   - fields: Empty preserves defaults; nonempty includes document number and title.
  /// - Returns: The source batch. A singleton retains its detail shape and nil count.
  /// - Throws: `FederalRegisterError.validation` for invalid input, or execution failures.
  public func documents(numbered numbers: [String], fields: [DocumentField] = [])
    async throws(FederalRegisterError) -> DocumentBatch
  {
    let request: DocumentRequest<DocumentBatch>
    do { request = try .documents(numbered: numbers, fields: fields) } catch {
      throw .validation(error)
    }
    return try await value(for: request)
  }

  /// Retrieves only the first presidential-document page.
  /// - Parameter query: Validated filters.
  /// - Returns: The original page envelope.
  /// - Throws: The same `FederalRegisterError` as request and endpoint execution.
  public func presidentialDocuments(matching query: DocumentQuery)
    async throws(FederalRegisterError) -> DocumentPage
  {
    try await value(for: .presidentialDocuments(matching: query))
  }

  /// Retrieves a value and its original response bytes in one request.
  /// - Parameter request: An inspectable document operation; a query retrieves one page.
  /// - Returns: A receipt retaining bytes, headers, status, URL, attribution, and optional retrieval time.
  /// - Throws: `FederalRegisterError` for transport, source decoding, cancellation, or size failures.
  public func response<Value: DocumentResponse>(for request: DocumentRequest<Value>)
    async throws(FederalRegisterError) -> SourceResponse<Value>
  {
    try await response(for: request.endpoint)
  }

  /// Retrieves a typed endpoint with a raw response receipt.
  /// - Parameter endpoint: The validated source operation.
  /// - Returns: The decoded value and exact response used to decode it.
  /// - Throws: `FederalRegisterError` for transport, decoding, cancellation, or size failures.
  public func response<Value: DocumentResponse>(for endpoint: Endpoint<Value>)
    async throws(FederalRegisterError) -> SourceResponse<Value>
  {
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    let response: Response
    do { response = try await client.execute(request(for: endpoint)) } catch {
      throw FederalRegisterError(error)
    }
    return try decode(response, as: Value.self, path: endpoint.path)
  }

  /// Executes one independent typed endpoint.
  /// - Parameter endpoint: The source operation to send.
  /// - Returns: Its decoded source value.
  /// - Throws: The same `FederalRegisterError` as receipt execution.
  public func send<Value: DocumentResponse>(_ endpoint: Endpoint<Value>)
    async throws(FederalRegisterError) -> Value
  {
    try await response(for: endpoint).value
  }

  /// Executes one reusable request, without automatically traversing search pages.
  /// - Parameter request: The source operation to execute once.
  /// - Returns: The concrete response inferred by the factory.
  /// - Throws: The same `FederalRegisterError` as endpoint execution.
  public func value<Value: DocumentResponse>(for request: DocumentRequest<Value>)
    async throws(FederalRegisterError) -> Value
  {
    try await send(request.endpoint)
  }

  func decode<Value: DocumentResponse>(
    _ response: Response, as type: Value.Type, path: String
  )
    throws(FederalRegisterError) -> SourceResponse<Value>
  {
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    guard response.body.count <= maximumResponseBytes else {
      throw .responseTooLarge(limit: maximumResponseBytes)
    }
    let value: Value
    do { value = try Value.decode(response.body) } catch let error as DocumentContentError {
      throw .content(error)
    } catch { throw .decoding(String(describing: error)) }
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    return SourceResponse(
      body: response.body,
      headers: response.headers.map { SourceHeader(name: $0.name.rawName, value: $0.value) },
      requestURL: "https://www.federalregister.gov" + path,
      retrievedAt: retrievalTime(), status: response.status.code, value: value)
  }

  func request<Value>(for endpoint: Endpoint<Value>) -> Request {
    Request(headers: [.accept: endpoint.accept, .userAgent: userAgent], path: endpoint.path)
  }

  private func sequence<Value: Sendable>(
    for request: DocumentRequest<DocumentPage>,
    transform: @escaping @Sendable (SourceResponse<DocumentPage>) -> Value
  ) -> DocumentPageSequence<Value> {
    let followsLinks: Bool
    switch request.resolution {
    case .endpoint, .publicInspectionSearch: followsLinks = false
    case .documentSearch, .presidentialDocuments: followsLinks = true
    }
    let base = client.pages(
      self.request(for: request.endpoint), as: SourceResponse<DocumentPage>.self,
      decode: { response in try self.decode(response, as: DocumentPage.self, path: "") }
    ) { page, sent in
      guard followsLinks, let endpoint = Endpoint<DocumentPage>(path: sent.path),
        let following = try? page.value.value.continuation(after: endpoint, seenCursors: [])
      else { return nil }
      return .request(self.request(for: following.endpoint))
    }
    return DocumentPageSequence(
      base: base, endpoint: request.endpoint, followsLinks: followsLinks, transform: transform)
  }

  private static let baseURL: URL = {
    guard let url = URL(string: "https://www.federalregister.gov") else {
      preconditionFailure("The fixed Federal Register HTTPS origin is a valid URL.")
    }
    return url
  }()
}
