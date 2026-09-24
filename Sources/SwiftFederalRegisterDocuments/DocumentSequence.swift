import SwiftFederalRegisterDocumentsModels

/// Documents flattened lazily from one source page at a time.
///
/// Order and duplicates are preserved. Cancellation is checked while draining buffered items.
public struct DocumentSequence: AsyncSequence, Sendable {
  /// A source document, including its full original fields.
  public typealias Element = FederalRegisterDocument
  /// The typed service failure.
  public typealias Failure = FederalRegisterError

  /// An independent item iterator.
  public struct Iterator: AsyncIteratorProtocol {
    /// One source document.
    public typealias Element = FederalRegisterDocument
    /// The typed service failure.
    public typealias Failure = FederalRegisterError

    private var current = [FederalRegisterDocument]().makeIterator()
    private var finished = false
    private var pages: DocumentPageSequence<DocumentPage>.Iterator

    init(pages: DocumentPageSequence<DocumentPage>.Iterator) { self.pages = pages }

    /// Yields one item, requesting a page only after buffered items are exhausted.
    /// - Returns: The next document, or nil after completion or failure.
    /// - Throws: `FederalRegisterError`, including cancellation while items remain buffered.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(FederalRegisterError) -> FederalRegisterDocument?
    {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      if let document = current.next() { finished = false; return document }
      while let page = try await pages.next(isolation: actor) {
        current = page.results.makeIterator()
        if let document = current.next() { finished = false; return document }
      }
      return nil
    }
  }

  private let pages: DocumentPageSequence<DocumentPage>
  init(pages: DocumentPageSequence<DocumentPage>) { self.pages = pages }

  /// Creates a new traversal without fetching or prefetching.
  /// - Returns: An independent item iterator.
  public func makeAsyncIterator() -> Iterator { Iterator(pages: pages.makeAsyncIterator()) }
}
