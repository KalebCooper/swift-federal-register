import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

/// One general search recorded on 2026-09-26 with the package User-Agent, paired with the query
/// that describes it. Every capture carried `per_page=2` and the inclusive 2024 publication range
/// beside the single filter under test, so each query states those too. The shipped
/// Fixtures/receipts.json holds the newest, oldest, and term captures; the other URLs are the
/// recorded request lines of captures whose bodies were not promoted to fixtures.
enum RecordedSearch: CaseIterable, Sendable {
  case agency, cfrPart, cfrRange, cfrTitle, docket, effectiveRange, effectiveYear, newest, oldest
  case rin, term, types

  private static let base =
    "https://www.federalregister.gov/api/v1/documents.json?order=newest&per_page=2"
    + "&conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
    + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31"

  var url: String {
    switch self {
    case .agency: Self.base + "&conditions%5Bagencies%5D%5B%5D=environmental-protection-agency"
    case .cfrPart: Self.base + "&conditions%5Bcfr%5D%5Btitle%5D=40&conditions%5Bcfr%5D%5Bpart%5D=52"
    case .cfrRange:
      Self.base + "&conditions%5Bcfr%5D%5Btitle%5D=40&conditions%5Bcfr%5D%5Bpart%5D=1-50"
    case .cfrTitle: Self.base + "&conditions%5Bcfr%5D%5Btitle%5D=40"
    case .docket: Self.base + "&conditions%5Bdocket_id%5D=EPA-R09-OAR-2023-0649"
    case .effectiveRange:
      Self.base + "&conditions%5Beffective_date%5D%5Bgte%5D=2024-01-01"
        + "&conditions%5Beffective_date%5D%5Blte%5D=2024-12-31"
    case .effectiveYear: Self.base + "&conditions%5Beffective_date%5D%5Byear%5D=2024"
    case .newest: Self.base
    case .oldest:
      "https://www.federalregister.gov/api/v1/documents.json?order=oldest&per_page=2"
        + "&conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
        + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31"
    case .rin: Self.base + "&conditions%5Bregulation_id_number%5D=2060-AS35"
    case .term: Self.base + "&conditions%5Bterm%5D=water"
    case .types: Self.base + "&conditions%5Btype%5D%5B%5D=RULE&conditions%5Btype%5D%5B%5D=PRORULE"
    }
  }

