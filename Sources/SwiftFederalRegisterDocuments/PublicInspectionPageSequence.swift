#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import SwiftFederalRegisterDocumentsModels

/// Lazy inspection pages or receipts, fetched by swifty-networking's PageSequence.
///
/// Each iterator starts independently, requests one page on demand, and validates continuation
/// before yielding. Breaking iteration sends no further request. A failure ends that iterator.
public struct PublicInspectionPageSequence<Value: Sendable>: AsyncSequence, Sendable {
  /// The selected page or receipt view.
  public typealias Element = Value
  /// Every failure is a typed service error.
  public typealias Failure = FederalRegisterError

  /// One independent traversal over the provider's page-number links.
  public struct Iterator: AsyncIteratorProtocol {
    /// The selected page or receipt view.
    public typealias Element = Value
    /// The typed failure shared by all SDK entry points.
    public typealias Failure = FederalRegisterError

    private var base: PageSequence<SourceResponse<PublicInspectionPage>>.Iterator
    private var endpoint: Endpoint<PublicInspectionPage>
    private var finished = false
    private let followsLinks: Bool
    private let transform: @Sendable (SourceResponse<PublicInspectionPage>) -> Value

    init(
      base: PageSequence<SourceResponse<PublicInspectionPage>>.Iterator,
      endpoint: Endpoint<PublicInspectionPage>,
      followsLinks: Bool,
      transform: @escaping @Sendable (SourceResponse<PublicInspectionPage>) -> Value
    ) {
      self.base = base
      self.endpoint = endpoint
      self.followsLinks = followsLinks
      self.transform = transform

    }

    /// Fetches and validates one page, or ends after completion or any failure.
    /// - Returns: The next complete page or its receipt.
    /// - Throws: `FederalRegisterError.pagination` for unusable continuation, or execution failures.
    public mutating func next(isolation actor: isolated (any Actor)? = #isolation)
      async throws(FederalRegisterError) -> Value?
    {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      let captured: SourceResponse<PublicInspectionPage>
      do throws(TransportError) {
        guard let page = try await base.next(isolation: actor) else { return nil }
        captured = page.value
      } catch { throw FederalRegisterError(error) }
      let receipt = SourceResponse(
        body: captured.body, headers: captured.headers,
        requestURL: "https://www.federalregister.gov" + endpoint.path,
        retrievedAt: captured.retrievedAt,
        status: captured.status, value: captured.value)
      if followsLinks {
        do {
          if let following = try captured.value.continuation(
            after: endpoint)
          {
            endpoint = following
            finished = false
          }
        } catch { throw .pagination(error) }
      }
      guard !Task.isCancelled else {
        finished = true
        throw .transport(.cancelled)
      }
      return transform(receipt)
    }
  }

  private let base: PageSequence<SourceResponse<PublicInspectionPage>>
  private let endpoint: Endpoint<PublicInspectionPage>
  private let followsLinks: Bool
  private let transform: @Sendable (SourceResponse<PublicInspectionPage>) -> Value

  init(
    base: PageSequence<SourceResponse<PublicInspectionPage>>,
    endpoint: Endpoint<PublicInspectionPage>,
    followsLinks: Bool,
    transform: @escaping @Sendable (SourceResponse<PublicInspectionPage>) -> Value
  ) {
    self.base = base
    self.endpoint = endpoint
    self.followsLinks = followsLinks
    self.transform = transform
  }

  /// Creates an independent traversal without fetching a page.
  /// - Returns: An iterator at the initial endpoint, before any request is sent.
  public func makeAsyncIterator() -> Iterator {
    Iterator(
      base: base.makeAsyncIterator(), endpoint: endpoint, followsLinks: followsLinks,
      transform: transform)
  }
}
