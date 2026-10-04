import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ExpandedRequestTests {
  @Test("Models-only consumer factories infer responses across discovery families")
  func consumerFactories() throws {
    let stored = try DocumentRequest.climateDiscovery()
    let contextual: DocumentRequest<SuggestedSearch> = try .climateDiscovery()
    #expect(stored == contextual)
    #expect(stored.endpoint.path == "/api/v1/suggested_searches/climate-change.json")
    let inspection = try DocumentRequest.regularInspection()
    #expect(inspection.resolution == .publicInspectionSearch(inspection.endpoint))
    #expect(
      inspection.endpoint.path
        == "/api/v1/public-inspection-documents.json?conditions%5Bspecial_filing%5D=0&per_page=20")
  }

  @Test("Custom response types use each new route without importing the SDK")
  func customResponses() throws {
    let captures: [(String, Fixture)] = [
      ("/api/v1/documents/93-32104,2024-31396.json", .batchPublished),
      ("/api/v1/documents/facets/agency", .facetsAgency),
      ("/api/v1/issues/2024-12-31.json", .issue),
      ("/api/v1/public-inspection-documents/current.json", .inspectionCurrent),
      ("/api/v1/public-inspection-documents/2026-19958.json", .inspectionDetail),
      ("/api/v1/public-inspection-documents.json", .inspectionSearch),
      ("/api/v1/suggested_searches.json", .suggestedCatalog),
      ("/api/v1/suggested_searches/climate-change.json", .suggestedDetail),
    ]
    for (path, fixture) in captures {
      let endpoint = try #require(Endpoint<ExpandedCustomResponse>(path: path))
      let request = DocumentRequest(endpoint: endpoint)
      #expect(request.endpoint == endpoint)
      let body = try fixture.data()
      let custom = try ExpandedCustomResponse.decode(body)
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(custom))
          == JSONDecoder().decode(JSONValue.self, from: body))
    }
  }
}

private struct ExpandedCustomResponse: Codable, DocumentResponse {
  let value: JSONValue

  init(from decoder: any Decoder) throws {
    value = try JSONValue(from: decoder)
  }

  func encode(to encoder: any Encoder) throws {
    try value.encode(to: encoder)
  }
}

extension DocumentRequest where Response == PublicInspectionPage {
  fileprivate static func regularInspection() throws -> Self {
    .searchPublicInspectionDocuments(matching: try PublicInspectionQuery(specialFiling: .regular))
  }
}

extension DocumentRequest where Response == SuggestedSearch {
  fileprivate static func climateDiscovery() throws -> Self {
    try .suggestedSearch(.init(rawValue: "climate-change"))
  }
}
