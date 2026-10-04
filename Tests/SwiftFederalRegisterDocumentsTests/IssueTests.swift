import Foundation
import HTTPCore
import HTTPTesting
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct IssueTests {
  @Test("Issue APIs preserve hierarchy and require explicit document fetching")
  func equivalence() async throws {
    let body = try Fixture.issue.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let value = try await client.issueTableOfContents(on: "2024-12-31")
    let request = try DocumentRequest.issueTableOfContents(on: "2024-12-31")
    #expect(try await client.value(for: request) == value)
    #expect(try await client.send(.issueTableOfContents(on: "2024-12-31")) == value)
    #expect(try await client.response(for: request).body == body)
    #expect(transport.requests.count == 4)
    #expect(value.meta?.publicationDate == "2024-12-31")
    #expect(value.agencies?.first?.documentCategories == [])
    #expect(
      value.agencies?.first?.seeAlso?.first?.slug == "animal-and-plant-health-inspection-service")
    let defense = try #require(value.agencies?.first { $0.slug == "defense-department" })
    #expect(
      defense.documentCategories?.first?.documents?.first?.documentNumbers == [
        "2024-31394", "2024-31395", "2024-31398", "2024-31399", "2024-31400",
      ])
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
        == JSONDecoder().decode(JSONValue.self, from: body))
  }

  @Test("Nonpublication-day HTML 404 is retained as an HTTP failure")
  func failure() async throws {
    let body = try Fixture.issueNonpublication.data()
    let transport = MockTransport(results: [.success(Response(body: body, status: .notFound))])
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    do {
      _ = try await client.issueTableOfContents(on: "2024-12-29")
      Issue.record("Expected HTTP failure")
    } catch {
      guard case .transport(.httpStatus(let bytes, let code, _)) = error else {
        Issue.record("Wrong failure"); return
      }
      #expect(code == 404)
      #expect(bytes == body)
    }
  }

  @Test("Issue date routes and malformed synthetic hierarchy fail closed")
  func validation() throws {
    for date in ["2024-02-30", "../documents", "2024-12-31/extra"] {
      #expect(throws: DocumentValidationError.invalidDate(date)) {
        try Endpoint<IssueTableOfContents>.issueTableOfContents(on: date)
      }
      #expect(Endpoint<IssueTableOfContents>(path: "/api/v1/issues/" + date + ".json") == nil)
    }
    let value = try IssueTableOfContents.decode(
      Data(#"{"agencies":[{},null],"meta":{"publication_date":null,"future":false}}"#.utf8))
    #expect(value.agencies == nil)
    #expect(value.meta?.publicationDate == nil)
    #expect(value.meta?.fields["future"] == .bool(false))
  }
}
