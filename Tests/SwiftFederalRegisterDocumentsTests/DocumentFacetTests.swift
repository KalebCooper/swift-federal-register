import Foundation
import HTTPCore
import HTTPTesting
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DocumentFacetTests {
  @Test(
    "All captured groupings retain keyed buckets",
    arguments: [
      Fixture.facetsAgency, .facetsDaily, .facetsMonthlyYear, .facetsQuarterly, .facetsSection,
      .facetsSubtypeYear, .facetsTopic, .facetsType, .facetsWeekly, .facetsYearly,
    ])
  func buckets(_ fixture: Fixture) throws {
    let body = try fixture.data()
    let value = try DocumentFacetCounts.decode(body)
    #expect(try #require(value.buckets).isEmpty == false)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
        == JSONDecoder().decode(JSONValue.self, from: body))
  }

  @Test("Facet execution excludes presentation parameters and preserves topic evidence")
  func equivalence() async throws {
    let body = try Fixture.facetsTopicFilter.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let query = try DocumentSearchQuery(
      fields: [.significant], order: .oldest, pageSize: 2,
      topics: [.init(rawValue: "air-pollution-control")])
    let value = try await client.documentFacets(.type, matching: query)
    let request = DocumentRequest.documentFacets(.type, matching: query)
    #expect(try await client.value(for: request) == value)
    #expect(try await client.send(.documentFacets(.type, matching: query)) == value)
    #expect(try await client.response(for: request).body == body)
    #expect(transport.requests.count == 4)
    #expect(
      transport.requests.allSatisfy {
        $0.request.path
          == "/api/v1/documents/facets/type?conditions%5Btopics%5D%5B%5D=air-pollution-control"
      })
  }

  @Test("Empty and malformed synthetic bucket kinds stay distinct")
  func rawKinds() throws {
    #expect(try DocumentFacetCounts.decode(Fixture.facetsEmpty.data()).buckets == [:])
    let value = try DocumentFacetCounts.decode(
      Data(#"{"future":{"count":1.5,"name":null,"extra":false}}"#.utf8))
    #expect(value.buckets?["future"]?.count == nil)
    #expect(value.buckets?["future"]?.fields["extra"] == .bool(false))
    #expect(try DocumentFacetCounts.decode(Data(#"{"future":null}"#.utf8)).buckets == nil)
  }
}
