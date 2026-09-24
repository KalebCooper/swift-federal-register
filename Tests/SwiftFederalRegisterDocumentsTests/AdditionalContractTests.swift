import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AdditionalContractTests {
  @Test("All detail levels retain the same HTTP failure bytes and headers")
  func allDetailLevelsRetainTheSameHTTPFailureBytesAndHeaders() async throws {
    let response = Response(
      body: Data("not found".utf8), headers: [.retryAfter: "30"], status: .notFound)
    let transport = MockTransport(results: Array(repeating: .success(response), count: 3))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let endpoint = try Endpoint<FederalRegisterDocument>.document("93-32104")
    let request = try DocumentRequest.document("93-32104")
    for level in 0..<3 {
      do throws(FederalRegisterError) {
        switch level {
        case 0: _ = try await client.document("93-32104")
        case 1:
          _ = try await client.value(for: request)
        default:
          _ = try await client.send(endpoint)
        }
        Issue.record("Expected HTTP failure")
      } catch {
        guard case .transport(.httpStatus(let body, let code, let headers)) = error else {
          Issue.record("Wrong failure"); continue
        }
        #expect(body == Data("not found".utf8))
        #expect(code == 404)
        #expect(headers[.retryAfter] == "30")
      }
    }
    #expect(transport.requests.count == 3)
  }

  @Test("All single-page levels infer and decode the same envelope")
  func allSinglePageLevelsInferAndDecodeTheSameEnvelope() async throws {
    let response = Response(body: try Fixture.pageOne.data(), status: .ok)
    let transport = MockTransport(results: Array(repeating: .success(response), count: 3))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let query = try DocumentQuery(pageSize: 2)
    let page = try await client.presidentialDocuments(matching: query)
    let stored = DocumentRequest.presidentialDocuments(matching: query)
    #expect(try await client.value(for: stored) == page)
    #expect(try await client.send(.presidentialDocuments(matching: query)) == page)
    #expect(page.results.map(\.documentNumber) == ["2026-19555", "2026-19554"])
    #expect(transport.requests.count == 3)
  }

  @Test("Empty continuing pages and negative metadata fail explicitly", arguments: [false, true])
  func emptyContinuingPagesAndNegativeMetadataFailExplicitly(_ negative: Bool) async throws {
    var object = try #require(
      try JSONSerialization.jsonObject(with: Fixture.pageOne.data()) as? [String: Any])
    if negative { object["count"] = -1 } else { object["results"] = [] }
    let transport = MockTransport(results: [
      .success(Response(body: try JSONSerialization.data(withJSONObject: object), status: .ok))
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = client.documentPages(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    do { _ = try await iterator.next(); Issue.record("Expected invalid metadata") } catch {
      guard case .pagination(.invalidMetadata) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("Item traversal preserves duplicates across page boundaries")
  func itemTraversalPreservesDuplicatesAcrossPageBoundaries() async throws {
    var terminal = try #require(
      try JSONSerialization.jsonObject(with: Fixture.pageOne.data()) as? [String: Any])
    terminal["next_page_url"] = NSNull()
    let transport = MockTransport(results: [
      .success(Response(body: try Fixture.pageOne.data(), status: .ok)),
      .success(Response(body: try JSONSerialization.data(withJSONObject: terminal), status: .ok)),
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var numbers: [String] = []
    for try await document in client.documents(matching: try DocumentQuery(pageSize: 2)) {
      numbers.append(document.documentNumber)
    }
    #expect(numbers == ["2026-19555", "2026-19554", "2026-19555", "2026-19554"])
    #expect(transport.requests.count == 2)
  }

  @Test("Malformed successful JSON fails decoding without another request")
  func malformedSuccessfulJSONFailsDecodingWithoutAnotherRequest() async throws {
    let transport = MockTransport(results: [
      .success(Response(body: Data("<html>unavailable</html>".utf8), status: .ok))
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    do {
      _ = try await client.document("93-32104"); Issue.record("Expected decoding failure")
    } catch { guard case .decoding = error else { Issue.record("Wrong failure"); return } }
    #expect(transport.requests.count == 1)
  }

  @Test("Unknown document codes and nested fields survive semantic reencoding")
  func unknownDocumentCodesAndNestedFieldsSurviveSemanticReencoding() throws {
    var object = try #require(
      try JSONSerialization.jsonObject(with: Fixture.historicalDocument.data()) as? [String: Any])
    object["subtype"] = "Future Presidential Instrument"
    object["future"] = ["null": NSNull(), "values": [true, "new", 12]]
    let document = try FederalRegisterDocument.decode(
      JSONSerialization.data(withJSONObject: object))
    #expect(document.subtype == "Future Presidential Instrument")
    #expect(
      document.fields["future"]
        == .object(["null": .null, "values": .array([.bool(true), .string("new"), .number(12)])]))
    #expect(try FederalRegisterDocument.decode(JSONEncoder().encode(document)) == document)
  }
}
