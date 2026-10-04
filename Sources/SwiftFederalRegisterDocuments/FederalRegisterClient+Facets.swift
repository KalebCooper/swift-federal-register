import SwiftFederalRegisterDocumentsModels

extension FederalRegisterClient {
  /// Retrieves source facet counts without interpreting them as complete coverage.
  /// - Parameters:
  ///   - facet: Provider grouping.
  ///   - query: Conditions only; fields, order, and page size do not affect this request.
  /// - Returns: Keyed buckets, not a ranked list or a page.
  /// - Throws: `FederalRegisterError` for execution failures.
  public func documentFacets(_ facet: DocumentFacet, matching query: DocumentSearchQuery)
    async throws(FederalRegisterError) -> DocumentFacetCounts
  {
    try await value(for: .documentFacets(facet, matching: query))
  }
}
