#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A header field captured without combining duplicate fields.
public struct SourceHeader: Codable, Hashable, Sendable {
  /// The original HTTP field name as exposed by the transport.
  public let name: String
  /// The field value.
  public let value: String
  /// Creates one receipt header.
  public init(name: String, value: String) { self.name = name; self.value = value }
}

/// A decoded value and the exact successful response from the same request.
///
/// Bodies are retained without a second fetch. No retrieval instant is invented: callers can supply
/// a receipt clock to the client. Header names follow the transport's HTTP normalization.
public struct SourceResponse<Value: Sendable>: Sendable {
  /// The original buffered response bytes, suitable for hashing and replay.
  public let body: Data
  /// All response fields, retaining duplicates.
  public let headers: [SourceHeader]
  /// Publisher attribution, separate from the issuing agency or president.
  public let publisher: String
  /// The requested URL; redirects are refused by the SDK.
  public let requestURL: String
  /// The caller-supplied retrieval instant, or nil when no clock is provided.
  public let retrievedAt: Date?
  /// The HTTP status code.
  public let status: Int
  /// The value decoded from `body`.
  public let value: Value

  /// Creates a receipt from one response, without transforming its body.
  public init(
    body: Data, headers: [SourceHeader], requestURL: String, retrievedAt: Date?, status: Int,
    value: Value
  ) {
    self.body = body
    self.headers = headers
    self.publisher = "Office of the Federal Register, NARA; Government Publishing Office"
    self.requestURL = requestURL
    self.retrievedAt = retrievedAt
    self.status = status
    self.value = value
  }
}
