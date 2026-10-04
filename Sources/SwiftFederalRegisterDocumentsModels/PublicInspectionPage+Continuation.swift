#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension PublicInspectionPage {
  /// Validates a provider page link while preserving the search-condition multiset.
  /// Only verified search aliases are accepted; cursor parameters are rejected.
  /// - Parameter endpoint: The endpoint that returned this page.
  /// - Returns: The next endpoint, or nil for an absent/null link.
  /// - Throws: `DocumentPaginationError` for unsafe routes, changed conditions, nonprogressing pages,
  ///   invalid metadata, unexpected cursors, or conflicting/duplicate routing parameters.
  public func continuation(after endpoint: Endpoint<PublicInspectionPage>)
    throws(DocumentPaginationError) -> Endpoint<PublicInspectionPage>?
  {
    guard count >= 0, (totalPages ?? 0) >= 0 else { throw .invalidMetadata }
    guard let nextPageURL else { return nil }
    guard !results.isEmpty else { throw .invalidMetadata }
    guard let next = Endpoint<PublicInspectionPage>(link: nextPageURL),
      let parts = URLComponents(string: nextPageURL),
      let current = URLComponents(string: "https://www.federalregister.gov" + endpoint.path),
      Self.searchPaths.contains(parts.path), Self.searchPaths.contains(current.path)
    else { throw .invalidLink(nextPageURL) }
    let items = Self.formItems(parts)
    let currentItems = Self.formItems(current)
    try Self.validateRouting(items, path: parts.path, link: nextPageURL)
    try Self.validateRouting(currentItems, path: current.path, link: endpoint.path)
    guard let page = Self.pageNumber(items) else { throw .missingCursor }
    let previous: Int
    if currentItems.contains(where: { $0.name == "page" }) {
      guard let number = Self.pageNumber(currentItems) else { throw .nonprogressingPage(page) }
      previous = number
    } else {
      previous = 1
    }
    guard page > previous else { throw .nonprogressingPage(page) }
    let excluded: Set<String> = ["action", "controller", "format", "page"]
    let conditions: ([URLQueryItem]) -> [URLQueryItem] = {
      $0.filter { !excluded.contains($0.name) }.sorted {
        ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "")
      }
    }
    guard conditions(items) == conditions(currentItems) else { throw .changedQuery }
    return next
  }

  private static let searchPaths: Set<String> = [
    "/api/v1/public-inspection-documents", "/api/v1/public-inspection-documents.json",
    "/api/v1/public_inspection_documents", "/api/v1/public_inspection_documents.json",
  ]

  private static func formItems(_ components: URLComponents) -> [URLQueryItem] {
    var decoded = components
    decoded.percentEncodedQuery = components.percentEncodedQuery?.replacing("+", with: "%20")
    return decoded.queryItems ?? []
  }

  private static func pageNumber(_ items: [URLQueryItem]) -> Int? {
    let values = items.filter { $0.name == "page" }
    guard values.count == 1, let value = values.first?.value, !value.isEmpty,
      value.utf8.allSatisfy({ (48...57).contains($0) }), let number = Int(value), number >= 1
    else { return nil }
    return number
  }

  private static func validateRouting(_ items: [URLQueryItem], path: String, link: String)
    throws(DocumentPaginationError)
  {
    guard !items.contains(where: { $0.name == "search_after_cursor" }) else {
      throw .invalidLink(link)
    }
    for (key, expected) in [
      ("action", "index"), ("controller", "api/v1/public_inspection_documents"), ("format", "json"),
    ] {
      let values = items.filter { $0.name == key }
      guard values.count <= 1, values.allSatisfy({ $0.value == expected }) else {
        throw .invalidLink(link)
      }
      if key != "format", !values.isEmpty, !path.hasPrefix("/api/v1/public_inspection_documents") {
        throw .invalidLink(link)
      }
    }
  }
}
