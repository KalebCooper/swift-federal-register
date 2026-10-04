import Foundation
import HTTPCore
import HTTPTesting
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SuggestedSearchTests {
  @Test("Suggested catalog levels preserve group and item order without execution")
  func catalog() async throws {
    let body = try Fixture.suggestedSection.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let value = try await client.suggestedSearches(section: .environment)
    let request = try DocumentRequest.suggestedSearches(section: .environment)
    #expect(try await client.value(for: request) == value)
    #expect(try await client.send(.suggestedSearches(section: .environment)) == value)
    #expect(try await client.response(for: request).body == body)
    #expect(transport.requests.count == 4)
    #expect(
      transport.requests.allSatisfy {
        $0.request.path == "/api/v1/suggested_searches.json?conditions%5Bsections%5D=environment"
      })
    #expect(
      value.searchesBySection?["environment"]?.first?.slug?.rawValue
        == "endangered-threatened-species")
    let full = try SuggestedSearchCatalog.decode(Fixture.suggestedCatalog.data())
    #expect(full.searchesBySection?.count == 6)
    #expect(full.searchesBySection?["world"]?.first?.searchConditions != nil)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(full))
        == JSONDecoder().decode(JSONValue.self, from: Fixture.suggestedCatalog.data()))
  }

  @Test("Detail omits catalog counts and preserves markup and exact raw conditions")
  func detail() async throws {
    let body = try Fixture.suggestedDetail.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let id = SuggestedSearchIdentifier(rawValue: "climate-change")
    let value = try await client.suggestedSearch(id)
    let stored = try DocumentRequest.suggestedSearch(id)
    #expect(try await client.value(for: stored) == value)
    #expect(try await client.send(.suggestedSearch(id)) == value)
    #expect(try await client.response(for: stored).body == body)
    #expect(value.title == "Climate Change")
    #expect(value.documentsInLastYear == nil)
    #expect(value.position == nil)
    #expect(value.description?.hasPrefix("<p>") == true)
    #expect(
      value.searchConditions
        == .object(["term": .string("\"greenhouse gas\" | \"climate change\"")]))
    #expect(transport.requests.count == 4)
  }

  @Test("Unknown and incompatible synthetic groups preserve their raw values")
  func rawKinds() throws {
    let body = Data(
      #"{"future":[{"slug":"future","search_conditions":{"near":{"within":"25"}},"position":null}]}"#
        .utf8)
    let value = try SuggestedSearchCatalog.decode(body)
    #expect(value.searchesBySection?["future"]?.first?.position == nil)
    #expect(
      value.searchesBySection?["future"]?.first?.searchConditions
        == .object(["near": .object(["within": .string("25")])]))
    #expect(
      try SuggestedSearchCatalog.decode(Data(#"{"future":[{},null]}"#.utf8)).searchesBySection
        == nil)
  }

  @Test("Unsafe identifiers fail before transport", arguments: ["", "../x", "a/b", "a%2Fb", "a,b"])
  func validation(_ id: String) async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    do {
      _ = try await client.suggestedSearch(.init(rawValue: id)); Issue.record("Expected validation")
    } catch {
      guard case .validation(.invalidSuggestedSearchIdentifier) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(transport.requests.isEmpty)
    #expect(Endpoint<SuggestedSearch>(path: "/api/v1/suggested_searches/" + id + ".json") == nil)
    #expect(
      try Endpoint<SuggestedSearchCatalog>.suggestedSearches().path
        == "/api/v1/suggested_searches.json")
  }
}
