import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FederalRegisterClientTests {
  @Test("All three detail levels produce the same value and exact request")
  func allThreeDetailLevelsProduceTheSameValueAndExactRequest() async throws {
    let transport = try transport([
      .historicalDocument, .historicalDocument, .historicalDocument, .historicalDocument,
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let everyday = try await client.document("93-32104")
    let stored = try DocumentRequest.document("93-32104")
    #expect(try await client.value(for: stored) == everyday)
    #expect(try await client.send(.document("93-32104")) == everyday)
    let custom = try await client.value(for: DocumentRequest<CustomResponse>.historical)
    #expect(custom.document_number == "93-32104")
    #expect(transport.requests.count == 4)
    for call in transport.requests {
      #expect(call.request.path == "/api/v1/documents/93-32104.json")
      #expect(call.request.headerFields[.userAgent] == "test-app")
      #expect(call.request.headerFields[.accept] == "application/json")
    }
  }

  @Test("Buffered item cancellation sends no following request")
  func bufferedItemCancellationSendsNoFollowingRequest() async throws {
    let transport = try transport([.pageOne])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = client.documents(matching: try DocumentQuery(pageSize: 2)).makeAsyncIterator()
    #expect(try await iterator.next()?.documentNumber == "2026-19555")
    unsafe withUnsafeCurrentTask { unsafe $0?.cancel() }
    do { _ = try await iterator.next(); Issue.record("Expected cancellation") } catch {
      guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("Cancellation before sending makes no request")
  func cancellationBeforeSendingMakesNoRequest() async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        do throws(FederalRegisterError) {
          _ = try await client.document("93-32104")
          Issue.record("Expected cancellation")
        } catch {
          guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
        }
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Content levels preserve source bytes and missing formats send nothing")
  func contentLevelsPreserveSourceBytesAndMissingFormatsSendNothing() async throws {
    let transport = try transport([.historicalText, .historicalText, .historicalText])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let document = try FederalRegisterDocument.decode(Fixture.historicalDocument.data())
    let value = try await client.content(.text, for: document)
    #expect(try await client.value(for: .content(.text, for: document)) == value)
    #expect(try await client.send(.content(.text, for: document)) == value)
    #expect(value.source.hasPrefix("<html>"))
    do {
      _ = try await client.content(.xml, for: document); Issue.record("Expected missing format")
    } catch {
      guard case .content(.unavailable(.xml)) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(transport.requests.count == 3)
    #expect(transport.last?.request.headerFields[.accept] == "text/plain")
  }

  @Test("Custom page endpoints yield only one page")
  func customPageEndpointsYieldOnlyOnePage() async throws {
    let transport = try transport([.pageOne])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let endpoint = Endpoint<DocumentPage>.presidentialDocuments(
      matching: try DocumentQuery(pageSize: 2))
    var iterator = client.documentPages(for: .init(endpoint: endpoint)).makeAsyncIterator()
    #expect(try await iterator.next()?.results.count == 2)
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("Early break never prefetches")
  func earlyBreakNeverPrefetches() async throws {
    let transport = try transport([.pageOne])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    for try await _ in client.documents(matching: try DocumentQuery(pageSize: 2)) { break }
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Invalid continuation fails before yielding or sending another page",
    arguments: [
      "https://evil.example/api/v1/documents?search_after_cursor=x",
      "https://www.federalregister.gov/api/v1/documents?per_page=2",
      "https://www.federalregister.gov/api/v1/documents?search_after_cursor=&per_page=2",
      "https://www.federalregister.gov/api/v1/documents?search_after_cursor=x&per_page=9",
      "https://www.federalregister.gov/api/v1/documents?search_after_cursor=x&search_after_cursor=y",
    ])
  func invalidContinuationFailsBeforeYieldingOrSendingAnotherPage(_ link: String) async throws {
    let body = try changedPage(.pageOne, next: link)
    let transport = MockTransport(results: [.success(Response(body: body, status: .ok))])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = client.documentPages(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    do { _ = try await iterator.next(); Issue.record("Expected pagination failure") } catch {
      guard case .pagination = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("Later page HTTP failure retains headers and terminates the iterator")
  func laterPageHTTPFailureRetainsHeadersAndTerminatesTheIterator() async throws {
    let transport = try transport([.pageOne])
    transport.enqueue(
      .success(
        MockTransport.Answer(
          Response(body: Data("quota".utf8), headers: [.retryAfter: "12"], status: .tooManyRequests)
        )))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = client.documentPages(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    #expect(try await iterator.next()?.results.count == 2)
    do { _ = try await iterator.next(); Issue.record("Expected HTTP failure") } catch {
      guard case .transport(.httpStatus(let body, let code, let fields)) = error else {
        Issue.record("Wrong failure"); return
      }
      #expect(body == Data("quota".utf8)); #expect(code == 429);
      #expect(fields[.retryAfter] == "12")
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Page receipts match the decoded bytes and actual cursor URL")
  func pageReceiptsMatchTheDecodedBytesAndActualCursorURL() async throws {
    let transport = try transport([.pageOne, .pageTwo])
    let instant = Date(timeIntervalSince1970: 123)
    let client = FederalRegisterClient(
      retrievalTime: { instant }, transport: transport, userAgent: "test-app")
    var iterator = client.documentResponses(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    let first = try #require(try await iterator.next())
    let second = try #require(try await iterator.next())
    #expect(first.body == (try Fixture.pageOne.data()))
    #expect(second.body == (try Fixture.pageTwo.data()))
    #expect(try DocumentPage.decode(second.body) == second.value)
    #expect(second.requestURL == first.value.nextPageURL)
    #expect(second.retrievedAt == instant)
    #expect(second.status == 200)
    #expect(
      second.publisher == "Office of the Federal Register, NARA; Government Publishing Office")
    #expect(transport.requests.count == 2)
  }

  @Test("Pages are lazy and iterators are independent")
  func pagesAreLazyAndIteratorsAreIndependent() async throws {
    let transport = try transport([.pageOne, .pageOne, .pageTwo])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let pages = client.documentPages(matching: try DocumentQuery(pageSize: 2))
    var first = pages.makeAsyncIterator(); var second = pages.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    #expect(try await first.next()?.results.first?.documentNumber == "2026-19555")
    #expect(transport.requests.count == 1)
    #expect(try await second.next()?.results.first?.documentNumber == "2026-19555")
    #expect(try await first.next()?.results.first?.documentNumber == "2026-19417")
    #expect(transport.requests[0].request.path == transport.requests[1].request.path)
    #expect(
      transport.requests[2].request.path?.contains(
        "search_after_cursor=WzE3OTAxMjE2MDAwMDAsIjIwMjYtMTk1NTQiXQ") == true)
  }

  @Test("Receipts and ordinary decoding perform exactly one fetch each")
  func receiptsAndOrdinaryDecodingPerformExactlyOneFetchEach() async throws {
    let transport = try transport([.historicalDocument])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let receipt = try await client.response(for: DocumentRequest.document("93-32104"))
    #expect(receipt.body == (try Fixture.historicalDocument.data()))
    #expect(receipt.value.signingDate == "1993-12-18")
    #expect(receipt.retrievedAt == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("Redirects are refused before another origin is contacted")
  func redirectsAreRefusedBeforeAnotherOriginIsContacted() async throws {
    let transport = MockTransport(results: [
      .success(Response(headers: [.location: "https://evil.example/"], status: .found))
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    do {
      _ = try await client.document("93-32104"); Issue.record("Expected redirect refusal")
    } catch {
      guard case .transport(.httpStatus(_, 302, _)) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Repeated cursors fail before the repeated page is yielded")
  func repeatedCursorsFailBeforeTheRepeatedPageIsYielded() async throws {
    let first = try DocumentPage.decode(Fixture.pageOne.data())
    let repeated = try changedPage(.pageTwo, next: first.nextPageURL)
    let transport = try transport([.pageOne])
    transport.enqueue(.success(MockTransport.Answer(Response(body: repeated, status: .ok))))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = client.documentPages(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    _ = try await iterator.next()
    do { _ = try await iterator.next(); Issue.record("Expected repeated cursor") } catch {
      guard case .pagination(.repeatedCursor) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Response limits fail through both single and page execution")
  func responseLimitsFailThroughBothSingleAndPageExecution() async throws {
    let transport = try transport([.historicalDocument, .pageOne])
    let client = FederalRegisterClient(
      maximumResponseBytes: 1, transport: transport, userAgent: "test-app")
    do { _ = try await client.document("93-32104"); Issue.record("Expected size failure") } catch {
      guard case .responseTooLarge(limit: 1) = error else { Issue.record("Wrong failure"); return }
    }
    var iterator = client.documentPages(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    do { _ = try await iterator.next(); Issue.record("Expected size failure") } catch {
      guard case .responseTooLarge(limit: 1) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
  }

  @Test("Terminal pages and items agree without dropping duplicates")
  func terminalPagesAndItemsAgreeWithoutDroppingDuplicates() async throws {
    let body = try changedPage(.pageOne, next: nil)
    let transport = MockTransport(results: [.success(Response(body: body, status: .ok))])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var result: [String] = []
    for try await document in client.documents(matching: try DocumentQuery(pageSize: 2)) {
      result.append(document.documentNumber)
    }
    #expect(result == ["2026-19555", "2026-19554"])
    #expect(transport.requests.count == 1)
  }

  private func changedPage(_ fixture: Fixture, next: String?) throws -> Data {
    var json = try #require(
      try JSONSerialization.jsonObject(with: fixture.data()) as? [String: Any])
    json["next_page_url"] = next.map { $0 as Any } ?? NSNull()
    return try JSONSerialization.data(withJSONObject: json)
  }

  private func transport(_ fixtures: [Fixture]) throws -> MockTransport {
    MockTransport(
      results: try fixtures.map {
        .success(
          Response(body: try $0.data(), headers: [.contentType: "application/json"], status: .ok))
      })
  }
}

private struct CustomResponse: Codable, DocumentResponse { let document_number: String }
extension DocumentRequest where Response == CustomResponse {
  fileprivate static var historical: Self {
    get throws {
      Self(endpoint: try #require(Endpoint(path: "/api/v1/documents/93-32104.json")))
    }
  }
}