  func query() throws -> DocumentSearchQuery {
    let year2024 = try DocumentDateFilter.range(from: "2024-01-01", through: "2024-12-31")
    switch self {
    case .agency:
      return try DocumentSearchQuery(
        agencies: [.environmentalProtectionAgency], pageSize: 2, publicationDate: year2024)
    case .cfrPart:
      return try DocumentSearchQuery(
        cfr: CFRFilter(part: "52", title: 40), pageSize: 2, publicationDate: year2024)
    case .cfrRange:
      return try DocumentSearchQuery(
        cfr: CFRFilter(part: "1-50", title: 40), pageSize: 2, publicationDate: year2024)
    case .cfrTitle:
      return try DocumentSearchQuery(
        cfr: CFRFilter(title: 40), pageSize: 2, publicationDate: year2024)
    case .docket:
      return try DocumentSearchQuery(
        docketID: "EPA-R09-OAR-2023-0649", pageSize: 2, publicationDate: year2024)
    case .effectiveRange:
      return try DocumentSearchQuery(
        effectiveDate: year2024, pageSize: 2, publicationDate: year2024)
    case .effectiveYear:
      return try DocumentSearchQuery(
        effectiveDate: .inYear(2024), pageSize: 2, publicationDate: year2024)
    case .newest:
      return try DocumentSearchQuery(pageSize: 2, publicationDate: year2024)
    case .oldest:
      return try DocumentSearchQuery(order: .oldest, pageSize: 2, publicationDate: year2024)
    case .rin:
      return try DocumentSearchQuery(
        pageSize: 2, publicationDate: year2024, regulationIDNumber: "2060-AS35")
    case .term:
      return try DocumentSearchQuery(pageSize: 2, publicationDate: year2024, term: "water")
    case .types:
      return try DocumentSearchQuery(
        pageSize: 2, publicationDate: year2024, types: [.rule, .proposedRule])
    }
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DocumentSearchQueryTests {
  /// Decodes a recorded request URL's query into name and value pairs sorted like `queryItems`.
  private func recordedItems(_ url: String) throws -> [URLQueryItem] {
    let items = try #require(URLComponents(string: url)?.queryItems)
    return items.sorted { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
  }

  @Test("A combined search encodes deterministically and keeps repeated values")
  func aCombinedSearchEncodesDeterministicallyAndKeepsRepeatedValues() throws {
    let search = try DocumentSearchQuery(
      agencies: [.environmentalProtectionAgency],
      cfr: CFRFilter(part: "1-50", title: 40),
      publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "water",
      types: [.proposedRule, .rule])
    #expect(
      search.queryItems == [
        URLQueryItem(name: "conditions[agencies][]", value: "environmental-protection-agency"),
        URLQueryItem(name: "conditions[cfr][part]", value: "1-50"),
        URLQueryItem(name: "conditions[cfr][title]", value: "40"),
        URLQueryItem(name: "conditions[publication_date][gte]", value: "2024-01-01"),
        URLQueryItem(name: "conditions[publication_date][lte]", value: "2024-12-31"),
        URLQueryItem(name: "conditions[term]", value: "water"),
        URLQueryItem(name: "conditions[type][]", value: "PRORULE"),
        URLQueryItem(name: "conditions[type][]", value: "RULE"),
        URLQueryItem(name: "order", value: "newest"),
        URLQueryItem(name: "per_page", value: "20"),
      ])
    let reordered = try DocumentSearchQuery(
      agencies: [.environmentalProtectionAgency],
      cfr: CFRFilter(part: "1-50", title: 40),
      publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "water",
      types: [.rule, .proposedRule])
    #expect(reordered.queryItems == search.queryItems)
    let repeated = try DocumentSearchQuery(
      agencies: [.environmentalProtectionAgency, .environmentalProtectionAgency],
      types: [.rule, .rule, .proposedRule])
    #expect(
      repeated.queryItems == [
        URLQueryItem(name: "conditions[agencies][]", value: "environmental-protection-agency"),
        URLQueryItem(name: "conditions[agencies][]", value: "environmental-protection-agency"),
        URLQueryItem(name: "conditions[type][]", value: "PRORULE"),
        URLQueryItem(name: "conditions[type][]", value: "RULE"),
        URLQueryItem(name: "conditions[type][]", value: "RULE"),
        URLQueryItem(name: "order", value: "newest"),
        URLQueryItem(name: "per_page", value: "20"),
      ])
  }

  @Test(
    "A CFR part is a nonnegative integer or an ascending range in ASCII digits",
    arguments: [
      ("0", true), ("52", true), ("1-50", true), ("007-10", true), ("50-50", true),
      ("99999999999999999999-100000000000000000000", true),
      ("50-1", false), ("1a", false), (" 52", false), ("", false), ("1-", false), ("-5", false),
      ("1-2-3", false), ("52 ", false), ("+1", false), ("٥", false),
    ])
  func aCFRPartIsANonnegativeIntegerOrAnAscendingRangeInASCIIDigits(_ part: String, _ valid: Bool)
    throws
  {
    if valid {
      let filter = try CFRFilter(part: part, title: 40)
      #expect(filter.part == part)
      #expect(filter.title == 40)
    } else {
      #expect(throws: DocumentValidationError.invalidCFRFilter(part)) {
        try CFRFilter(part: part, title: 40)
      }
    }
  }

