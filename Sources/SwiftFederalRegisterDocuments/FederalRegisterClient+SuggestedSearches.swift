import SwiftFederalRegisterDocumentsModels

extension FederalRegisterClient {
  /// Retrieves suggested-search metadata without interpreting or executing its conditions.
  /// - Parameter identifier: A safe open provider slug.
  /// - Returns: The source metadata, including raw search conditions and description markup.
  /// - Throws: `FederalRegisterError` for validation or execution failures.
  public func suggestedSearch(_ identifier: SuggestedSearchIdentifier)
    async throws(FederalRegisterError) -> SuggestedSearch
  {
    let request: DocumentRequest<SuggestedSearch>
    do { request = try .suggestedSearch(identifier) } catch { throw .validation(error) }
    return try await value(for: request)
  }

  /// Retrieves the catalog grouped by source section, preserving each group's array order.
  /// - Parameter section: Optional open section slug; nil requests the full catalog.
  /// - Returns: Discovery metadata only, with no hidden document requests.
  /// - Throws: `FederalRegisterError` for validation or execution failures.
  public func suggestedSearches(section: SectionIdentifier? = nil)
    async throws(FederalRegisterError) -> SuggestedSearchCatalog
  {
    let request: DocumentRequest<SuggestedSearchCatalog>
    do { request = try .suggestedSearches(section: section) } catch { throw .validation(error) }
    return try await value(for: request)
  }
}
