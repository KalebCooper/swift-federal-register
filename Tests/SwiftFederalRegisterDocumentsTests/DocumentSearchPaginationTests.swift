import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Synchronization
import Testing

/// A recorded lazy traversal: cursor links (newest, oldest, presidential) or page-number links
/// (term).
enum Traversal: String, CaseIterable, CustomTestStringConvertible, Sendable {
  case newest
  case oldest
  case presidential
  case term

  static let origin = "https://www.federalregister.gov"

  /// The shared 2024 publication range every recorded general search carried.
  static let dated =
    "conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
    + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31"

  /// The recorded first page.
  var pageOne: Fixture {
    switch self {
    case .newest: .searchNewestPageOne
    case .oldest: .searchOldestPageOne
    case .presidential: .pageOne
    case .term: .searchSpacedTermPageOne
    }
  }

  /// Document numbers of the recorded first page, in source order.
  var pageOneNumbers: [String] {
    switch self {
    case .newest: ["2024-31440", "2024-31439"]
    case .oldest: ["2023-26792", "2023-27783"]
    case .presidential: ["2026-19555", "2026-19554"]
    case .term: ["2024-31438", "2024-31431"]
    }
  }

  /// The receipt URL path of the first page as the SDK encodes it.
  var pageOnePath: String {
    switch self {
    case .newest: "/api/v1/documents.json?" + Self.dated + "&order=newest&per_page=2"
    case .oldest: "/api/v1/documents.json?" + Self.dated + "&order=oldest&per_page=2"
    case .presidential:
      "/api/v1/documents.json?conditions%5Btype%5D%5B%5D=PRESDOCU&order=newest&per_page=2"
    case .term:
      "/api/v1/documents.json?" + Self.dated
        + "&conditions%5Bterm%5D=clean%20water&order=newest&per_page=2"
    }
  }

  /// Document numbers of the second page, in source order.
  var pageTwoNumbers: [String] {
    switch self {
    case .newest: ["2024-31438", "2024-31437"]
    case .oldest: ["2023-27901", "2023-27905"]
    case .presidential: ["2026-19417", "2026-19416"]
    case .term: ["2024-31438", "2024-31431"]
    }
  }

  /// The path of the recorded first page's `next_page_url`.
  var pageTwoPath: String {
    switch self {
    case .newest:
      "/api/v1/documents?" + Self.dated + "&format=json&order=newest&page=2&per_page=2"
        + "&search_after_cursor=WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzkiXQ"
    case .oldest:
      "/api/v1/documents?" + Self.dated + "&format=json&order=oldest&page=2&per_page=2"
        + "&search_after_cursor=WzE3MDQxNTM2MDAwMDAsIjIwMjMtMjc3ODMiXQ"
    case .presidential:
      "/api/v1/documents?conditions%5Btype%5D%5B%5D=PRESDOCU&format=json&order=newest&page=2"
        + "&per_page=2&search_after_cursor=WzE3OTAxMjE2MDAwMDAsIjIwMjYtMTk1NTQiXQ"
    case .term:
      "/api/v1/documents?" + Self.dated
        + "&conditions%5Bterm%5D=clean+water&format=json&order=newest&page=2&per_page=2"
    }
  }

  var testDescription: String { rawValue }

  func documents(_ client: FederalRegisterClient) throws -> DocumentSequence {
    if let query = try searchQuery() { return client.documents(searching: query) }
    return client.documents(matching: try DocumentQuery(pageSize: 2))
  }

  func pages(_ client: FederalRegisterClient) throws -> DocumentPageSequence<DocumentPage> {
    if let query = try searchQuery() { return client.documentPages(searching: query) }
    return client.documentPages(matching: try DocumentQuery(pageSize: 2))
  }

  /// The recorded second page, or for the term search, whose page two was not captured, a
  /// synthetic terminal copy of the recorded page one.
  func pageTwo() throws -> Data {
    switch self {
    case .newest: try Fixture.searchNewestPageTwo.data()
    case .oldest: try Fixture.searchOldestPageTwo.data()
    case .presidential: try Fixture.pageTwo.data()
    case .term:
      try RecordedPage.changed(Fixture.searchSpacedTermPageOne.data()) {
        $0["next_page_url"] = NSNull()
      }
    }
  }

