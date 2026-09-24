#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A source-specific decoder usable without a networking dependency.
///
/// Codable custom JSON responses need only declare conformance. Content responses can implement
/// their own decoder without pretending that JSONDecoder reads XML or HTML.
public protocol DocumentResponse: Sendable, SendableMetatype {
  /// Decodes a downloaded body without making any request.
  /// - Parameter data: The original response bytes.
  /// - Returns: The source value.
  /// - Throws: A decoding error for malformed or unsupported content.
  static func decode(_ data: Data) throws -> Self
}

extension DocumentResponse where Self: Decodable {
  /// Decodes Federal Register JSON with unchanged provider keys and string dates.
  /// - Parameter data: UTF-8 JSON response bytes.
  /// - Returns: The decoded value.
  /// - Throws: `DecodingError` for incompatible JSON.
  public static func decode(_ data: Data) throws -> Self {
    try JSONDecoder().decode(Self.self, from: data)
  }
}
