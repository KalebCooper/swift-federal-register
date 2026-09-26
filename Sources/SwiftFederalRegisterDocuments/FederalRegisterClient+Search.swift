import SwiftFederalRegisterDocumentsModels

extension FederalRegisterClient {
  /// Creates lazy general-search pages that follow the provider's validated next links.
  ///
  /// No request is sent until an iterator asks for its first page, and no page is prefetched.
  /// Each page's next link is validated for origin, route, credentials, fragment, and an
  /// unchanged query before it is followed; a link carrying an opaque `search_after_cursor` or a
  /// strictly increasing `page` continues the sequence, and a missing link ends it. A zero-match
  /// search yields one empty page. The provider caps its page depth and promises no stable
  /// snapshot between pages. The presidential sibling is `documentPages(matching:)`, which takes a
  /// `DocumentQuery`.
  ///
  /// ```swift
  /// let pages = client.documentPages(
  ///   searching: try DocumentSearchQuery(agencies: [.environmentalProtectionAgency]))
  /// for try await page in pages { print(page.count, page.results.count) }
  /// ```
  ///
  /// - Parameter query: Validated general search filters, order, and page size.
  /// - Returns: Independent demand-driven page traversals, equal to `documentPages(for:)` with
  ///   `DocumentRequest.searchDocuments(matching:)`.
  public func documentPages(searching query: DocumentSearchQuery) -> DocumentPageSequence<
    DocumentPage
  > {
    documentPages(for: .searchDocuments(matching: query))
  }

  /// Creates lazy general-search page receipts with the exact bytes each page was decoded from.
  ///
  /// Every receipt retains the response body, headers, status, request URL, OFR/NARA and GPO
  /// attribution, and the caller's optional retrieval time, without a second fetch. Continuation
  /// follows the same validated cursor or page-number links as `documentPages(searching:)`. The
  /// presidential sibling is `documentResponses(matching:)`, which takes a `DocumentQuery`.
  ///
  /// ```swift
  /// for try await receipt in client.documentResponses(
  ///   searching: try DocumentSearchQuery(term: "clean water"))
  /// {
  ///   print(receipt.requestURL, receipt.body.count)
  /// }
  /// ```
  ///
  /// - Parameter query: Validated general search filters, order, and page size.
  /// - Returns: Original response bytes and metadata for every yielded page, equal to
  ///   `documentResponses(for:)` with `DocumentRequest.searchDocuments(matching:)`.
  public func documentResponses(searching query: DocumentSearchQuery) -> DocumentPageSequence<
    SourceResponse<DocumentPage>
  > {
    documentResponses(for: .searchDocuments(matching: query))
  }

  /// Creates a lazy item traversal over the documents a general search returns.
  ///
  /// Documents are drained from one page at a time in provider order, duplicates included, and
  /// the next page is requested only after the buffered items are exhausted. Cancellation is
  /// checked before every request and while draining. A zero-match search yields nothing. Only
  /// the fields the provider includes in search results are present; a search result never
  /// triggers a detail fetch. The presidential sibling is `documents(matching:)`, which takes a
  /// `DocumentQuery`.
  ///
  /// ```swift
  /// for try await document in client.documents(
  ///   searching: try DocumentSearchQuery(types: [.rule]))
  /// {
  ///   print(document.documentNumber)
  /// }
  /// ```
  ///
  /// - Parameter query: Validated general search filters, order, and page size.
  /// - Returns: Documents in source order, equal to `documents(for:)` with
  ///   `DocumentRequest.searchDocuments(matching:)`.
  public func documents(searching query: DocumentSearchQuery) -> DocumentSequence {
    documents(for: .searchDocuments(matching: query))
  }

  /// Retrieves only the first page of a general document search.
  ///
  /// One request is sent and its next link is not followed. A zero-match search returns an empty
  /// page whose `count` is 0. The presidential sibling is `presidentialDocuments(matching:)`, which
  /// takes a `DocumentQuery` and adds the provider's presidential type condition; this method adds
  /// no condition of its own.
  ///
  /// ```swift
  /// let page = try await client.searchDocuments(
  ///   matching: try DocumentSearchQuery(
  ///     publicationDate: .range(from: "2024-01-01", through: "2024-12-31")))
  /// ```
  ///
  /// - Parameter query: Validated general search filters, order, and page size.
  /// - Returns: The original page envelope, equal to `value(for:)` with
  ///   `DocumentRequest.searchDocuments(matching:)` and `send(_:)` with
  ///   `Endpoint<DocumentPage>.searchDocuments(matching:)`.
  /// - Throws: `FederalRegisterError.transport` for HTTP, transport, or cancellation failures,
  ///   `FederalRegisterError.responseTooLarge` above the client's limit, or
  ///   `FederalRegisterError.decoding` when the body is not a document page.
  public func searchDocuments(matching query: DocumentSearchQuery)
    async throws(FederalRegisterError) -> DocumentPage
  {
    try await value(for: .searchDocuments(matching: query))
  }
}
