import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DocumentSearchClientTests {
  /// Receipt URL of Fixtures/search-newest-page-one.json as the SDK encodes it.
  private let newestPageOnePath =
    "/api/v1/documents.json?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
    + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&order=newest&per_page=2"
  /// The `next_page_url` path of Fixtures/search-newest-page-one.json.
  private let newestPageTwoPath =
    "/api/v1/documents?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
    + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&format=json&order=newest&page=2"
    + "&per_page=2&search_after_cursor=WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzkiXQ"
  /// Receipt URL of Fixtures/search-spaced-term-page-one.json as the SDK encodes it.
  private let spacedTermPageOnePath =
    "/api/v1/documents.json?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
    + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D=clean%20water"
    + "&order=newest&per_page=2"
  /// The `next_page_url` path of Fixtures/search-spaced-term-page-one.json: a page number, no cursor.
  private let spacedTermPageTwoPath =
    "/api/v1/documents?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
    + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D=clean+water"
    + "&format=json&order=newest&page=2&per_page=2"

  @Test("All three search levels produce the same page and exact request")
  func allThreeSearchLevelsProduceTheSamePageAndExactRequest() async throws {
    let transport = try transport([
      .searchNewestPageOne, .searchNewestPageOne, .searchNewestPageOne,
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let query = try newestQuery()
    let everyday = try await client.searchDocuments(matching: query)
    let stored = DocumentRequest.searchDocuments(matching: query)
    #expect(try await client.value(for: stored) == everyday)
    #expect(try await client.send(.searchDocuments(matching: query)) == everyday)
    #expect(everyday.results.map(\.documentNumber) == ["2024-31440", "2024-31439"])
    #expect(everyday.count == 10000)
    #expect(everyday.totalPages == 50)
    #expect(transport.requests.count == 3)
    for call in transport.requests {
      #expect(call.request.path == newestPageOnePath)
      #expect(call.request.headerFields[.userAgent] == "test-app")
      #expect(call.request.headerFields[.accept] == "application/json")
    }
  }

  @Test("A custom endpoint request from the search path yields exactly one page")
  func aCustomEndpointRequestFromTheSearchPathYieldsExactlyOnePage() async throws {
    let transport = try transport([.searchNewestPageOne])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let endpoint = try #require(Endpoint<DocumentPage>(path: newestPageOnePath))
    var iterator = client.documentPages(for: DocumentRequest(endpoint: endpoint))
      .makeAsyncIterator()
    let page = try #require(try await iterator.next())
    #expect(page.results.map(\.documentNumber) == ["2024-31440", "2024-31439"])
    #expect(page.nextPageURL != nil)
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
    #expect(transport.requests[0].request.path == newestPageOnePath)
  }

  @Test("A zero-match search returns an empty page and an empty item sequence")
  func aZeroMatchSearchReturnsAnEmptyPageAndAnEmptyItemSequence() async throws {
    let transport = try transport([.searchTerminal, .searchTerminal, .searchTerminal])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let query = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "codexNoMatchingDocument987654321")
    let page = try await client.searchDocuments(matching: query)
    #expect(page.count == 0)
    #expect(page.results == [])
    #expect(page.totalPages == nil)
    #expect(page.nextPageURL == nil)
    var pages = client.documentPages(searching: query).makeAsyncIterator()
    #expect(try await pages.next()?.results == [])
    #expect(try await pages.next() == nil)
    var numbers: [String] = []
    for try await document in client.documents(searching: query) {
      numbers.append(document.documentNumber)
    }
    #expect(numbers == [])
    #expect(transport.requests.count == 3)
    for call in transport.requests {
      #expect(
        call.request.path
          == "/api/v1/documents.json?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
          + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31"
          + "&conditions%5Bterm%5D=codexNoMatchingDocument987654321&order=newest&per_page=2")
    }
  }

  @Test("Cancellation before a search sends nothing")
  func cancellationBeforeASearchSendsNothing() async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let query = try newestQuery()
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        do throws(FederalRegisterError) {
          _ = try await client.searchDocuments(matching: query)
          Issue.record("Expected cancellation")
        } catch {
          guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
        }
      }
      group.addTask {
        var iterator = client.documentPages(searching: query).makeAsyncIterator()
        do throws(FederalRegisterError) {
          _ = try await iterator.next()
          Issue.record("Expected cancellation")
        } catch {
          guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
        }
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Cancellation after a search page sends no following request")
  func cancellationAfterASearchPageSendsNoFollowingRequest() async throws {
    let transport = try transport([.searchNewestPageOne])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = client.documents(searching: try newestQuery()).makeAsyncIterator()
    #expect(try await iterator.next()?.documentNumber == "2024-31440")
    unsafe withUnsafeCurrentTask { unsafe $0?.cancel() }
    do { _ = try await iterator.next(); Issue.record("Expected cancellation") } catch {
      guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("HTTP failures reach every search level with their body and status")
  func httpFailuresReachEverySearchLevelWithTheirBodyAndStatus() async throws {
    let body = try Fixture.invalidCursorFailure.data()
    let response = Response(body: body, status: .badRequest)
    let transport = MockTransport(results: Array(repeating: .success(response), count: 3))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let query = try newestQuery()
    for level in 0..<3 {
      do throws(FederalRegisterError) {
        switch level {
        case 0: _ = try await client.searchDocuments(matching: query)
        case 1: _ = try await client.value(for: .searchDocuments(matching: query))
        default: _ = try await client.send(.searchDocuments(matching: query))
        }
        Issue.record("Expected HTTP failure")
      } catch {
        guard case .transport(.httpStatus(let failureBody, let code, _)) = error else {
          Issue.record("Wrong failure"); continue
        }
        #expect(failureBody == body)
        #expect(
          String(decoding: failureBody, as: UTF8.self)
            == #"{"status":400,"message":"Invalid search_after_cursor token"}"#)
        #expect(code == 400)
      }
    }
    #expect(transport.requests.count == 3)
  }

  @Test("Presidential labels still infer the presidential query")
  func presidentialLabelsStillInferThePresidentialQuery() throws {
    let client = FederalRegisterClient(transport: MockTransport(), userAgent: "test-app")
    let presidential: DocumentSequence = client.documents(matching: try .init(pageSize: 2))
    let general: DocumentSequence = client.documents(searching: try .init(pageSize: 2))
    let presidentialPages = client.documentPages(matching: try .init(pageSize: 2))
    let generalPages = client.documentPages(searching: try .init(pageSize: 2))
    _ = (presidential, general, presidentialPages, generalPages)
    #expect(
      Endpoint<DocumentPage>.presidentialDocuments(matching: try .init(pageSize: 2)).path
        == "/api/v1/documents.json?conditions%5Btype%5D%5B%5D=PRESDOCU&order=newest&per_page=2")
    #expect(
      Endpoint<DocumentPage>.searchDocuments(matching: try .init(pageSize: 2)).path
        == "/api/v1/documents.json?order=newest&per_page=2")
  }

  @Test("Search sequences are lazy, independent, and follow the recorded cursor link")
  func searchSequencesAreLazyIndependentAndFollowTheRecordedCursorLink() async throws {
    let transport = try transport([
      .searchNewestPageOne, .searchNewestPageOne, .searchNewestPageTwo,
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let pages = client.documentPages(searching: try newestQuery())
    var first = pages.makeAsyncIterator()
    var second = pages.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    #expect(
      try await first.next()?.results.map(\.documentNumber) == ["2024-31440", "2024-31439"])
    #expect(transport.requests.count == 1)
    #expect(
      try await second.next()?.results.map(\.documentNumber) == ["2024-31440", "2024-31439"])
    #expect(transport.requests.count == 2)
    #expect(
      try await first.next()?.results.map(\.documentNumber) == ["2024-31438", "2024-31437"])
    #expect(transport.requests.count == 3)
    #expect(transport.requests[0].request.path == newestPageOnePath)
    #expect(transport.requests[1].request.path == newestPageOnePath)
    #expect(transport.requests[2].request.path == newestPageTwoPath)
  }

  @Test("Search receipts and both request overloads agree on the first page")
  func searchReceiptsAndBothRequestOverloadsAgreeOnTheFirstPage() async throws {
    let transport = try transport([
      .searchNewestPageOne, .searchNewestPageTwo, .searchNewestPageOne, .searchNewestPageOne,
      .searchNewestPageOne, .searchNewestPageOne, .searchNewestPageOne,
    ])
    let instant = Date(timeIntervalSince1970: 123)
    let client = FederalRegisterClient(
      retrievalTime: { instant }, transport: transport, userAgent: "test-app")
    let query = try newestQuery()
    let request = DocumentRequest.searchDocuments(matching: query)
    var receipts = client.documentResponses(searching: query).makeAsyncIterator()
    let first = try #require(try await receipts.next())
    let second = try #require(try await receipts.next())
    #expect(first.body == (try Fixture.searchNewestPageOne.data()))
    #expect(second.body == (try Fixture.searchNewestPageTwo.data()))
    #expect(first.requestURL == "https://www.federalregister.gov" + newestPageOnePath)
    #expect(second.requestURL == "https://www.federalregister.gov" + newestPageTwoPath)
    #expect(second.requestURL == first.value.nextPageURL)
    #expect(first.retrievedAt == instant)
    #expect(second.status == 200)
    #expect(
      second.publisher == "Office of the Federal Register, NARA; Government Publishing Office")
    var receiptsForRequest = client.documentResponses(for: request).makeAsyncIterator()
    let firstForRequest = try #require(try await receiptsForRequest.next())
    #expect(firstForRequest.body == first.body)
    #expect(firstForRequest.requestURL == first.requestURL)
    #expect(firstForRequest.value == first.value)
    var pages = client.documentPages(searching: query).makeAsyncIterator()
    var pagesForRequest = client.documentPages(for: request).makeAsyncIterator()
    #expect(try await pages.next() == first.value)
    #expect(try await pagesForRequest.next() == first.value)
    var documents = client.documents(searching: query).makeAsyncIterator()
    var documentsForRequest = client.documents(for: request).makeAsyncIterator()
    #expect(try await documents.next() == first.value.results[0])
    #expect(try await documentsForRequest.next() == first.value.results[0])
    #expect(transport.requests.count == 7)
    for call in transport.requests.dropFirst(2) {
      #expect(call.request.path == newestPageOnePath)
    }
  }

  @Test("Search results stay sparse without a hidden detail fetch")
  func searchResultsStaySparseWithoutAHiddenDetailFetch() async throws {
    let transport = try transport([.searchNewestPageOne])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let page = try await client.searchDocuments(matching: try newestQuery())
    #expect(page.results.count == 2)
    for document in page.results {
      #expect(document.cfrReferences == nil)
      #expect(document.fields["cfr_references"] == nil)
      #expect(document.fields["title"] != nil)
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Term searches follow the recorded page-number link without a cursor")
  func termSearchesFollowTheRecordedPageNumberLinkWithoutACursor() async throws {
    // Synthetic second page: the recorded page one with its next link removed; the provider's
    // page two of this term search was not captured.
    let terminal = try changedPage(.searchSpacedTermPageOne, next: nil)
    let transport = try transport([.searchSpacedTermPageOne])
    transport.enqueue(.success(MockTransport.Answer(Response(body: terminal, status: .ok))))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let query = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "clean water")
    var numbers: [String] = []
    for try await document in client.documents(searching: query) {
      numbers.append(document.documentNumber)
    }
    #expect(numbers == ["2024-31438", "2024-31431", "2024-31438", "2024-31431"])
    #expect(transport.requests.count == 2)
    #expect(transport.requests[0].request.path == spacedTermPageOnePath)
    #expect(transport.requests[1].request.path == spacedTermPageTwoPath)
  }

  private func changedPage(_ fixture: Fixture, next: String?) throws -> Data {
    var json = try #require(
      try JSONSerialization.jsonObject(with: fixture.data()) as? [String: Any])
    json["next_page_url"] = next.map { $0 as Any } ?? NSNull()
    return try JSONSerialization.data(withJSONObject: json)
  }

  /// The query recorded as Fixtures/search-newest-page-one.json.
  private func newestQuery() throws -> DocumentSearchQuery {
    try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"))
  }

  private func transport(_ fixtures: [Fixture]) throws -> MockTransport {
    MockTransport(
      results: try fixtures.map {
        .success(
          Response(body: try $0.data(), headers: [.contentType: "application/json"], status: .ok))
      })
  }
}
