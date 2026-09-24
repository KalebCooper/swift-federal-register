// Public initializers and failures name Transport and TransportError.
@_exported import HTTPCore
import SwiftFederalRegisterDocumentsModels

/// A typed failure from any Federal Register execution level.
public enum FederalRegisterError: Error, Sendable {
  /// A requested representation is absent, invalid, or not UTF-8.
  case content(DocumentContentError)
  /// Source decoding failed; original HTTP errors instead retain their status, body, and fields.
  case decoding(String)
  /// The provider's continuation is unusable; this iterator terminates.
  case pagination(DocumentPaginationError)
  /// The buffered response exceeded the client's decoding and receipt size limit.
  case responseTooLarge(limit: Int)
  /// Transport, HTTP status, or cancellation failure, including Retry-After headers.
  case transport(TransportError)
  /// Input validation failed before sending.
  case validation(DocumentValidationError)

  init(_ error: TransportError) {
    if case .decode(let underlying) = error, let service = underlying as? Self {
      self = service
    } else {
      self = .transport(error)
    }
  }
}
