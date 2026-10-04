#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One daily issue's source hierarchy, without automatic document hydration.
/// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
public struct IssueTableOfContents: Codable, DocumentResponse, Hashable, Sendable {
  /// One issue agency group, distinct from the agency catalog.
  /// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
  public struct Agency: Codable, Hashable, Sendable {
    /// Every source member, including unknown fields and explicit nulls.
    public let fields: [String: JSONValue]

    /// Source `document_categories`, without invented defaults or normalization.
    public var documentCategories: [Category]? {
      fields["document_categories"]?.objectArray?.map(Category.init(fields:))
    }
    /// Source `name`, without invented defaults or normalization.
    public var name: String? { fields["name"]?.string }
    /// Source `see_also`, without invented defaults or normalization.
    public var seeAlso: [SeeAlsoReference]? {
      fields["see_also"]?.objectArray?.map(SeeAlsoReference.init(fields:))
    }
    /// Source `slug`, without invented defaults or normalization.
    public var slug: String? { fields["slug"]?.string }

    init(fields: [String: JSONValue]) { self.fields = fields }

    /// Decodes the complete source object.
    public init(from decoder: any Decoder) throws {
      fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    /// Encodes the complete source object without normalizing projected values.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(fields)
    }
  }
  /// One source document-type group.
  /// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
  public struct Category: Codable, Hashable, Sendable {
    /// Every source member, including unknown fields and explicit nulls.
    public let fields: [String: JSONValue]

    /// Source `documents`, without invented defaults or normalization.
    public var documents: [Entry]? { fields["documents"]?.objectArray?.map(Entry.init(fields:)) }
    /// Source `type`, without invented defaults or normalization.
    public var type: String? { fields["type"]?.string }

    init(fields: [String: JSONValue]) { self.fields = fields }

    /// Decodes the complete source object.
    public init(from decoder: any Decoder) throws {
      fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    /// Encodes the complete source object without normalizing projected values.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(fields)
    }
  }
  /// One source subject entry referencing one or more documents.
  /// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
  public struct Entry: Codable, Hashable, Sendable {
    /// Every source member, including unknown fields and explicit nulls.
    public let fields: [String: JSONValue]

    /// Source `document_numbers`, without invented defaults or normalization.
    public var documentNumbers: [String]? { fields["document_numbers"]?.stringArray }
    /// Source `subject_1`, without invented defaults or normalization.
    public var subject1: String? { fields["subject_1"]?.string }
    /// Source `subject_2`, without invented defaults or normalization.
    public var subject2: String? { fields["subject_2"]?.string }

    init(fields: [String: JSONValue]) { self.fields = fields }

    /// Decodes the complete source object.
    public init(from decoder: any Decoder) throws {
      fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    /// Encodes the complete source object without normalizing projected values.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(fields)
    }
  }
  /// Source issue metadata, without inferring publication from absence.
  /// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
  public struct Metadata: Codable, Hashable, Sendable {
    /// Every source member, including unknown fields and explicit nulls.
    public let fields: [String: JSONValue]

    /// Source `publication_date`, without invented defaults or normalization.
    public var publicationDate: String? { fields["publication_date"]?.string }

    init(fields: [String: JSONValue]) { self.fields = fields }

    /// Decodes the complete source object.
    public init(from decoder: any Decoder) throws {
      fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    /// Encodes the complete source object without normalizing projected values.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(fields)
    }
  }
  /// An agency reference exactly as supplied.
  /// Optional projections preserve incompatible kinds in `fields`; encoding retains the source object.
  public struct SeeAlsoReference: Codable, Hashable, Sendable {
    /// Every source member, including unknown fields and explicit nulls.
    public let fields: [String: JSONValue]

    /// Source `name`, without invented defaults or normalization.
    public var name: String? { fields["name"]?.string }
    /// Source `slug`, without invented defaults or normalization.
    public var slug: String? { fields["slug"]?.string }

    init(fields: [String: JSONValue]) { self.fields = fields }

    /// Decodes the complete source object.
    public init(from decoder: any Decoder) throws {
      fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    /// Encodes the complete source object without normalizing projected values.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(fields)
    }
  }

  /// Every source member, including unknown fields and explicit nulls.
  public let fields: [String: JSONValue]

  /// Source `agencies`, without invented defaults or normalization.
  public var agencies: [Agency]? { fields["agencies"]?.objectArray?.map(Agency.init(fields:)) }
  /// Source `meta`, without invented defaults or normalization.
  public var meta: Metadata? { fields["meta"]?.object.map(Metadata.init(fields:)) }

  init(fields: [String: JSONValue]) { self.fields = fields }

  /// Decodes the complete source object.
  public init(from decoder: any Decoder) throws {
    fields = try decoder.singleValueContainer().decode([String: JSONValue].self)
  }

  /// Encodes the complete source object without normalizing projected values.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(fields)
  }
}
