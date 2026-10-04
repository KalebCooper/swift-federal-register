import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ExpandedQueryTests {
  @Test("Combined conditions encode exact strings and retain duplicate values")
  func combined() throws {
    let query = try DocumentSearchQuery(
      near: .init(location: "Chicago, IL + é", withinMiles: 25), order: .executiveOrderNumber,
      sections: [.environment, .environment], significant: false,
      topics: [.init(rawValue: "air-pollution-control"), .init(rawValue: "future&topic")])
    #expect(
      Endpoint<DocumentPage>.searchDocuments(matching: query).path
        == "/api/v1/documents.json?conditions%5Bnear%5D%5Blocation%5D=Chicago%2C%20IL%20%2B%20%C3%A9&conditions%5Bnear%5D%5Bwithin%5D=25&conditions%5Bsections%5D%5B%5D=environment&conditions%5Bsections%5D%5B%5D=environment&conditions%5Bsignificant%5D=0&conditions%5Btopics%5D%5B%5D=air-pollution-control&conditions%5Btopics%5D%5B%5D=future%26topic&order=executive_order_number&per_page=20"
    )
    #expect(try DocumentLocation(location: "60601").withinMiles == nil)
    #expect(try DocumentLocation(location: "60601", withinMiles: 1).withinMiles == 1)
    #expect(try DocumentLocation(location: "60601", withinMiles: 200).withinMiles == 200)
  }

  @Test("Captured geographic and EO searches continue without changing order")
  func continuations() throws {
    for fixture in [Fixture.geographic, .executiveOrder, .eoTerm] {
      let page = try DocumentPage.decode(fixture.data())
      let next = try #require(page.nextPageURL)
      var parts = try #require(URLComponents(string: next))
      parts.queryItems = parts.queryItems?.filter {
        !["page", "search_after_cursor", "format"].contains($0.name)
      }
      let link = try #require(parts.string)
      let first = try #require(Endpoint<DocumentPage>(link: link))
      #expect(try page.continuation(after: first, seenCursors: []) != nil)
    }
    let first = try DocumentPage.decode(Fixture.executiveOrder.data())
    let second = try DocumentPage.decode(Fixture.executiveOrderTwo.data())
    #expect(first.results.map(\.executiveOrderNumber) == [nil, nil])
    #expect(second.results.map(\.executiveOrderNumber) == ["12890", "12891"])
  }

  @Test("Invalid radii and text fail", arguments: [-1, 0, 201])
  func invalidRadius(_ miles: Int) {
    #expect(throws: DocumentValidationError.invalidDistanceMiles(miles)) {
      try DocumentLocation(location: "60601", withinMiles: miles)
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("location")) {
      try DocumentLocation(location: "")
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("topics")) {
      try DocumentSearchQuery(topics: [.init(rawValue: "\n")])
    }
  }

  @Test("Open presidential values preserve literal plus and reserved characters")
  func presidentialEncoding() throws {
    let query = try DocumentQuery(
      president: "A+B & é",
      presidentialDocumentType: .init(rawValue: "future+type"))
    #expect(
      Endpoint<DocumentPage>.presidentialDocuments(matching: query).path
        == "/api/v1/documents.json?conditions%5Bpresident%5D%5B%5D=A%2BB%20%26%20%C3%A9&conditions%5Bpresidential_document_type%5D%5B%5D=future%2Btype&conditions%5Btype%5D%5B%5D=PRESDOCU&order=newest&per_page=20"
    )
  }

  @Test("Typed subtype preserves unknown values, nil and existing query defaults")
  func subtype() throws {
    let order: DocumentQuery.Order = .newest
    let original = try DocumentQuery(order: order)
    #expect(
      Endpoint<DocumentPage>.presidentialDocuments(matching: original).path
        == "/api/v1/documents.json?conditions%5Btype%5D%5B%5D=PRESDOCU&order=newest&per_page=20")
    #expect(
      try DocumentQuery(presidentialDocumentType: .executiveOrder).presidentialDocumentType?
        .rawValue == "executive_order")
    let future = PresidentialDocumentTypeCode(rawValue: "future")
    #expect(
      try JSONDecoder().decode(
        PresidentialDocumentTypeCode.self, from: JSONEncoder().encode(future)) == future)
    #expect(try DocumentQuery(presidentialDocumentType: future).presidentialDocumentType == future)
    #expect(try DocumentQuery(presidentialDocumentType: nil).presidentialDocumentType == nil)
    #expect(try DocumentSearchQuery(order: order).order == .newest)
  }
}