  func responses(_ client: FederalRegisterClient) throws -> DocumentPageSequence<
    SourceResponse<DocumentPage>
  > {
    if let query = try searchQuery() { return client.documentResponses(searching: query) }
    return client.documentResponses(matching: try DocumentQuery(pageSize: 2))
  }

  /// The general search each capture recorded, or nil for the presidential query.
  private func searchQuery() throws -> DocumentSearchQuery? {
    let year2024 = try DocumentDateFilter.range(from: "2024-01-01", through: "2024-12-31")
    switch self {
    case .newest: return try DocumentSearchQuery(pageSize: 2, publicationDate: year2024)
    case .oldest:
      return try DocumentSearchQuery(order: .oldest, pageSize: 2, publicationDate: year2024)
    case .presidential: return nil
    case .term:
      return try DocumentSearchQuery(pageSize: 2, publicationDate: year2024, term: "clean water")
    }
  }
}

/// Builds labeled synthetic page bodies from recorded bytes.
enum RecordedPage {
  /// A recorded page with its JSON object edited; only the edited keys differ from the capture.
  static func changed(_ data: Data, _ edit: (inout [String: Any]) -> Void) throws -> Data {
    var object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    edit(&object)
    return try JSONSerialization.data(withJSONObject: object)
  }

  /// A recorded page with no next link.
  static func terminal(_ data: Data) throws -> Data {
    try changed(data) { $0["next_page_url"] = NSNull() }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DocumentSearchPaginationTests {
  /// Synthetic next links, each paired with the traversal whose first page publishes it and the
  /// refusal it must produce. Each edits one part of a recorded next link.
  static let unusableLinks: [(Traversal, String, DocumentPaginationError)] = {
    let newest = Traversal.newest.pageTwoPath
    let term = Traversal.term.pageTwoPath
    let newestQuery = String(newest.drop { $0 != "?" })
    let termQuery = String(term.drop { $0 != "?" })
    let origin = Traversal.origin
    let cursor = "&search_after_cursor=WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzkiXQ"
    var links: [(Traversal, String, DocumentPaginationError)] = []
    for (traversal, path, query) in [
      (Traversal.newest, newest, newestQuery), (.term, term, termQuery),
    ] {
      for link in [
        "https://evil.example" + path,
        "http://www.federalregister.gov" + path,
        "https://www.federalregister.gov:8443" + path,
        "https://user:secret@www.federalregister.gov" + path,
        origin + path + "#top",
        origin + "/api/v1/agencies.json" + query,
        origin + "/api/v1/agencies/environmental-protection-agency.json" + query,
        origin + "/api/v1/documents/%2e%2e/agencies.json" + query,
        origin + "/api/v1/documents%2Fx" + query,
        origin + path.replacing("format=json", with: "format=xml"),
      ] {
        links.append((traversal, link, .invalidLink(link)))
      }
    }
    links += [
      (.newest, origin + newest.replacing(cursor, with: "&search_after_cursor="), .missingCursor),
      (.newest, origin + newest + "&search_after_cursor=abc", .missingCursor),
      (
        .newest, origin + newest.replacing(cursor, with: "").replacing("&page=2", with: ""),
        .missingCursor
      ),
      (
        .newest, origin + newest.replacing("lte%5D=2024-12-31", with: "lte%5D=2024-06-30"),
        .changedQuery
      ),
      (.newest, origin + newest.replacing("order=newest", with: "order=oldest"), .changedQuery),
      (.newest, origin + newest.replacing("per_page=2", with: "per_page=20"), .changedQuery),
      (
        .newest, origin + newest + "&conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01",
        .changedQuery
      ),
      (.term, origin + term.replacing("&page=2", with: ""), .missingCursor),
      (.term, origin + term.replacing("&page=2", with: "&page=1"), .nonprogressingPage(1)),
      (.term, origin + term.replacing("clean+water", with: "clean+air"), .changedQuery),
      (.term, origin + term.replacing("per_page=2", with: "per_page=20"), .changedQuery),
    ]
    return links
  }()

  @Test(
    "A document repeated across a page boundary is yielded twice in source order",
    arguments: [Traversal.newest, .oldest])
  func aDocumentRepeatedAcrossAPageBoundaryIsYieldedTwiceInSourceOrder(_ traversal: Traversal)
    async throws
  {
    // Synthetic second page: the recorded first page with its next link removed.
    let pageOne = try traversal.pageOne.data()
    let transport = transport([pageOne, try RecordedPage.terminal(pageOne)])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var numbers: [String] = []
    for try await document in try traversal.documents(client) {
      numbers.append(document.documentNumber)
    }
    #expect(numbers == traversal.pageOneNumbers + traversal.pageOneNumbers)
    #expect(transport.requests.count == 2)
    #expect(transport.requests[1].request.path == traversal.pageTwoPath)
  }

  @Test(
    "A later page that repeats a cursor fails before it is yielded",
    arguments: [Traversal.newest, .oldest])
  func aLaterPageThatRepeatsACursorFailsBeforeItIsYielded(_ traversal: Traversal) async throws {
    // Synthetic: the recorded second page pointing back at its own cursor link.
    let repeated = try RecordedPage.changed(traversal.pageTwo()) {
      $0["next_page_url"] = Traversal.origin + traversal.pageTwoPath
    }
    let transport = transport([try traversal.pageOne.data(), repeated])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    #expect(try await iterator.next()?.results.map(\.documentNumber) == traversal.pageOneNumbers)
    do { _ = try await iterator.next(); Issue.record("Expected repeated cursor") } catch {
      guard case .pagination(let failure) = error else { Issue.record("Wrong failure"); return }
      let cursor = try #require(traversal.pageTwoPath.split(separator: "=").last)
      #expect(failure == .repeatedCursor(String(cursor)))
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test(
    "A later page decoding failure ends the traversal without another request",
    arguments: Traversal.allCases)
  func aLaterPageDecodingFailureEndsTheTraversalWithoutAnotherRequest(_ traversal: Traversal)
    async throws
  {
    let transport = transport([try traversal.pageOne.data(), Data("<html>unavailable</html>".utf8)])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    #expect(try await iterator.next()?.results.map(\.documentNumber) == traversal.pageOneNumbers)
    do { _ = try await iterator.next(); Issue.record("Expected decoding failure") } catch {
      guard case .decoding = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
    #expect(transport.requests[1].request.path == traversal.pageTwoPath)
  }

  @Test(
    "A later page HTTP 400 keeps its status and body and ends the traversal",
    arguments: [Traversal.newest, .oldest, .term])
  func aLaterPageHTTP400KeepsItsStatusAndBodyAndEndsTheTraversal(_ traversal: Traversal)
    async throws
  {
    let transport = transport([try traversal.pageOne.data()])
    transport.enqueue(
      .success(
        MockTransport.Answer(
          Response(
            body: try Fixture.invalidCursorFailure.data(),
            headers: [.contentType: "application/json"], status: .badRequest))))
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    #expect(try await iterator.next()?.results.map(\.documentNumber) == traversal.pageOneNumbers)
    do { _ = try await iterator.next(); Issue.record("Expected HTTP failure") } catch {
      guard case .transport(.httpStatus(let body, let code, let headers)) = error else {
        Issue.record("Wrong failure"); return
      }
      #expect(
        String(decoding: body, as: UTF8.self)
          == #"{"status":400,"message":"Invalid search_after_cursor token"}"#)
      #expect(code == 400)
      #expect(headers[.contentType] == "application/json")
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
    #expect(transport.requests[1].request.path == traversal.pageTwoPath)
  }

  @Test(
    "A page total at or below the pages seen does not end a traversal with a next link",
    arguments: Traversal.allCases)
  func aPageTotalAtOrBelowThePagesSeenDoesNotEndATraversalWithANextLink(_ traversal: Traversal)
    async throws
  {
    // Synthetic: the recorded first page claiming one page and two matches in all.
    let capped = try RecordedPage.changed(traversal.pageOne.data()) {
      $0["count"] = 2
      $0["total_pages"] = 1
    }
    let transport = transport([capped, try traversal.pageTwo()])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    let first = try #require(try await iterator.next())
    #expect(first.count == 2)
    #expect(first.totalPages == 1)
    #expect(transport.requests.count == 1)
    #expect(try await iterator.next()?.results.map(\.documentNumber) == traversal.pageTwoNumbers)
    #expect(transport.requests.count == 2)
    #expect(transport.requests[1].request.path == traversal.pageTwoPath)
  }

  @Test(
    "An unusable next link fails before any further request",
    arguments: DocumentSearchPaginationTests.unusableLinks)
  func anUnusableNextLinkFailsBeforeAnyFurtherRequest(
    _ traversal: Traversal, _ link: String, _ expected: DocumentPaginationError
  ) async throws {
    let body = try RecordedPage.changed(traversal.pageOne.data()) { $0["next_page_url"] = link }
    let transport = transport([body])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    do { _ = try await iterator.next(); Issue.record("Expected pagination failure") } catch {
      guard case .pagination(let failure) = error else { Issue.record("Wrong failure"); return }
      #expect(failure == expected)
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
    #expect(transport.requests[0].request.path == traversal.pageOnePath)
  }

  @Test(
    "Breaking after the first item or at a page boundary sends no further request",
    arguments: [Traversal.newest, .oldest, .term], [1, 2])
  func breakingAfterTheFirstItemOrAtAPageBoundarySendsNoFurtherRequest(
    _ traversal: Traversal, _ taken: Int
  ) async throws {
    let transport = transport([try traversal.pageOne.data()])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var numbers: [String] = []
    for try await document in try traversal.documents(client) {
      numbers.append(document.documentNumber)
      if numbers.count == taken { break }
    }
    #expect(numbers == Array(traversal.pageOneNumbers.prefix(taken)))
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Cancellation between pages sends no following page request",
    arguments: Traversal.allCases)
  func cancellationBetweenPagesSendsNoFollowingPageRequest(_ traversal: Traversal) async throws {
    let transport = transport([try traversal.pageOne.data()])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    #expect(try await iterator.next()?.results.map(\.documentNumber) == traversal.pageOneNumbers)
    unsafe withUnsafeCurrentTask { unsafe $0?.cancel() }
    do { _ = try await iterator.next(); Issue.record("Expected cancellation") } catch {
      guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Cancellation while a page request is in flight discards its response",
    arguments: Traversal.allCases, [false, true])
  func cancellationWhileAPageRequestIsInFlightDiscardsItsResponse(
    _ traversal: Traversal, _ onSecondPage: Bool
  ) async throws {
    let transport = MockTransport()
    let answer: Data
    if onSecondPage {
      transport.enqueue(
        .success(MockTransport.Answer(Response(body: try traversal.pageOne.data(), status: .ok))))
      answer = try traversal.pageTwo()
    } else {
      answer = try traversal.pageOne.data()
    }
    // First pages use the `.json` route; every recorded next link uses the bare route.
    let running = RunningTraversal()
    transport.setHandler(forPath: onSecondPage ? "/api/v1/documents" : "/api/v1/documents.json") {
      _ in
      running.task.withLock { $0?.cancel() }
      return .success(MockTransport.Answer(Response(body: answer, status: .ok)))
    }
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let pages = try traversal.pages(client)
    let (start, starter) = AsyncStream<Void>.makeStream()
    let traversalTask = Task { () -> TraversalOutcome in
      for await _ in start { break }
      var iterator = pages.makeAsyncIterator()
      var yielded: [[String]] = []
      do throws(FederalRegisterError) {
        while let page = try await iterator.next() {
          yielded.append(page.results.map(\.documentNumber))
        }
        return TraversalOutcome(failure: nil, nextAfterFailure: nil, yielded: yielded)
      } catch {
        let failure = error
        let after: DocumentPage?
        do throws(FederalRegisterError) { after = try await iterator.next() } catch {
          return TraversalOutcome(failure: failure, nextAfterFailure: "threw", yielded: yielded)
        }
        return TraversalOutcome(
          failure: failure, nextAfterFailure: after == nil ? "nil" : "page", yielded: yielded)
      }
    }
    running.task.withLock { $0 = traversalTask }
    starter.yield()
    starter.finish()
    let outcome = await traversalTask.value
    guard case .transport(.cancelled) = outcome.failure else {
      Issue.record("Expected cancellation, got \(String(describing: outcome.failure))"); return
    }
    #expect(outcome.nextAfterFailure == "nil")
    #expect(outcome.yielded == (onSecondPage ? [traversal.pageOneNumbers] : []))
    #expect(transport.requests.count == (onSecondPage ? 2 : 1))
    #expect(
      transport.last?.request.path == (onSecondPage ? traversal.pageTwoPath : traversal.pageOnePath)
    )
  }

  @Test(
    "Cancellation while draining buffered items sends no following request",
    arguments: [Traversal.oldest, .term])
  func cancellationWhileDrainingBufferedItemsSendsNoFollowingRequest(_ traversal: Traversal)
    async throws
  {
    let transport = transport([try traversal.pageOne.data()])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.documents(client).makeAsyncIterator()
    #expect(try await iterator.next()?.documentNumber == traversal.pageOneNumbers[0])
    unsafe withUnsafeCurrentTask { unsafe $0?.cancel() }
    do { _ = try await iterator.next(); Issue.record("Expected cancellation") } catch {
      guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Each receipt carries the bytes and URL of its own single fetch",
    arguments: [Traversal.oldest, .term])
  func eachReceiptCarriesTheBytesAndURLOfItsOwnSingleFetch(_ traversal: Traversal) async throws {
    let pageOne = try traversal.pageOne.data()
    let pageTwo = try traversal.pageTwo()
    let transport = transport([pageOne, pageTwo])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var receipts = try traversal.responses(client).makeAsyncIterator()
    let first = try #require(try await receipts.next())
    #expect(transport.requests.count == 1)
    let second = try #require(try await receipts.next())
    #expect(transport.requests.count == 2)
    #expect(first.body == pageOne)
    #expect(first.requestURL == Traversal.origin + traversal.pageOnePath)
    #expect(first.status == 200)
    #expect(first.value.results.map(\.documentNumber) == traversal.pageOneNumbers)
    #expect(second.body == pageTwo)
    #expect(second.requestURL == Traversal.origin + traversal.pageTwoPath)
    #expect(second.status == 200)
    #expect(second.value.results.map(\.documentNumber) == traversal.pageTwoNumbers)
    #expect(
      transport.requests.map(\.request.path) == [traversal.pageOnePath, traversal.pageTwoPath])
  }

  @Test(
    "Independent iterators start from the first page and keep their own cursors",
    arguments: Traversal.allCases)
  func independentIteratorsStartFromTheFirstPageAndKeepTheirOwnCursors(_ traversal: Traversal)
    async throws
  {
    let pageOne = try traversal.pageOne.data()
    let pageTwo = try traversal.pageTwo()
    let transport = transport([pageOne, pageOne, pageTwo, pageTwo])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let pages = try traversal.pages(client)
    var first = pages.makeAsyncIterator()
    var second = pages.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    #expect(try await first.next()?.results.map(\.documentNumber) == traversal.pageOneNumbers)
    #expect(transport.requests.count == 1)
    #expect(try await second.next()?.results.map(\.documentNumber) == traversal.pageOneNumbers)
    #expect(transport.requests.count == 2)
    #expect(try await first.next()?.results.map(\.documentNumber) == traversal.pageTwoNumbers)
    #expect(transport.requests.count == 3)
    #expect(try await second.next()?.results.map(\.documentNumber) == traversal.pageTwoNumbers)
    #expect(transport.requests.count == 4)
    #expect(
      transport.requests.map(\.request.path) == [
        traversal.pageOnePath, traversal.pageOnePath, traversal.pageTwoPath, traversal.pageTwoPath,
      ])
  }

  @Test(
    "Invalid page metadata fails before any further request",
    arguments: [Traversal.newest, .term], [false, true])
  func invalidPageMetadataFailsBeforeAnyFurtherRequest(_ traversal: Traversal, _ negative: Bool)
    async throws
  {
    // Synthetic: the recorded first page with a negative count or no results beside its next link.
    let body = try RecordedPage.changed(traversal.pageOne.data()) {
      if negative { $0["count"] = -1 } else { $0["results"] = [Any]() }
    }
    let transport = transport([body])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var iterator = try traversal.pages(client).makeAsyncIterator()
    do { _ = try await iterator.next(); Issue.record("Expected invalid metadata") } catch {
      guard case .pagination(.invalidMetadata) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Items fetch one page on demand and buffered items send nothing",
    arguments: Traversal.allCases)
  func itemsFetchOnePageOnDemandAndBufferedItemsSendNothing(_ traversal: Traversal) async throws {
    let transport = transport([
      try traversal.pageOne.data(), try RecordedPage.terminal(traversal.pageTwo()),
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    let documents = try traversal.documents(client)
    var iterator = documents.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    var numbers: [String] = []
    var counts: [Int] = []
    while let document = try await iterator.next() {
      numbers.append(document.documentNumber)
      counts.append(transport.requests.count)
    }
    #expect(numbers == traversal.pageOneNumbers + traversal.pageTwoNumbers)
    #expect(counts == [1, 1, 2, 2])
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
    #expect(
      transport.requests.map(\.request.path) == [traversal.pageOnePath, traversal.pageTwoPath])
  }

  @Test(
    "Recorded cursor links carry a traversal through two sequential pages",
    arguments: [Traversal.newest, .oldest, .presidential])
  func recordedCursorLinksCarryATraversalThroughTwoSequentialPages(_ traversal: Traversal)
    async throws
  {
    // Synthetic third page: the recorded second page with its next link removed.
    let pageTwo = try traversal.pageTwo()
    let transport = transport([
      try traversal.pageOne.data(), pageTwo, try RecordedPage.terminal(pageTwo),
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test-app")
    var pages: [[String]] = []
    for try await page in try traversal.pages(client) {
      pages.append(page.results.map(\.documentNumber))
    }
    #expect(
      pages == [traversal.pageOneNumbers, traversal.pageTwoNumbers, traversal.pageTwoNumbers])
    let pageThree: String =
      switch traversal {
      case .newest:
        "/api/v1/documents?" + Traversal.dated + "&format=json&order=newest&page=3&per_page=2"
          + "&search_after_cursor=WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzciXQ"
      case .oldest:
        "/api/v1/documents?" + Traversal.dated + "&format=json&order=oldest&page=3&per_page=2"
          + "&search_after_cursor=WzE3MDQxNTM2MDAwMDAsIjIwMjMtMjc5MDUiXQ"
      default:
        "/api/v1/documents?conditions%5Btype%5D%5B%5D=PRESDOCU&format=json&order=newest&page=3"
          + "&per_page=2&search_after_cursor=WzE3OTAwMzUyMDAwMDAsIjIwMjYtMTk0MTYiXQ"
      }
    #expect(
      transport.requests.map(\.request.path) == [
        traversal.pageOnePath, traversal.pageTwoPath, pageThree,
      ])
  }

  private func transport(_ bodies: [Data]) -> MockTransport {
    MockTransport(
      results: bodies.map {
        .success(Response(body: $0, headers: [.contentType: "application/json"], status: .ok))
      })
  }
}

/// What one in-flight traversal observed before and after its failure.
private struct TraversalOutcome: Sendable {
  let failure: FederalRegisterError?
  let nextAfterFailure: String?
  let yielded: [[String]]
}

/// Holds the traversal a transport handler cancels while its request is in flight.
private final class RunningTraversal: Sendable {
  let task = Mutex<Task<TraversalOutcome, Never>?>(nil)
}
