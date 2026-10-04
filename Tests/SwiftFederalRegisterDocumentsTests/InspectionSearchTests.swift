import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Synchronization
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct InspectionSearchTests {
  private static let next =
    "https://www.federalregister.gov/api/v1/public_inspection_documents?action=index&controller=api%2Fv1%2Fpublic_inspection_documents&format=json&page=2&per_page=2"

  @Test("Cancellation before sending performs no request")
  func cancellationBefore() async throws {
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let query = try PublicInspectionQuery(pageSize: 2)
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        var iterator = client.publicInspectionPages(searching: query).makeAsyncIterator()
        do throws(FederalRegisterError) {
          _ = try await iterator.next(); Issue.record("Expected cancellation")
        } catch {
          guard case .transport(.cancelled) = error else { Issue.record("Wrong failure"); return }
        }
        do { #expect(try await iterator.next() == nil) } catch {
          Issue.record("Finished iterator threw")
        }
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test(
    "Cancellation in flight, between pages, and while draining terminates iterators",
    arguments: ["first", "second", "between", "drain"])
  func cancellationDuring(_ stage: String) async throws {
    let first = try Fixture.inspectionSearch.data()
    let second = try Fixture.inspectionSearchTwo.data()
    let transport = MockTransport()
    let running = InspectionRunningTask()
    let firstPath = "/api/v1/public-inspection-documents.json"
    let secondPath = "/api/v1/public_inspection_documents"
    transport.setHandler(forPath: firstPath) { _ in
      if stage == "first" { running.task.withLock { $0?.cancel() } }
      return .success(MockTransport.Answer(Response(body: first, status: .ok)))
    }
    transport.setHandler(forPath: secondPath) { _ in
      if stage == "second" { running.task.withLock { $0?.cancel() } }
      return .success(MockTransport.Answer(Response(body: second, status: .ok)))
    }
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let query = try PublicInspectionQuery(pageSize: 2)
    let (start, continuation) = AsyncStream<Void>.makeStream()
    let task = Task { () -> FederalRegisterError? in
      for await _ in start { break }
      var iterator = client.publicInspectionDocuments(searching: query).makeAsyncIterator()
      do throws(FederalRegisterError) {
        _ = try await iterator.next()
        if stage == "drain" { running.task.withLock { $0?.cancel() } }
        _ = try await iterator.next()
        if stage == "between" { running.task.withLock { $0?.cancel() } }
        _ = try await iterator.next()
        Issue.record("Expected cancellation")
        return nil
      } catch {
        do { #expect(try await iterator.next() == nil) } catch {
          Issue.record("Finished iterator threw")
        }
        return error
      }
    }
    running.task.withLock { $0 = task }
    continuation.yield()
    continuation.finish()
    let failure = await task.value
    guard case .transport(.cancelled) = failure else {
      Issue.record("Wrong failure: \(String(describing: failure))"); return
    }
    #expect(transport.requests.count == (stage == "second" ? 2 : 1))
  }

  @Test("One-shot search levels and custom requests never traverse automatically")
  func equivalence() async throws {
    let body = try Fixture.inspectionSearch.data()
    let transport = makeTransport(Array(repeating: body, count: 5))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let query = try PublicInspectionQuery(pageSize: 2)
    let value = try await client.searchPublicInspectionDocuments(matching: query)
    let request = DocumentRequest.searchPublicInspectionDocuments(matching: query)
    #expect(try await client.value(for: request) == value)
    #expect(try await client.send(.searchPublicInspectionDocuments(matching: query)) == value)
    #expect(try await client.response(for: request).body == body)
    var custom = client.publicInspectionPages(for: DocumentRequest(endpoint: request.endpoint))
      .makeAsyncIterator()
    #expect(try await custom.next() == value)
    #expect(try await custom.next() == nil)
    #expect(transport.requests.count == 5)
  }

  @Test(
    "Changed and unsafe links fail before another fetch",
    arguments: [
      "http://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2",
      "https://evil.example/api/v1/public_inspection_documents?page=2&per_page=2",
      "https://user@www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2",
      "https://www.federalregister.gov:444/api/v1/public_inspection_documents?page=2&per_page=2",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2#x",
      "https://www.federalregister.gov/api/v1/public-inspection-documents/current.json?page=2&per_page=2",
      "https://www.federalregister.gov/api/v1/public-inspection-documents/a,b.json?page=2&per_page=2",
      "https://www.federalregister.gov/api/v1/documents.json?page=2&per_page=2",
      "https://www.federalregister.gov/api/v1/issues/2024-12-31.json?page=2&per_page=2",
      "https://www.federalregister.gov/api/v1/public-inspection-documents/%2f.json?page=2&per_page=2",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=1&per_page=2",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&page=3&per_page=2",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=3",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&action=other",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&action=index&action=index",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&controller=other",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&controller=api%2Fv1%2Fpublic_inspection_documents&controller=api%2Fv1%2Fpublic_inspection_documents",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&format=xml",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&format=json&format=json",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&search_after_cursor=x",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?per_page=2",
      "https://www.federalregister.gov/api/v1/public_inspection_documents?page=2&per_page=2&unknown=1",
      "https://www.federalregister.gov/api/v1/public-inspection-documents?page=2&per_page=2&action=index",
    ])
  func invalidLinks(_ link: String) async throws {
    let body = try changed(.inspectionSearch) { $0["next_page_url"] = link }
    let transport = makeTransport([body])
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    var iterator = client.publicInspectionPages(searching: try .init(pageSize: 2))
      .makeAsyncIterator()
    do throws(FederalRegisterError) {
      _ = try await iterator.next(); Issue.record("Expected pagination failure")
    } catch {
      guard case .pagination = error else { Issue.record("Wrong failure"); return }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Later HTTP and decoding errors preserve already yielded data and finish",
    arguments: [false, true])
  func laterFailures(_ decoding: Bool) async throws {
    let transport = MockTransport(results: [
      .success(Response(body: try Fixture.inspectionSearch.data(), status: .ok)),
      .success(Response(body: Data("failure".utf8), status: decoding ? .ok : .tooManyRequests)),
    ])
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    var iterator = client.publicInspectionPages(searching: try .init(pageSize: 2))
      .makeAsyncIterator()
    #expect(
      try await iterator.next()?.results.map(\.documentNumber) == ["2026-19930", "2026-19936"])
    do throws(FederalRegisterError) {
      _ = try await iterator.next(); Issue.record("Expected failure")
    } catch {
      if decoding {
        guard case .decoding = error else { Issue.record("Wrong failure"); return }
      } else {
        guard case .transport(.httpStatus(let body, let code, _)) = error else {
          Issue.record("Wrong failure"); return
        }
        #expect(body == Data("failure".utf8))
        #expect(code == 429)
      }
    }
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Lazy items preserve order and duplicates, ignore capped totals and never prefetch")
  func laziness() async throws {
    let first = try changed(.inspectionSearch) { $0["total_pages"] = 1 }
    let second = try changed(.inspectionSearchTwo) { $0["next_page_url"] = NSNull() }
    let transport = makeTransport([first, second])
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let sequence = client.publicInspectionDocuments(searching: try .init(pageSize: 2))
    var iterator = sequence.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    var numbers: [String] = []
    var counts: [Int] = []
    while let item = try await iterator.next() {
      numbers.append(item.documentNumber)
      counts.append(transport.requests.count)
    }
    #expect(numbers == ["2026-19930", "2026-19936", "2026-19932", "2026-19931"])
    #expect(counts == [1, 1, 2, 2])
    #expect(try await iterator.next() == nil)
    let duplicate = try changed(.inspectionSearch) {
      let results = $0["results"] as? [Any] ?? []
      $0["results"] = results + results
      $0["next_page_url"] = NSNull()
    }
    let dupTransport = makeTransport([duplicate])
    let dupClient = FederalRegisterClient(transport: dupTransport, userAgent: "test")
    var duplicates: [String] = []
    for try await item in dupClient.publicInspectionDocuments(searching: try .init(pageSize: 2)) {
      duplicates.append(item.documentNumber)
    }
    #expect(duplicates == ["2026-19930", "2026-19936", "2026-19930", "2026-19936"])
    let earlyTransport = makeTransport([first])
    let earlyClient = FederalRegisterClient(transport: earlyTransport, userAgent: "test")
    for try await _ in earlyClient.publicInspectionDocuments(searching: try .init(pageSize: 2)) {
      break
    }
    #expect(earlyTransport.requests.count == 1)
  }

  @Test("Synthetic invalid metadata and zero results retain structural rules")
  func metadata() async throws {
    let zero = try PublicInspectionPage.decode(Fixture.inspectionZero.data())
    #expect(zero.results == [])
    #expect(zero.totalPages == nil)
    for json in [#"{"count":0,"results":null}"#, #"{"count":1}"#] {
      #expect(throws: (any Error).self) { try PublicInspectionPage.decode(Data(json.utf8)) }
    }
    for negative in [false, true] {
      let body = try changed(.inspectionSearch) {
        if negative { $0["count"] = -1 } else { $0["results"] = [Any]() }
      }
      let page = try PublicInspectionPage.decode(body)
      #expect(throws: DocumentPaginationError.invalidMetadata) {
        try page.continuation(after: .searchPublicInspectionDocuments(matching: .init(pageSize: 2)))
      }
    }
  }

  @Test("Filtered captures and exact query inputs retain fields, false and literal plus")
  func query() throws {
    let query = try PublicInspectionQuery(
      fields: [.title], pageSize: 2, specialFiling: .regular, types: [.notice])
    let endpoint = Endpoint<PublicInspectionPage>.searchPublicInspectionDocuments(matching: query)
    #expect(
      endpoint.path
        == "/api/v1/public-inspection-documents.json?conditions%5Bspecial_filing%5D=0&conditions%5Btype%5D%5B%5D=NOTICE&fields%5B%5D=document_number&fields%5B%5D=title&per_page=2"
    )
    let first = try PublicInspectionPage.decode(Fixture.inspectionFilteredFields.data())
    let next = try #require(try first.continuation(after: endpoint))
    let second = try PublicInspectionPage.decode(Fixture.inspectionFilteredFieldsTwo.data())
    #expect(try second.continuation(after: next) != nil)
    #expect(
      try Endpoint<PublicInspectionPage>.searchPublicInspectionDocuments(
        matching: .init(term: "a+b é")
      ).path
        == "/api/v1/public-inspection-documents.json?conditions%5Bterm%5D=a%2Bb%20%C3%A9&per_page=20"
    )
    #expect(throws: DocumentValidationError.invalidPageSize(0)) {
      try PublicInspectionQuery(pageSize: 0)
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("fields")) {
      try PublicInspectionQuery(fields: [.init(rawValue: "")])
    }
  }

  @Test("Receipts and independent iterators perform exactly their own fetches")
  func receiptsAndIndependence() async throws {
    let one = try Fixture.inspectionSearch.data()
    let two = try Fixture.inspectionSearchTwo.data()
    let transport = makeTransport([one, one, two, two])
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let receipts = client.publicInspectionResponses(searching: try .init(pageSize: 2))
    var a = receipts.makeAsyncIterator()
    var b = receipts.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    #expect(try await a.next()?.body == one)
    #expect(try await b.next()?.body == one)
    let second = try await a.next()
    #expect(second?.body == two)
    #expect(second?.requestURL == Self.next)
    #expect(try await b.next()?.body == two)
    #expect(transport.requests.count == 4)
  }

  // Synthetic modifications to attributed recordings carry no new capture provenance.
  private func changed(_ fixture: Fixture, _ edit: (inout [String: Any]) -> Void) throws -> Data {
    var object = try #require(JSONSerialization.jsonObject(with: fixture.data()) as? [String: Any])
    edit(&object)
    return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }

  private func makeTransport(_ bodies: [Data]) -> MockTransport {
    MockTransport(results: bodies.map { .success(Response(body: $0, status: .ok)) })
  }
}

private final class InspectionRunningTask: Sendable {
  let task = Mutex<Task<FederalRegisterError?, Never>?>(nil)
}
