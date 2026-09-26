#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Validated presidential-document filters, with no product-era cutoff.
///
/// ```swift
/// let query = try DocumentQuery(pageSize: 2, publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
/// ```
public struct DocumentQuery: Hashable, Sendable {
  /// Chronological ordering supported by cursor traversal.
  public enum Order: String, Codable, Sendable {
    /// Most recently published first.
    case newest
    /// Earliest published first.
    case oldest
  }

  /// The requested chronological order.
  public let order: Order
  /// Number of results per response; the API documents 20 by default and 1000 maximum.
  public let pageSize: Int
  /// An open provider president identifier, or nil for all presidents.
  public let president: String?
  /// An open provider presidential-document-type identifier.
  public let presidentialDocumentType: String?
  /// Inclusive lower publication-date bound, or nil.
  public let publishedFrom: String?
  /// Inclusive upper publication-date bound, or nil.
  public let publishedThrough: String?

  /// Creates validated immutable filters; no request is sent.
  /// - Parameters:
  ///   - order: Chronological order, defaulting to newest first.
  ///   - pageSize: A value in 1...1000; defaults to the API's 20.
  ///   - president: Provider identifier; unknown values are sent unchanged.
  ///   - presidentialDocumentType: Provider type identifier; unknown values remain valid inputs.
  ///   - publishedFrom: Inclusive Gregorian YYYY-MM-DD lower bound.
  ///   - publishedThrough: Inclusive Gregorian YYYY-MM-DD upper bound.
  /// - Throws: `DocumentValidationError` for invalid page sizes or dates.
  public init(
    order: Order = .newest, pageSize: Int = 20, president: String? = nil,
    presidentialDocumentType: String? = nil, publishedFrom: String? = nil,
    publishedThrough: String? = nil
  ) throws(DocumentValidationError) {
    guard (1...1000).contains(pageSize) else { throw .invalidPageSize(pageSize) }
    for date in [publishedFrom, publishedThrough].compactMap({ $0 }) {
      guard GregorianDate.isValid(date) else { throw .invalidDate(date) }
    }
    if let publishedFrom, let publishedThrough, publishedFrom > publishedThrough {
      throw .reversedDates
    }
    self.order = order
    self.pageSize = pageSize
    self.president = president
    self.presidentialDocumentType = presidentialDocumentType
    self.publishedFrom = publishedFrom
    self.publishedThrough = publishedThrough
  }

  var queryItems: [URLQueryItem] {
    var items = [URLQueryItem(name: "conditions[type][]", value: "PRESDOCU")]
    if let president { items.append(.init(name: "conditions[president][]", value: president)) }
    if let presidentialDocumentType {
      items.append(
        .init(name: "conditions[presidential_document_type][]", value: presidentialDocumentType))
    }
    if let publishedFrom {
      items.append(.init(name: "conditions[publication_date][gte]", value: publishedFrom))
    }
    if let publishedThrough {
      items.append(.init(name: "conditions[publication_date][lte]", value: publishedThrough))
    }
    items.append(.init(name: "order", value: order.rawValue))
    items.append(.init(name: "per_page", value: String(pageSize)))
    return items.sorted { $0.name < $1.name }
  }
}
