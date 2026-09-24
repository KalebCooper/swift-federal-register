import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DocumentModelsTests {
  @Test("Current document fields and unknown attributes survive a round trip")
  func currentDocumentFieldsAndUnknownAttributesSurviveARoundTrip() throws {
    let value = try FederalRegisterDocument.decode(Fixture.currentDocument.data())
    #expect(value.documentNumber == "2026-19417")
    #expect(value.executiveOrderNumber == "14430")
    #expect(value.publicationDate == "2026-09-22")
    #expect(value.signingDate == "2026-09-17")
    #expect(value.fields["images_metadata"] != nil)
    #expect(try FederalRegisterDocument.decode(JSONEncoder().encode(value)) == value)
  }

  @Test("Historical null links and contradictory dates remain distinct")
  func historicalNullLinksAndContradictoryDatesRemainDistinct() throws {
    let value = try FederalRegisterDocument.decode(Fixture.historicalDocument.data())
    #expect(value.pdfURL == nil)
    #expect(value.fullTextXMLURL == nil)
    #expect(value.fields["pdf_url"] == .null)
    #expect(value.fields["new_unpublished_field"] == nil)
    #expect(value.publicationDate == "1994-01-03")
    #expect(value.signingDate == "1993-12-18")
    #expect(value.tocDoc == "Presidential Determination 94-7 of December 19, 1993")
    #expect(throws: DocumentContentError.unavailable(.xml)) {
      try Endpoint<DocumentContent>.content(.xml, for: value)
    }
  }

  @Test("Models-only custom requests infer a concrete response")
  func modelsOnlyCustomRequestsInferAConcreteResponse() throws {
    let stored = try DocumentRequest.document("93-32104")
    let custom = DocumentRequest<CustomResponse>.init(
      endpoint: try #require(Endpoint(path: "/api/v1/documents/93-32104.json")))
    #expect(stored.endpoint.path == "/api/v1/documents/93-32104.json")
    #expect(custom == .historical)
    #expect(
      try CustomResponse.decode(Fixture.historicalDocument.data()).document_number == "93-32104")
  }

  @Test("Pagination follows cursors beyond capped totals and preserves the next query")
  func paginationFollowsCursorsBeyondCappedTotalsAndPreservesTheNextQuery() throws {
    let page = try DocumentPage.decode(Fixture.pageOne.data())
    let first = Endpoint<DocumentPage>.presidentialDocuments(
      matching: try DocumentQuery(pageSize: 2))
    let next = try #require(try page.continuation(after: first, seenCursors: []))
    #expect(page.count == 8582)
    #expect(page.totalPages == 50)
    #expect(next.cursor == "WzE3OTAxMjE2MDAwMDAsIjIwMjYtMTk1NTQiXQ")
    #expect(next.endpoint.path.contains("page=2&per_page=2&search_after_cursor="))
    #expect(throws: DocumentPaginationError.repeatedCursor(next.cursor)) {
      try page.continuation(after: first, seenCursors: [next.cursor])
    }
  }

  @Test("Source content keeps XML markup and historical HTML inside text responses")
  func sourceContentKeepsXMLMarkupAndHistoricalHTMLInsideTextResponses() throws {
    let xml = try DocumentContent.decode(Fixture.currentXML.data())
    #expect(xml.source.hasPrefix("<PRESDOCU>"))
    #expect(xml.source.contains("Executive Order 14430 of September 17, 2026"))
    let text = try DocumentContent.decode(Fixture.historicalText.data())
    #expect(text.source.hasPrefix("<html>"))
    #expect(text.source.contains("Washington, December 18, 1993."))
    #expect(Data(text.source.utf8) == (try Fixture.historicalText.data()))
    #expect(throws: DocumentContentError.invalidUTF8) { try DocumentContent.decode(Data([0xFF])) }
  }

  @Test("Terminal historical pages omit continuation without inventing formats")
  func terminalHistoricalPagesOmitContinuationWithoutInventingFormats() throws {
    let page = try DocumentPage.decode(Fixture.historicalPage.data())
    #expect(page.count == 1)
    #expect(page.nextPageURL == nil)
    #expect(page.results.first?.pdfURL == nil)
    #expect(
      try page.continuation(
        after: .presidentialDocuments(matching: DocumentQuery()), seenCursors: []) == nil)
  }

  @Test(
    "Unsafe origins and paths are rejected",
    arguments: [
      "https://evil.example/api/v1/documents.json",
      "http://www.federalregister.gov/api/v1/documents.json",
      "https://user@www.federalregister.gov/api/v1/documents.json",
      "https://www.federalregister.gov/api/v1/documents.json#fragment",
      "https://www.federalregister.gov:444/api/v1/documents.json",
      "https://www.federalregister.gov/api/v1/documents/../agencies",
      "https://www.federalregister.gov/api/v1/documents/%2e%2e/agencies",
      "https://www.federalregister.gov/api/v1/documents/%252e%252e/agencies",
      "https://www.federalregister.gov/api/v1/documents/%2fother",
      "https://www.federalregister.gov/api/v1/documents/%5cother",
    ])
  func unsafeOriginsAndPathsAreRejected(_ link: String) {
    #expect(Endpoint<DocumentPage>(link: link) == nil)
  }

  @Test("Validation rejects impossible dates and page sizes")
  func validationRejectsImpossibleDatesAndPageSizes() throws {
    #expect(throws: DocumentValidationError.invalidPageSize(0)) { try DocumentQuery(pageSize: 0) }
    #expect(throws: DocumentValidationError.invalidPageSize(1001)) {
      try DocumentQuery(pageSize: 1001)
    }
    #expect(throws: DocumentValidationError.invalidDate("1900-02-29")) {
      try DocumentQuery(publishedFrom: "1900-02-29")
    }
    #expect(throws: DocumentValidationError.reversedDates) {
      try DocumentQuery(publishedFrom: "1994-02-01", publishedThrough: "1994-01-01")
    }
    #expect(try DocumentQuery(publishedFrom: "1789-04-30").publishedFrom == "1789-04-30")
    #expect(try DocumentQuery(publishedFrom: "2000-02-29").pageSize == 20)
    #expect(throws: DocumentValidationError.invalidDocumentNumber("../escape")) {
      try Endpoint<FederalRegisterDocument>.document("../escape")
    }
  }
}

private struct CustomResponse: Codable, DocumentResponse { let document_number: String }
extension DocumentRequest where Response == CustomResponse {
  fileprivate static var historical: Self {
    Self(endpoint: Endpoint(path: "/api/v1/documents/93-32104.json")!)
  }
}