  @Test("A CFR title must be at least 1 and a part is optional")
  func aCFRTitleMustBeAtLeast1AndAPartIsOptional() throws {
    #expect(throws: DocumentValidationError.invalidCFRFilter("0")) { try CFRFilter(title: 0) }
    #expect(throws: DocumentValidationError.invalidCFRFilter("-3")) {
      try CFRFilter(part: "52", title: -3)
    }
    let title = try CFRFilter(title: 1)
    #expect(title.part == nil)
    #expect(title.title == 1)
    #expect(try CFRFilter(part: "52", title: 40) == CFRFilter(part: "52", title: 40))
  }

  @Test(
    "A date filter accepts only real Gregorian dates",
    arguments: [
      ("2024-02-29", true), ("2023-02-29", false), ("1900-02-29", false), ("2000-02-29", true),
      ("0001-01-01", true), ("9999-12-31", true), ("0000-01-01", false), ("2024-13-01", false),
      ("2024-04-31", false), ("2024-1-01", false), ("2024/01/01", false), ("2024-01-01 ", false),
    ])
  func aDateFilterAcceptsOnlyRealGregorianDates(_ date: String, _ valid: Bool) throws {
    if valid {
      #expect(try DocumentDateFilter.on(date).form == .exact(date))
      #expect(
        try DocumentDateFilter.range(from: date, through: nil).form
          == .range(from: date, through: nil))
    } else {
      #expect(throws: DocumentValidationError.invalidDate(date)) { try DocumentDateFilter.on(date) }
      #expect(throws: DocumentValidationError.invalidDate(date)) {
        try DocumentDateFilter.range(from: nil, through: date)
      }
    }
  }

  @Test("A date range needs at least one bound and ordered bounds")
  func aDateRangeNeedsAtLeastOneBoundAndOrderedBounds() throws {
    #expect(throws: DocumentValidationError.invalidDateRange) {
      try DocumentDateFilter.range(from: nil, through: nil)
    }
    #expect(throws: DocumentValidationError.invalidDateRange) {
      try DocumentDateFilter.range(from: "2024-01-02", through: "2024-01-01")
    }
    #expect(
      try DocumentDateFilter.range(from: "2024-01-01", through: "2024-01-01").form
        == .range(from: "2024-01-01", through: "2024-01-01"))
    #expect(
      try DocumentDateFilter.range(from: nil, through: "2024-12-31").form
        == .range(from: nil, through: "2024-12-31"))
    #expect(
      try DocumentDateFilter.range(from: "2024-01-01", through: nil)
        == DocumentDateFilter.range(from: "2024-01-01", through: nil))
  }

  @Test("A defaulted search sends only its order and page size")
  func aDefaultedSearchSendsOnlyItsOrderAndPageSize() throws {
    let query = try DocumentSearchQuery()
    #expect(
      query.queryItems == [
        URLQueryItem(name: "order", value: "newest"), URLQueryItem(name: "per_page", value: "20"),
      ])
    #expect(query.agencies.isEmpty)
    #expect(query.cfr == nil)
    #expect(query.docketID == nil)
    #expect(query.effectiveDate == nil)
    #expect(query.order == .newest)
    #expect(query.pageSize == 20)
    #expect(query.publicationDate == nil)
    #expect(query.regulationIDNumber == nil)
    #expect(query.term == nil)
    #expect(query.types.isEmpty)
    #expect(throws: DocumentValidationError.invalidPageSize(0)) {
      try DocumentSearchQuery(pageSize: 0)
    }
    #expect(throws: DocumentValidationError.invalidPageSize(1001)) {
      try DocumentSearchQuery(pageSize: 1001)
    }
  }

  @Test("A publication day filter sends the exact-date condition")
  func aPublicationDayFilterSendsTheExactDateCondition() throws {
    // Recorded 2026-09-26 with the package User-Agent. The capture also carried the 2024 range
    // beside the exact day; a filter holds one form, so only the shared items are compared.
    let recorded = try recordedItems(
      "https://www.federalregister.gov/api/v1/documents.json?order=newest&per_page=2"
        + "&conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
        + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31"
        + "&conditions%5Bpublication_date%5D%5Bis%5D=2024-12-31")
    let query = try DocumentSearchQuery(pageSize: 2, publicationDate: .on("2024-12-31"))
    let expected = [
      URLQueryItem(name: "conditions[publication_date][is]", value: "2024-12-31"),
      URLQueryItem(name: "order", value: "newest"),
      URLQueryItem(name: "per_page", value: "2"),
    ]
    #expect(query.queryItems == expected)
    #expect(Set(recorded).isSuperset(of: expected))
    #expect(recorded.count == expected.count + 2)
  }

  @Test(
    "A search filter value must be nonempty without control characters",
    arguments: ["", "\u{0}", "a\tb", "a\u{7F}", "a\u{85}b"])
  func aSearchFilterValueMustBeNonemptyWithoutControlCharacters(_ value: String) throws {
    #expect(throws: DocumentValidationError.emptyFilterValue("agencies")) {
      try DocumentSearchQuery(agencies: [AgencyIdentifier(rawValue: value)])
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("docketID")) {
      try DocumentSearchQuery(docketID: value)
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("regulationIDNumber")) {
      try DocumentSearchQuery(regulationIDNumber: value)
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("term")) {
      try DocumentSearchQuery(term: value)
    }
    #expect(throws: DocumentValidationError.emptyFilterValue("types")) {
      try DocumentSearchQuery(types: [DocumentTypeCode(rawValue: value)])
    }
  }

  @Test("A term keeps its exact spelling and an absent term sends nothing")
  func aTermKeepsItsExactSpellingAndAnAbsentTermSendsNothing() throws {
    let term = #"clean "water" & air + soil / élan ñ 水"#
    let query = try DocumentSearchQuery(term: term)
    #expect(query.term == term)
    #expect(query.queryItems.contains(URLQueryItem(name: "conditions[term]", value: term)))
    #expect(try DocumentSearchQuery(term: " ").term == " ")
    #expect(!(try DocumentSearchQuery().queryItems.contains { $0.name == "conditions[term]" }))
  }

  @Test("A year filter accepts 1 through 9999", arguments: [0, 10000, -1, Int.min, Int.max])
  func aYearFilterAccepts1Through9999(_ year: Int) {
    #expect(throws: DocumentValidationError.invalidYear(year)) {
      try DocumentDateFilter.inYear(year)
    }
  }

  @Test("A year filter keeps its year", arguments: [1, 1994, 2025, 9999])
  func aYearFilterKeepsItsYear(_ year: Int) throws {
    #expect(try DocumentDateFilter.inYear(year).form == .year(year))
  }

  @Test(
    "Each recorded single filter reproduces its captured request items",
    arguments: RecordedSearch.allCases)
  func eachRecordedSingleFilterReproducesItsCapturedRequestItems(_ search: RecordedSearch) throws {
    #expect(try search.query().queryItems == recordedItems(search.url))
  }

  @Test("Presidential query literals and validation are unchanged by the search filters")
  func presidentialQueryLiteralsAndValidationAreUnchangedByTheSearchFilters() throws {
    // Literal from the presidential-page-one.json receipt URL in Fixtures/receipts.json.
    #expect(
      Endpoint<DocumentPage>.presidentialDocuments(matching: try DocumentQuery(pageSize: 2)).path
        == "/api/v1/documents.json?conditions%5Btype%5D%5B%5D=PRESDOCU&order=newest&per_page=2")
    #expect(throws: DocumentValidationError.invalidDate("1900-02-29")) {
      try DocumentQuery(publishedFrom: "1900-02-29")
    }
    #expect(throws: DocumentValidationError.reversedDates) {
      try DocumentQuery(publishedFrom: "1994-02-01", publishedThrough: "1994-01-01")
    }
    #expect(try DocumentQuery(publishedFrom: "2000-02-29").publishedFrom == "2000-02-29")
  }

  @Test("Unknown agency slugs and type codes are sent unchanged")
  func unknownAgencySlugsAndTypeCodesAreSentUnchanged() throws {
    let query = try DocumentSearchQuery(
      agencies: [AgencyIdentifier(rawValue: "future-agency")],
      types: [DocumentTypeCode(rawValue: "FUTURE")])
    #expect(
      query.queryItems == [
        URLQueryItem(name: "conditions[agencies][]", value: "future-agency"),
        URLQueryItem(name: "conditions[type][]", value: "FUTURE"),
        URLQueryItem(name: "order", value: "newest"),
        URLQueryItem(name: "per_page", value: "20"),
      ])
  }

  /// A one-result page whose next link is the given literal; nil omits the key.
  private func page(next link: String?) throws -> DocumentPage {
    let next = link.map { #","next_page_url":""# + $0 + #"""# } ?? ""
    return try DocumentPage.decode(
      Data(
        (#"{"count":1"# + next
          + #","results":[{"document_number":"2024-31396","title":"Example"}],"total_pages":1}"#)
          .utf8))
  }

  @Test(
    "A general search endpoint reproduces each recorded request query byte for byte",
    arguments: RecordedSearch.allCases)
  func aGeneralSearchEndpointReproducesEachRecordedRequestQueryByteForByte(
    _ search: RecordedSearch
  ) throws {
    let endpoint = Endpoint<DocumentPage>.searchDocuments(matching: try search.query())
    let sent = endpoint.path.split(separator: "?", maxSplits: 1)
    let recorded = search.url.split(separator: "?", maxSplits: 1)
    #expect(sent[0] == "/api/v1/documents.json")
    #expect(recorded[0] == "https://www.federalregister.gov/api/v1/documents.json")
    #expect(
      sent[1].split(separator: "&").sorted() == recorded[1].split(separator: "&").sorted())
    #expect(endpoint.accept == "application/json")
  }

  @Test("A general search request resolves to its endpoint with cursor continuation")
  func aGeneralSearchRequestResolvesToItsEndpointWithCursorContinuation() throws {
    let query = try DocumentSearchQuery(agencies: [.environmentalProtectionAgency])
    let stored = DocumentRequest.searchDocuments(matching: query)
    let contextual: DocumentRequest<DocumentPage> = .searchDocuments(matching: query)
    let endpoint = Endpoint<DocumentPage>.searchDocuments(matching: query)
    #expect(stored.resolution == .documentSearch(endpoint))
    #expect(stored.endpoint == endpoint)
    #expect(contextual == stored)
    #expect(
      endpoint.path
        == "/api/v1/documents.json?conditions%5Bagencies%5D%5B%5D=environmental-protection-agency"
        + "&order=newest&per_page=20")
    let rules = try DocumentRequest.environmentalRules()
    let rulesEndpoint = try #require(
      Endpoint<DocumentPage>(
        path:
          "/api/v1/documents.json?conditions%5Bagencies%5D%5B%5D=environmental-protection-agency"
          + "&conditions%5Btype%5D%5B%5D=RULE&order=newest&per_page=20"))
    #expect(rules.resolution == .documentSearch(rulesEndpoint))
    #expect(continuationPolicy(of: stored.resolution) == "follows search cursors")
    #expect(
      continuationPolicy(of: DocumentRequest(endpoint: endpoint).resolution) == "single page")
    #expect(
      continuationPolicy(
        of: DocumentRequest.presidentialDocuments(matching: try DocumentQuery()).resolution)
        == "follows presidential cursors")
  }

  @Test("A general search sends a literal plus and reserved characters percent-encoded")
  func aGeneralSearchSendsALiteralPlusAndReservedCharactersPercentEncoded() throws {
    let term = "clean+water & air=soil; a?b#c%d/\u{E9}"
    let endpoint = Endpoint<DocumentPage>.searchDocuments(
      matching: try DocumentSearchQuery(term: term))
    #expect(
      endpoint.path
        == "/api/v1/documents.json?conditions%5Bterm%5D="
        + "clean%2Bwater%20%26%20air%3Dsoil%3B%20a%3Fb%23c%25d%2F%C3%A9&order=newest&per_page=20")
    #expect(!endpoint.path.contains("+"))
    let sent = try #require(
      URLComponents(string: "https://www.federalregister.gov" + endpoint.path)?.queryItems)
    #expect(sent.first { $0.name == "conditions[term]" }?.value == term)
  }

  @Test("A general search with a spaced term matches its recorded request exactly")
  func aGeneralSearchWithASpacedTermMatchesItsRecordedRequestExactly() throws {
    // Receipt URL of Fixtures/search-spaced-term-page-one.json.
    let query = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "clean water")
    #expect(
      Endpoint<DocumentPage>.searchDocuments(matching: query).path
        == "/api/v1/documents.json?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
        + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D=clean%20water"
        + "&order=newest&per_page=2")
    #expect(
      Endpoint<DocumentPage>.searchDocuments(matching: try RecordedSearch.newest.query()).path
        == "/api/v1/documents.json?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
        + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&order=newest&per_page=2")
  }

  @Test("A provider plus in a next link compares as a space and an escaped plus as a plus")
  func aProviderPlusInANextLinkComparesAsASpaceAndAnEscapedPlusAsAPlus() throws {
    let spaced = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "clean water")
    let recorded = try #require(
      try DocumentPage.decode(Fixture.searchSpacedTermPageOne.data()).nextPageURL)
    #expect(
      recorded
        == "https://www.federalregister.gov/api/v1/documents?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
        + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D=clean+water"
        + "&format=json&order=newest&page=2&per_page=2")
    // Synthetic: the recorded link with a cursor appended, so the query comparison is reached.
    let next = try #require(
      try page(next: recorded + "&search_after_cursor=abc").continuation(
        after: .searchDocuments(matching: spaced), seenCursors: []))
    #expect(next.cursor == "abc")
    // Synthetic links in the same shape for a term holding a literal plus.
    let root = "https://www.federalregister.gov/api/v1/documents?"
    let tail = "&format=json&order=newest&page=2&per_page=20&search_after_cursor=abc"
    let plus = try DocumentSearchQuery(term: "a+b")
    #expect(
      try page(next: root + "conditions%5Bterm%5D=a%2Bb" + tail).continuation(
        after: .searchDocuments(matching: plus), seenCursors: [])?.cursor == "abc")
    #expect(throws: DocumentPaginationError.changedQuery) {
      try page(next: root + "conditions%5Bterm%5D=a+b" + tail).continuation(
        after: .searchDocuments(matching: plus), seenCursors: [])
    }
  }

  @Test("A repeated fields selection survives the continuation comparison")
  func aRepeatedFieldsSelectionSurvivesTheContinuationComparison() throws {
    // Receipt URL of Fixtures/search-fields-page-one.json, rebuilt from its 56 field names.
    let fields = [
      "abstract", "action", "agencies", "agency_names", "amendatory_instructions", "body_html_url",
      "cfr_references", "cfr_topics", "citation", "comment_url", "comments_close_on",
      "correction_of", "corrections", "dates", "disposition_notes", "docket_id", "docket_ids",
      "dockets", "document_number", "effective_on", "end_page", "excerpts", "executive_order_notes",
      "executive_order_number", "explanation", "full_text_xml_url", "html_url", "images",
      "images_metadata", "json_url", "mods_url", "not_received_for_publication", "page_length",
      "page_views", "pdf_url", "president", "presidential_document_number", "proclamation_number",
      "public_inspection_pdf_url", "publication_date", "raw_text_url", "regulation_id_number_info",
      "regulation_id_numbers", "regulations_dot_gov_info", "regulations_dot_gov_url",
      "related_documents", "significant", "signing_date", "start_page", "subtype", "title",
      "toc_doc", "toc_subject", "topics", "type", "volume",
    ]
    let base =
      "https://www.federalregister.gov/api/v1/documents.json?order=newest&per_page=2"
      + "&conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
      + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31"
      + "&conditions%5Bagencies%5D%5B%5D=environmental-protection-agency"
      + "&conditions%5Btype%5D%5B%5D=RULE"
    let pageOne = try DocumentPage.decode(Fixture.searchFieldsPageOne.data())
    let pageTwo = try DocumentPage.decode(Fixture.searchFieldsPageTwo.data())
    let first = try #require(
      Endpoint<DocumentPage>(link: base + fields.map { "&fields%5B%5D=" + $0 }.joined()))
    let second = try #require(try pageOne.continuation(after: first, seenCursors: []))
    let secondCursor = try #require(second.cursor)
    #expect(secondCursor == "WzE3MzU1MTY4MDAwMDAsIjIwMjQtMzA3NDciXQ")
    #expect(
      "https://www.federalregister.gov" + second.endpoint.path == pageOne.nextPageURL)
    let third = try #require(
      try pageTwo.continuation(after: second.endpoint, seenCursors: [secondCursor]))
    #expect(third.cursor == "WzE3MzU1MTY4MDAwMDAsIjIwMjQtMzA3MzQiXQ")
    #expect("https://www.federalregister.gov" + third.endpoint.path == pageTwo.nextPageURL)
    let fewer = try #require(
      Endpoint<DocumentPage>(
        link: base + fields.dropLast().map { "&fields%5B%5D=" + $0 }.joined()))
    #expect(throws: DocumentPaginationError.changedQuery) {
      try pageOne.continuation(after: fewer, seenCursors: [])
    }
  }

  @Test("A search page without a next link ends continuation")
  func aSearchPageWithoutANextLinkEndsContinuation() throws {
    let endpoint = Endpoint<DocumentPage>.searchDocuments(matching: try DocumentSearchQuery())
    #expect(try page(next: nil).continuation(after: endpoint, seenCursors: []) == nil)
    let explicitNull = try DocumentPage.decode(
      Data(
        #"{"count":1,"next_page_url":null,"results":[{"document_number":"2024-31396","title":"Example"}],"total_pages":1}"#
          .utf8))
    #expect(try explicitNull.continuation(after: endpoint, seenCursors: []) == nil)
    // The recorded zero-match body carries only description and count.
    let terminal = try DocumentPage.decode(Fixture.searchTerminal.data())
    #expect(terminal.count == 0)
    #expect(terminal.results.isEmpty)
    #expect(terminal.totalPages == nil)
    #expect(terminal.nextPageURL == nil)
    #expect(
      terminal.fields["description"]
        == .string(
          "Documents matching 'codexNoMatchingDocument987654321' and published from 01/01/2024 to 12/31/2024"
        ))
    #expect(terminal.fields.count == 2)
    #expect(try terminal.continuation(after: endpoint, seenCursors: []) == nil)
    #expect(try DocumentPage.decode(JSONEncoder().encode(terminal)) == terminal)
  }

  @Test(
    "A page without results decodes only for a zero count",
    arguments: [
      #"{"count":1}"#, #"{"count":1,"total_pages":1}"#, #"{"count":0,"results":null}"#,
      #"{"description":"none"}"#,
    ])
  func aPageWithoutResultsDecodesOnlyForAZeroCount(_ body: String) throws {
    // Synthetic literals: no capture omits results beside a nonzero count or publishes a null results.
    #expect(throws: DecodingError.self) {
      try DocumentPage.decode(Data(body.utf8))
    }
  }

  @Test(
    "Search continuations refuse links outside the permitted search routes",
    arguments: [
      "https://www.federalregister.gov/api/v1/agencies.json?search_after_cursor=x",
      "https://www.federalregister.gov/api/v1/agencies/environmental-protection-agency.json?search_after_cursor=x",
      "https://www.federalregister.gov/api/v1/documents/2024-31396.json?search_after_cursor=x",
      "https://www.federalregister.gov/documents/full_text/text/2024/12/31/2024-31396.txt?search_after_cursor=x",
      "https://example.gov/api/v1/documents?order=newest&per_page=20&search_after_cursor=x",
      "https://example.gov/api/v1/documents?order=newest&per_page=20&page=2",
      "https://user:secret@www.federalregister.gov/api/v1/documents?order=newest&per_page=20&search_after_cursor=x",
      "https://www.federalregister.gov/api/v1/documents?order=newest&per_page=20&search_after_cursor=x#top",
      "http://www.federalregister.gov/api/v1/documents?order=newest&per_page=20&search_after_cursor=x",
      "https://www.federalregister.gov:8443/api/v1/documents?order=newest&per_page=20&search_after_cursor=x",
    ])
  func searchContinuationsRefuseLinksOutsideThePermittedSearchRoutes(_ link: String) throws {
    // Synthetic literals: no capture publishes a next link outside the documents search route.
    let endpoint = Endpoint<DocumentPage>.searchDocuments(matching: try DocumentSearchQuery())
    #expect(throws: DocumentPaginationError.invalidLink(link)) {
      try page(next: link).continuation(after: endpoint, seenCursors: [])
    }
  }

  @Test("Search continuations follow the recorded newest and oldest cursor links")
  func searchContinuationsFollowTheRecordedNewestAndOldestCursorLinks() throws {
    let shared =
      "/api/v1/documents?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
      + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&format=json&order="
    let recorded: [(Fixture, Fixture, RecordedSearch, [String], [String])] = [
      (
        .searchNewestPageOne, .searchNewestPageTwo, .newest,
        [
          shared
            + "newest&page=2&per_page=2&search_after_cursor=WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzkiXQ",
          shared
            + "newest&page=3&per_page=2&search_after_cursor=WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzciXQ",
        ],
        ["WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzkiXQ", "WzE3MzU2MDMyMDAwMDAsIjIwMjQtMzE0MzciXQ"]
      ),
      (
        .searchOldestPageOne, .searchOldestPageTwo, .oldest,
        [
          shared
            + "oldest&page=2&per_page=2&search_after_cursor=WzE3MDQxNTM2MDAwMDAsIjIwMjMtMjc3ODMiXQ",
          shared
            + "oldest&page=3&per_page=2&search_after_cursor=WzE3MDQxNTM2MDAwMDAsIjIwMjMtMjc5MDUiXQ",
        ],
        ["WzE3MDQxNTM2MDAwMDAsIjIwMjMtMjc3ODMiXQ", "WzE3MDQxNTM2MDAwMDAsIjIwMjMtMjc5MDUiXQ"]
      ),
    ]
    for (one, two, search, paths, cursors) in recorded {
      let first = Endpoint<DocumentPage>.searchDocuments(matching: try search.query())
      let second = try #require(
        try DocumentPage.decode(one.data()).continuation(after: first, seenCursors: []))
      let secondCursor = try #require(second.cursor)
      #expect(second.endpoint.path == paths[0])
      #expect(secondCursor == cursors[0])
      let third = try #require(
        try DocumentPage.decode(two.data()).continuation(
          after: second.endpoint, seenCursors: [secondCursor]))
      #expect(third.endpoint.path == paths[1])
      #expect(third.cursor == cursors[1])
    }
  }

  @Test("Term searches continue by the provider's page number without a cursor")
  func termSearchesContinueByTheProvidersPageNumberWithoutACursor() throws {
    let spaced = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "clean water")
    let shared =
      "/api/v1/documents?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
      + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D="
    let second = try #require(
      try DocumentPage.decode(Fixture.searchSpacedTermPageOne.data()).continuation(
        after: .searchDocuments(matching: spaced), seenCursors: []))
    #expect(second.cursor == nil)
    #expect(
      second.endpoint.path == shared + "clean+water&format=json&order=newest&page=2&per_page=2")
    // Synthetic: the recorded page-two link advanced to page three; no third page was captured.
    let third = try #require(
      try page(
        next: "https://www.federalregister.gov" + shared
          + "clean+water&format=json&order=newest&page=3&per_page=2"
      ).continuation(after: second.endpoint, seenCursors: []))
    #expect(third.cursor == nil)
    #expect(
      third.endpoint.path == shared + "clean+water&format=json&order=newest&page=3&per_page=2")
    // Receipt URL of Fixtures/search-relevance-page-one.json; relevance order is not a query option.
    let relevance = try #require(
      Endpoint<DocumentPage>(
        link: "https://www.federalregister.gov/api/v1/documents.json?order=relevance&per_page=2"
          + "&conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
          + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D=water"))
    let relevanceTwo = try #require(
      try DocumentPage.decode(Fixture.searchRelevancePageOne.data()).continuation(
        after: relevance, seenCursors: []))
    #expect(relevanceTwo.cursor == nil)
    #expect(
      relevanceTwo.endpoint.path
        == shared + "water&format=json&order=relevance&page=2&per_page=2")
  }

  @Test("Page-number continuations must advance the page and keep the query")
  func pageNumberContinuationsMustAdvanceThePageAndKeepTheQuery() throws {
    // Synthetic links in the shape of the recorded clean-water page-two link.
    let spaced = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
      term: "clean water")
    let first = Endpoint<DocumentPage>.searchDocuments(matching: spaced)
    let root =
      "https://www.federalregister.gov/api/v1/documents?conditions%5Bpublication_date%5D%5Bgte%5D=2024-01-01"
      + "&conditions%5Bpublication_date%5D%5Blte%5D=2024-12-31&conditions%5Bterm%5D="
    let link: (String) -> String = { root + "clean+water&format=json&order=newest" + $0 }
    let second = try #require(Endpoint<DocumentPage>(link: link("&page=2&per_page=2")))
    #expect(throws: DocumentPaginationError.nonprogressingPage(1)) {
      try page(next: link("&page=1&per_page=2")).continuation(after: first, seenCursors: [])
    }
    #expect(throws: DocumentPaginationError.nonprogressingPage(0)) {
      try page(next: link("&page=0&per_page=2")).continuation(after: first, seenCursors: [])
    }
    #expect(throws: DocumentPaginationError.nonprogressingPage(2)) {
      try page(next: link("&page=2&per_page=2")).continuation(after: second, seenCursors: [])
    }
    #expect(throws: DocumentPaginationError.nonprogressingPage(1)) {
      try page(next: link("&page=1&per_page=2")).continuation(after: second, seenCursors: [])
    }
    for tail in ["", "&page=", "&page=two", "&page=2&page=3"] {
      #expect(throws: DocumentPaginationError.missingCursor) {
        try page(next: link(tail + "&per_page=2")).continuation(after: first, seenCursors: [])
      }
    }
    #expect(throws: DocumentPaginationError.changedQuery) {
      try page(next: link("&page=2&per_page=20")).continuation(after: first, seenCursors: [])
    }
    #expect(throws: DocumentPaginationError.changedQuery) {
      try page(next: root + "clean+air&format=json&order=newest&page=2&per_page=2").continuation(
        after: first, seenCursors: [])
    }
    // A cursor link continues by its cursor whatever page it names.
    #expect(
      try page(next: link("&page=1&per_page=2&search_after_cursor=abc")).continuation(
        after: second, seenCursors: [])?.cursor == "abc")
  }

  /// Names each resolution; the switch compiles only while it covers every case.
  private func continuationPolicy(of resolution: DocumentRequest<DocumentPage>.Resolution)
    -> String
  {
    switch resolution {
    case .documentSearch: "follows search cursors"
    case .endpoint: "single page"
    case .presidentialDocuments: "follows presidential cursors"
    }
  }
}

extension DocumentRequest where Response == DocumentPage {
  /// A consumer-defined general search for Environmental Protection Agency rules.
  fileprivate static func environmentalRules() throws -> Self {
    .searchDocuments(
      matching: try DocumentSearchQuery(agencies: [.environmentalProtectionAgency], types: [.rule]))
  }
}
