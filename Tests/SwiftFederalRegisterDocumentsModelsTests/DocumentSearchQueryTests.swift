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
}
