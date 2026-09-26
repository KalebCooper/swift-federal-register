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
  /// A next link supplies an empty or duplicate cursor, or carries neither a cursor nor a
  /// single integer page number.
  case missingCursor
  /// A page-number link does not advance past the current endpoint's page.
  case nonprogressingPage(Int)
  /// A cursor has already occurred in this traversal.
  case repeatedCursor(String)
}

extension DocumentPage {
  /// Validates the next provider link without using the capped page total as a limit.
  ///
  /// A link continues by exactly one nonempty `search_after_cursor` or, with no cursor, by a single
  /// integer `page` greater than the current endpoint's page, where an absent page is 1. Recorded
  /// term searches publish page-number links; other recorded searches publish cursors. Every other
  /// query item is compared as the provider parses it, reading `+` as a space before decoding
  /// percent escapes, so a published `clean+water` matches a sent `clean%20water`. The provider
  /// does not promise that a page-number link past its depth cap returns documents; only the links
  /// it publishes are followed, and no page is computed here.
  /// - Parameters:
  ///   - endpoint: The endpoint that produced this page.
  ///   - seenCursors: Every cursor already scheduled by this iterator.
  /// - Returns: The next independent endpoint and its opaque cursor, which is nil for a page-number
  ///   link, or nil for an absent or null next link.
  /// - Throws: `DocumentPaginationError.invalidLink` for an unsafe route, origin, or format,
  ///   `invalidMetadata` for a negative count or an empty continuing page, `missingCursor` for a
  ///   link with no usable cursor or page, `nonprogressingPage` for a same-or-lower page,
  ///   `repeatedCursor` for a cursor already seen, and `changedQuery` for changed filters.
  public func continuation(after endpoint: Endpoint<DocumentPage>, seenCursors: Set<String>)
    throws(DocumentPaginationError) -> (endpoint: Endpoint<DocumentPage>, cursor: String?)?
  {
    guard count >= 0, (totalPages ?? 0) >= 0 else { throw .invalidMetadata }
    guard let nextPageURL else { return nil }
    guard !results.isEmpty else { throw .invalidMetadata }
    guard let next = Endpoint<DocumentPage>(link: nextPageURL),
      let components = URLComponents(string: nextPageURL),
      components.path == "/api/v1/documents" || components.path == "/api/v1/documents.json",
      let current = URLComponents(string: "https://www.federalregister.gov" + endpoint.path)
    else { throw .invalidLink(nextPageURL) }
    let items = Self.formItems(components)
    let currentItems = Self.formItems(current)
    let cursors = items.filter { $0.name == "search_after_cursor" }
    let cursor: String?
    if cursors.isEmpty {
      guard let page = Self.pageNumber(in: items) else { throw .missingCursor }
      guard page > Self.pageNumber(in: currentItems) ?? 1 else { throw .nonprogressingPage(page) }
      cursor = nil
    } else {
      guard cursors.count == 1, let value = cursors.first?.value, !value.isEmpty else {
        throw .missingCursor
      }
      guard !seenCursors.contains(value) else { throw .repeatedCursor(value) }
      cursor = value
    }
    for item in items where item.name == "format" {
      guard item.value == "json" else { throw .invalidLink(nextPageURL) }
    }
    let ignored: Set<String> = ["format", "page", "search_after_cursor"]
    let filters: ([URLQueryItem]) -> [URLQueryItem] = { values in
      values.filter { !ignored.contains($0.name) }.sorted {
        ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "")
      }
    }
    guard filters(items) == filters(currentItems) else { throw .changedQuery }
    return (next, cursor)
  }

  /// Decodes a query as the provider's form parser does: `+` is a space, then escapes decode.
  private static func formItems(_ components: URLComponents) -> [URLQueryItem] {
    var decoded = components
    decoded.percentEncodedQuery = components.percentEncodedQuery?.replacing("+", with: "%20")
    return decoded.queryItems ?? []
  }

  /// The single integer `page` item, or nil when it is absent, repeated, or not an integer.
  private static func pageNumber(in items: [URLQueryItem]) -> Int? {
    let pages = items.filter { $0.name == "page" }
    guard pages.count == 1, let value = pages.first?.value else { return nil }
    return Int(value)
  }
}
