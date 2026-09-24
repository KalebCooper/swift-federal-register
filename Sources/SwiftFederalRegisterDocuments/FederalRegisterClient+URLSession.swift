#if canImport(Darwin)
import Foundation
import HTTPURLSession

extension FederalRegisterClient {
  /// Creates a client using Apple's URLSession transport.
  /// - Parameters:
  ///   - maximumResponseBytes: The positive buffered decoding/receipt limit.
  ///   - retrievalTime: A caller clock for optional receipt timestamps.
  ///   - session: The session to use; defaults to the shared session.
  ///   - userAgent: Your explicit application identity and contact.
  public init(
    maximumResponseBytes: Int = 8 * 1024 * 1024,
    retrievalTime: @escaping @Sendable () -> Date? = { nil }, session: URLSession = .shared,
    userAgent: String
  ) {
    self.init(
      maximumResponseBytes: maximumResponseBytes, retrievalTime: retrievalTime,
      transport: URLSessionTransport(session: session), userAgent: userAgent)
  }
}
#endif
