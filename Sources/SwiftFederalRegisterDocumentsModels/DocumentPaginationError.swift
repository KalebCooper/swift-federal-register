#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An unusable provider continuation; earlier pages are not a complete result set.
public enum DocumentPaginationError: Error, Hashable, Sendable {
  /// A link changes filters, order, or page size.
  case changedQuery
  /// The continuation route, origin, or query encoding is invalid.
  case invalidLink(String)
  /// The count is negative or an empty page advertises more data.
  case invalidMetadata
  /// A next link omits its cursor or supplies an empty or duplicate cursor parameter.
  case missingCursor
  /// A cursor has already occurred in this traversal.
  case repeatedCursor(String)
}

extension DocumentPage {
  /// Validates the next provider cursor without using the capped page total as a limit.
  /// - Parameters:
  ///   - endpoint: The endpoint that produced this page.
  ///   - seenCursors: Every cursor already scheduled by this iterator.
  /// - Returns: The next independent endpoint and opaque cursor, or nil for an absent/null link.
  /// - Throws: `DocumentPaginationError` for unsafe links, changed filters, or nonprogress.
  public func continuation(after endpoint: Endpoint<DocumentPage>, seenCursors: Set<String>)
    throws(DocumentPaginationError) -> (endpoint: Endpoint<DocumentPage>, cursor: String)?
  {
    guard count >= 0, totalPages >= 0 else { throw .invalidMetadata }
    guard let nextPageURL else { return nil }
    guard !results.isEmpty else { throw .invalidMetadata }
    guard let next = Endpoint<DocumentPage>(link: nextPageURL),
      let components = URLComponents(string: nextPageURL),
      components.path == "/api/v1/documents" || components.path == "/api/v1/documents.json",
      let current = URLComponents(string: "https://www.federalregister.gov" + endpoint.path)
    else { throw .invalidLink(nextPageURL) }
    let items = components.queryItems ?? []
    let cursors = items.filter { $0.name == "search_after_cursor" }
    guard cursors.count == 1, let cursor = cursors.first?.value, !cursor.isEmpty else {
      throw .missingCursor
    }
    guard !seenCursors.contains(cursor) else { throw .repeatedCursor(cursor) }
    for item in items where item.name == "format" {
      guard item.value == "json" else { throw .invalidLink(nextPageURL) }
    }
    let ignored: Set<String> = ["format", "page", "search_after_cursor"]
    let filters: ([URLQueryItem]) -> [URLQueryItem] = { values in
      values.filter { !ignored.contains($0.name) }.sorted {
        ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "")
      }
    }
    guard filters(items) == filters(current.queryItems ?? []) else { throw .changedQuery }
    return (next, cursor)
  }
}
