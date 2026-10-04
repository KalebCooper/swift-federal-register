import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct PublishedSelectionTests {
  @Test("Detail overloads preserve method references and one-fetch equivalence")
  func detailEquivalence() async throws {
    let body = try Fixture.fieldsDetail.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "selection-test")
    let endpointFactory: (String) throws -> Endpoint<FederalRegisterDocument> = Endpoint.document
    let requestFactory: (String) throws -> DocumentRequest<FederalRegisterDocument> =
      DocumentRequest.document
    #expect(try endpointFactory("93-32104").path == "/api/v1/documents/93-32104.json")
    #expect(try requestFactory("93-32104").endpoint == endpointFactory("93-32104"))
    let everyday = try await client.document("2024-31396", fields: [.significant])
    let request = try DocumentRequest.document("2024-31396", fields: [.significant])
    #expect(try await client.value(for: request) == everyday)
    #expect(try await client.send(.document("2024-31396", fields: [.significant])) == everyday)
    let receipt = try await client.response(for: request)
    #expect(receipt.body == body)
    #expect(receipt.value == everyday)
    #expect(transport.requests.count == 4)
    for call in transport.requests {
      #expect(
        call.request.path
          == "/api/v1/documents/2024-31396.json?fields%5B%5D=document_number&fields%5B%5D=significant&fields%5B%5D=title"
      )
      #expect(call.request.headerFields[.userAgent] == "selection-test")
    }
  }

  @Test("Empty and control field names fail before sending", arguments: ["", "\n", "a\u{0085}"])
  func invalidFields(_ name: String) async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    #expect(throws: DocumentValidationError.emptyFilterValue("fields")) {
      try DocumentSearchQuery(fields: [.init(rawValue: name)])
    }
    do {
      _ = try await client.document("93-32104", fields: [.init(rawValue: name)])
      Issue.record("Expected validation")
    } catch {
      guard case .validation(.emptyFilterValue("fields")) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Selected searches preserve explicit false, duplicates, future fields and required names")
  func queryLiterals() throws {
    #expect(
      try Endpoint<DocumentPage>.searchDocuments(matching: .init()).path
        == "/api/v1/documents.json?order=newest&per_page=20")
    let query = try DocumentSearchQuery(
      fields: [.title, .title, .init(rawValue: "future+field")], significant: false)
    #expect(
      Endpoint<DocumentPage>.searchDocuments(matching: query).path
        == "/api/v1/documents.json?conditions%5Bsignificant%5D=0&fields%5B%5D=document_number&fields%5B%5D=future%2Bfield&fields%5B%5D=title&fields%5B%5D=title&order=newest&per_page=20"
    )
    #expect(
      try JSONDecoder().decode(DocumentField.self, from: Data(#""future""#.utf8)).rawValue
        == "future")
  }

  @Test("Selected captured pages retain significance and validate continuation")
  func selectedPages() throws {
    let first = try DocumentPage.decode(Fixture.significant1.data())
    let second = try DocumentPage.decode(Fixture.significant1Two.data())
    #expect(first.results.allSatisfy { $0.significant == true })
    #expect(second.results.allSatisfy { $0.significant == true })
    let endpoint = try #require(
      Endpoint<DocumentPage>(
        path:
          "/api/v1/documents.json?per_page=2&conditions%5Bsignificant%5D=1&fields%5B%5D=document_number&fields%5B%5D=title&fields%5B%5D=significant"
      ))
    #expect(try first.continuation(after: endpoint, seenCursors: []) != nil)
    let falsePage = try DocumentPage.decode(Fixture.significant0.data())
    #expect(falsePage.results.allSatisfy { $0.significant == false })
    #expect(throws: (any Error).self) { try DocumentPage.decode(Fixture.sparseTitle.data()) }
  }
}
