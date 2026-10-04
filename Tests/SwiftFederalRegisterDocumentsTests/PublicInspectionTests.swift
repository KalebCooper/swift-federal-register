import Foundation
import HTTPCore
import HTTPTesting
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct PublicInspectionTests {
  @Test("All one-shot inspection operations have equivalent request and receipt levels")
  func equivalence() async throws {
    try await check(
      .inspectionCurrent, request: .currentPublicInspectionDocuments(),
      path: "/api/v1/public-inspection-documents/current.json"
    ) { try await $0.currentPublicInspectionDocuments() }
    try await check(
      .inspectionDateOnly, request: .publicInspectionDocuments(availableOn: "2024-12-30"),
      path: "/api/v1/public-inspection-documents.json?conditions%5Bavailable_on%5D=2024-12-30"
    ) {
      try await $0.publicInspectionDocuments(availableOn: "2024-12-30")
    }
    try await check(
      .inspectionDetail, request: .publicInspectionDocument("2026-19958"),
      path: "/api/v1/public-inspection-documents/2026-19958.json"
    ) { try await $0.publicInspectionDocument("2026-19958") }
    try await check(
      .inspectionBatch,
      request: .publicInspectionDocuments(numbered: ["2026-19958", "2026-19957"]),
      path: "/api/v1/public-inspection-documents/2026-19958,2026-19957.json"
    ) {
      try await $0.publicInspectionDocuments(numbered: ["2026-19958", "2026-19957"])
    }
  }

  @Test("Inspection source whitespace, date offsets and PDF metadata survive")
  func fields() throws {
    let body = try Fixture.inspectionDetail.data()
    let value = try PublicInspectionDocument.decode(body)
    #expect(value.title == "Meetings; Sunshine Act  ")
    #expect(value.filedAt == "2026-09-28T11:15:00.000-04:00")
    #expect(value.publicationDate == "2026-09-30")
    #expect(value.pdfUpdatedAt == "2026-09-28T11:15:08.000-04:00")
    #expect(value.pdfFileSize == 55043)
    #expect(value.numberOfPages == 1)
    #expect(value.filingType == .special)
    #expect(value.fields["editorial_note"] == .null)
    #expect(
      try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
        == JSONDecoder().decode(JSONValue.self, from: body))
    let synthetic = try PublicInspectionDocument.decode(
      Data(
        #"{"document_number":"future","title":" ","publication_date":null,"filed_at":"unchanged","filing_type":"future","num_pages":1.5,"pdf_file_size":"2","agencies":[{},false],"withdrawn":true}"#
          .utf8))
    #expect(synthetic.publicationDate == nil)
    #expect(synthetic.numberOfPages == nil)
    #expect(synthetic.pdfFileSize == nil)
    #expect(synthetic.agencies == nil)
    #expect(synthetic.filingType?.rawValue == "future")
    #expect(synthetic.fields["withdrawn"] == .bool(true))
  }

  @Test("Listings and batches retain distinct empty and singleton shapes")
  func shapes() throws {
    let current = try PublicInspectionListing.decode(Fixture.inspectionCurrent.data())
    #expect(current.count == 127)
    #expect(current.regularFilingsUpdatedAt != nil)
    #expect(current.specialFilingsUpdatedAt != nil)
    let dated = try PublicInspectionListing.decode(Fixture.inspectionDateOnly.data())
    #expect(dated.count == 113)
    #expect(try PublicInspectionListing.decode(Fixture.inspectionDateEmpty.data()).results == [])
    let missing = try PublicInspectionBatch.decode(Fixture.inspectionBatchAllMissing.data())
    #expect(missing.count == 0)
    #expect(missing.results == [])
    #expect(missing.errors?.notFound?.isEmpty == false)
    let singleton = try PublicInspectionBatch.decode(Fixture.inspectionBatchSingle.data())
    #expect(singleton.count == nil)
    #expect(singleton.results.count == 1)
    #expect(singleton.fields["results"] == nil)
    let partial = try PublicInspectionBatch.decode(Fixture.inspectionBatchMissing.data())
    #expect(partial.results.count == 1)
    #expect(partial.errors?.notFound?.isEmpty == false)
  }

  @Test("Inspection input and custom paths reject unsafe routes")
  func validation() async throws {
    for path in [
      "/api/v1/public_inspection_documents/current.json",
      "/api/v1/public-inspection-documents/a/b.json",
      "/api/v1/public-inspection-documents/a,,b.json",
      "/api/v1/public-inspection-documents/%2f.json",
    ] {
      #expect(Endpoint<PublicInspectionDocument>(path: path) == nil)
    }
    let transport = MockTransport()
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    do {
      _ = try await client.publicInspectionDocuments(numbered: []);
      Issue.record("Expected validation")
    } catch {
      guard case .validation(.emptyDocumentNumbers) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    do {
      _ = try await client.publicInspectionDocuments(availableOn: "2024-02-30");
      Issue.record("Expected validation")
    } catch {
      guard case .validation(.invalidDate) = error else { Issue.record("Wrong failure"); return }
    }
    do {
      _ = try await client.publicInspectionDocument("a/b"); Issue.record("Expected validation")
    } catch {
      guard case .validation(.invalidDocumentNumber) = error else {
        Issue.record("Wrong failure"); return
      }
    }
    #expect(transport.requests.isEmpty)
  }

  private func check<Value: DocumentResponse & Equatable>(
    _ fixture: Fixture, request: DocumentRequest<Value>, path: String,
    everyday: (FederalRegisterClient) async throws -> Value
  ) async throws {
    let body = try fixture.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = FederalRegisterClient(transport: transport, userAgent: "test")
    let value = try await everyday(client)
    #expect(try await client.value(for: request) == value)
    #expect(try await client.send(request.endpoint) == value)
    let receipt = try await client.response(for: request)
    #expect(receipt.body == body)
    #expect(receipt.value == value)
    #expect(transport.requests.count == 4)
    #expect(transport.requests.allSatisfy { $0.request.path == path })
  }
}
