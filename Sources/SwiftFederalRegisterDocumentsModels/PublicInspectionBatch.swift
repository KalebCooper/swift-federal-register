#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A single public-inspection batch response in provider order, including partial errors.
///
/// No input-order reconstruction, duplicate expansion, chunking, or missing-record retry occurs.
/// A singleton detail response exposes one result and a nil count, while retaining the detail shape
/// when encoded. A missing singleton may instead produce an ordinary HTTP failure.
public struct PublicInspectionBatch: Codable, DocumentResponse, Hashable {
  /// The source count; nil for the provider's singleton detail shape.
  public let count: Int?
  /// The complete original object, including unknown values and partial errors.
  public let fields: [String: JSONValue]
  /// Documents in response order, without inventing a result for each requested identifier.
  public let results: [PublicInspectionDocument]

  /// Source partial errors; nil for absent, null, or incompatible values.
  public var errors: BatchLookupErrors? {
    fields["errors"]?.object.map(BatchLookupErrors.init(fields:))
  }

  private enum CodingKeys: String, CodingKey {
    case count
    case results
  }

  /// Decodes a batch envelope or a verified singleton detail shape.
  /// - Throws: `DecodingError` for malformed envelopes or missing required document fields.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.count) || container.contains(.results) {
      count = try container.decode(Int.self, forKey: .count)
      results = try container.decode([PublicInspectionDocument].self, forKey: .results)
    } else {
      count = nil
      results = [try PublicInspectionDocument(from: decoder)]
    }
  }

  /// Re-encodes the source object without manufacturing an envelope or count.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
