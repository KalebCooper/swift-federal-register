import Foundation
import HTTPCore
import HTTPTesting
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DocumentBatchTests {
  @Test("Batch calls share one-fetch execution and retain partial errors")
  func equivalence() async throws {
    let body = try Fixture.batchMissingDuplicate.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let numbers = ["2024-31396", "9999-99999", "2024-31396"]
    let value = try await client.documents(numbered: numbers)
    let stored = try DocumentRequest.documents(numbered: numbers)
    #expect(try await client.value(for: stored) == value)
    #expect(try await client.send(.documents(numbered: numbers)) == value)
    let receipt = try await client.response(for: stored)
    #expect(receipt.body == body)
    #expect(value.count == 1)
    #expect(value.results.map(\.documentNumber) == ["2024-31396"])
    #expect(value.errors?.notFound == ["9999-99999"])
    #expect(transport.requests.count == 4)
    #expect(
      transport.requests.allSatisfy {
        $0.request.path == "/api/v1/documents/2024-31396,9999-99999,2024-31396.json"
      })
  }

  @Test("Invalid batches never send", arguments: [[], [""], ["a/b"], ["a,b"], ["%2F"]])
  func invalid(_ numbers: [String]) async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    do {
      _ = try await client.documents(numbered: numbers)
      Issue.record("Expected validation")
    } catch {
      guard case .validation = error else { Issue.record("Wrong failure"); return }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Malformed synthetic envelopes cannot fall back to singleton")
  func malformed() throws {
    for json in [
      #"{"count":0}"#, #"{"results":[]}"#, #"{"count":null,"results":[]}"#,
      #"{"count":1,"results":null,"document_number":"x","title":"y"}"#, "{}",
    ] {
      #expect(throws: (any Error).self) { try DocumentBatch.decode(Data(json.utf8)) }
    }
  }

  @Test("Captured batch order, all-missing and singleton shapes survive round trips")
  func shapes() throws {
    let forward = try DocumentBatch.decode(Fixture.batchPublished.data())
    let reverse = try DocumentBatch.decode(Fixture.publishedBatchReverseFields.data())
    #expect(forward.results.map(\.documentNumber) == reverse.results.map(\.documentNumber))
    let empty = try DocumentBatch.decode(Fixture.publishedBatchAllMissing.data())
    #expect(empty.count == 0)
    #expect(empty.results.isEmpty)
    #expect(empty.errors?.notFound?.isEmpty == false)
    let body = try Fixture.publishedBatchSingle.data()
    let singleton = try DocumentBatch.decode(body)
    #expect(singleton.count == nil)
    #expect(singleton.results.map(\.documentNumber) == ["2024-31396"])
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(singleton))
        == JSONDecoder().decode(JSONValue.self, from: body))
    #expect(
      try Endpoint<DocumentBatch>.documents(numbered: ["93-32104"]).path
        == "/api/v1/documents/93-32104.json")
  }
}
