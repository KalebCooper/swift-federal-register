import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AgencyModelsTests {
  /// Reads the `agencies` array of a recorded document.
  private struct AttributedDocument: Decodable {
    let agencies: [DocumentAgency]
  }

  /// Reads the `results` array of a recorded search page.
  private struct AttributedPage: Decodable {
    let results: [AttributedDocument]
  }

  @Test("A document's agency attributions keep raw and matched names")
  func aDocumentsAgencyAttributionsKeepRawAndMatchedNames() throws {
    let document = try JSONDecoder().decode(
      AttributedDocument.self, from: Fixture.regulatoryDocument.data())
    let agency = try #require(document.agencies.first)
    #expect(document.agencies.count == 1)
    #expect(agency.id == 145)
    #expect(agency.jsonURL == "https://www.federalregister.gov/api/v1/agencies/145")
    #expect(agency.name == "Environmental Protection Agency")
    #expect(agency.parentID == nil)
    #expect(agency.fields["parent_id"] == .null)
    #expect(agency.rawName == "ENVIRONMENTAL PROTECTION AGENCY")
    #expect(agency.slug == .environmentalProtectionAgency)
    #expect(
      agency.url == "https://www.federalregister.gov/agencies/environmental-protection-agency")
  }

  @Test("A document continuation never crosses into the agency routes")
  func aDocumentContinuationNeverCrossesIntoTheAgencyRoutes() throws {
    // Synthetic literal: no capture publishes a next link outside the documents routes.
    for link in [
      "https://www.federalregister.gov/api/v1/agencies.json?search_after_cursor=x",
      "https://www.federalregister.gov/api/v1/agencies/environmental-protection-agency.json?search_after_cursor=x",
    ] {
      let data = Data(
        """
        {"count":1,"next_page_url":"\(link)","results":[{"document_number":"2024-31396",
         "title":"Example"}],"total_pages":1}
        """.utf8)
      let page = try DocumentPage.decode(data)
      #expect(Endpoint<DocumentPage>(link: link) != nil)
      #expect(throws: DocumentPaginationError.invalidLink(link)) {
        try page.continuation(
          after: .presidentialDocuments(matching: DocumentQuery()), seenCursors: [])
      }
    }
  }

  @Test("A search result's child agency attribution names its parent")
  func aSearchResultsChildAgencyAttributionNamesItsParent() throws {
    let page = try JSONDecoder().decode(
      AttributedPage.self, from: Fixture.searchNewestPageOne.data())
    let agencies = try #require(page.results.first).agencies
    #expect(
      agencies.map(\.rawName) == ["DEPARTMENT OF ENERGY", "Federal Energy Regulatory Commission"])
    #expect(agencies.map(\.parentID) == [nil, 136])
    #expect(agencies.map(\.slug) == [.energyDepartment, .federalEnergyRegulatoryCommission])
  }

  @Test("Agency endpoints and requests describe the catalog and detail routes")
  func agencyEndpointsAndRequestsDescribeTheCatalogAndDetailRoutes() throws {
    let catalog = Endpoint<AgencyList>.agencies()
    #expect(catalog.accept == "application/json")
    #expect(catalog.path == "/api/v1/agencies.json")
    let epa = try Endpoint<FederalRegisterAgency>.agency(.environmentalProtectionAgency)
    #expect(epa.path == "/api/v1/agencies/environmental-protection-agency.json")
    let future = try Endpoint<FederalRegisterAgency>.agency(
      AgencyIdentifier(rawValue: "future-agency"))
    #expect(future.path == "/api/v1/agencies/future-agency.json")
    #expect(DocumentRequest.agencies().resolution == .endpoint(catalog))
    #expect(DocumentRequest.agencies().endpoint == catalog)
    #expect(try DocumentRequest.agency(.environmentalProtectionAgency).resolution == .endpoint(epa))
    #expect(
      try DocumentRequest.agency(AgencyIdentifier(rawValue: "future-agency")).endpoint == future)
  }

  @Test(
    "Agency slugs outside letters, digits, and hyphens are rejected before any path forms",
    arguments: ["", "a/b", "a b", "../x", "a%2Fb"])
  func agencySlugsOutsideLettersDigitsAndHyphensAreRejectedBeforeAnyPathForms(_ slug: String) {
    #expect(throws: DocumentValidationError.invalidAgencyIdentifier(slug)) {
      try Endpoint<FederalRegisterAgency>.agency(AgencyIdentifier(rawValue: slug))
    }
    #expect(throws: DocumentValidationError.invalidAgencyIdentifier(slug)) {
      try DocumentRequest.agency(AgencyIdentifier(rawValue: slug))
    }
  }

  @Test("Agency requests support contextual, inferred, and consumer-defined shapes")
  func agencyRequestsSupportContextualInferredAndConsumerDefinedShapes() throws {
    let contextual: DocumentRequest<AgencyList> = .agencies()
    let inferred = DocumentRequest.agencies()
    #expect(contextual == inferred)
    let stored = try DocumentRequest.agency(.environmentalProtectionAgency)
    let contextualEndpoint: Endpoint<FederalRegisterAgency> = try .agency(
      .environmentalProtectionAgency)
    #expect(stored.endpoint == contextualEndpoint)
    #expect(try DocumentRequest.environmentalProtectionAgency() == stored)
    let custom = try #require(
      Endpoint<AgencyName>(path: "/api/v1/agencies/environmental-protection-agency.json"))
    let customRequest = DocumentRequest(endpoint: custom)
    #expect(customRequest.resolution == .endpoint(custom))
    #expect(
      try AgencyName.decode(Fixture.agencyEPA.data()).name == "Environmental Protection Agency")
  }

  @Test("An agency list re-encodes as a bare array and decodes back equal")
  func anAgencyListReEncodesAsABareArrayAndDecodesBackEqual() throws {
    let list = try AgencyList.decode(Fixture.agencyCatalog.data())
    let encoded = try JSONEncoder().encode(list)
    #expect(encoded.first == UInt8(ascii: "["))
    #expect(try AgencyList.decode(encoded) == list)
  }

  @Test("An agency with only a raw name decodes with every other projection nil")
  func anAgencyWithOnlyARawNameDecodesWithEveryOtherProjectionNil() throws {
    // Synthetic literal: no capture carries a raw-name-only attribution.
    let data = Data(#"{"raw_name":"OFFICE OF THE FEDERAL REGISTER"}"#.utf8)
    let agency = try JSONDecoder().decode(DocumentAgency.self, from: data)
    #expect(agency.rawName == "OFFICE OF THE FEDERAL REGISTER")
    #expect(agency.id == nil)
    #expect(agency.jsonURL == nil)
    #expect(agency.name == nil)
    #expect(agency.parentID == nil)
    #expect(agency.slug == nil)
    #expect(agency.url == nil)
    #expect(agency.fields == ["raw_name": .string("OFFICE OF THE FEDERAL REGISTER")])
  }

  @Test("An incompatible field kind makes only that projection nil")
  func anIncompatibleFieldKindMakesOnlyThatProjectionNil() throws {
    // Synthetic literal: every captured agency publishes these fields with their documented kinds.
    let data = Data(
      #"""
      {"child_ids":[1,2.5],"child_slugs":[1,"x"],"id":"145","logo":"none","name":"Example",
       "parent_id":145.5,"slug":7}
      """#.utf8)
    let agency = try FederalRegisterAgency.decode(data)
    #expect(agency.childIDs == nil)
    #expect(
      agency.fields["child_ids"] == .array([.number(1), .number(Decimal(string: "2.5") ?? 0)]))
    #expect(agency.childSlugs == nil)
    #expect(agency.fields["child_slugs"] == .array([.number(1), .string("x")]))
    #expect(agency.id == nil)
    #expect(agency.fields["id"] == .string("145"))
    #expect(agency.logo == nil)
    #expect(agency.fields["logo"] == .string("none"))
    #expect(agency.name == "Example")
    #expect(agency.parentID == nil)
    #expect(agency.fields["parent_id"] == .number(Decimal(string: "145.5") ?? 0))
    #expect(agency.slug == nil)
    #expect(agency.fields["slug"] == .number(7))
  }

  @Test(
    "Custom agency paths accept only the catalog and one-segment detail routes",
    arguments: [
      ("/api/v1/agencies.json", true),
      ("/api/v1/agencies/environmental-protection-agency.json", true),
      ("/api/v1/agencies/145", true),
      ("/api/v1/agencies", false),
      ("/api/v1/agencies/", false),
      ("/api/v1/agencie.json", false),
      ("/api/v1/agencies.json/extra", false),
      ("/api/v1/agencies/../documents.json", false),
      ("/api/v1/agencies/%2e%2e/documents.json", false),
      ("/api/v1/agencies/a/b.json", false),
      ("/api/v1/agencies/a%2Fb.json", false),
    ])
  func customAgencyPathsAcceptOnlyTheCatalogAndOneSegmentDetailRoutes(
    _ path: String, _ accepted: Bool
  ) {
    #expect((Endpoint<AgencyList>(path: path) != nil) == accepted)
    #expect((Endpoint<FederalRegisterAgency>(path: path) != nil) == accepted)
  }

  @Test("Presidential request literals are unchanged by the agency routes")
  func presidentialRequestLiteralsAreUnchangedByTheAgencyRoutes() throws {
    // Literal from the presidential-page-one.json receipt URL in Fixtures/receipts.json.
    #expect(
      Endpoint<DocumentPage>.presidentialDocuments(matching: try DocumentQuery(pageSize: 2)).path
        == "/api/v1/documents.json?conditions%5Btype%5D%5B%5D=PRESDOCU&order=newest&per_page=2")
  }

  @Test("The agency catalog decodes every entry in provider order")
  func theAgencyCatalogDecodesEveryEntryInProviderOrder() throws {
    let list = try AgencyList.decode(Fixture.agencyCatalog.data())
    #expect(list.agencies.count == 473)
    #expect(list.agencies.first?.slug == .action)
    #expect(
      list.agencies.dropFirst().first?.slug?.rawValue
        == "administration-office-executive-office-of-the-president")
    #expect(list.agencies.last?.slug?.rawValue == "workers-compensation-programs-office")
    #expect(list.agencies.filter { $0.logo == nil }.count == 263)
    #expect(list.agencies.filter { $0.fields["logo"] == .null }.count == 263)
    #expect(list.agencies.filter { $0.parentID == nil }.count == 247)
    #expect(list.agencies.filter { $0.fields["parent_id"] == .null }.count == 247)
    #expect(list.agencies.filter { $0.shortName == nil }.count == 53)
    #expect(list.agencies.filter { $0.agencyURL == "" }.count == 139)
  }

  @Test("The catalog's EPA entry projects its identifiers, links, and logo")
  func theCatalogsEPAEntryProjectsItsIdentifiersLinksAndLogo() throws {
    let list = try AgencyList.decode(Fixture.agencyCatalog.data())
    let epa = try #require(list.agencies.first { $0.slug == .environmentalProtectionAgency })
    #expect(epa.agencyURL == "http://www.epa.gov/")
    #expect(epa.childIDs == [])
    #expect(epa.childSlugs == [])
    #expect(epa.id == 145)
    #expect(epa.jsonURL == "http://www.federalregister.gov/api/v1/agencies/145")
    #expect(
      epa.logo?.mediumURL == "https://agency-logos.federalregister.gov/145/medium.png?1279149236")
    #expect(
      epa.logo?.smallURL == "https://agency-logos.federalregister.gov/145/small.png?1279149236")
    #expect(
      epa.logo?.thumbURL == "https://agency-logos.federalregister.gov/145/thumb.png?1279149236")
    #expect(epa.name == "Environmental Protection Agency")
    #expect(epa.parentID == nil)
    #expect(epa.fields["parent_id"] == .null)
    #expect(
      epa.recentArticlesURL
        == "https://www.federalregister.gov/api/v1/documents?conditions%5Bagency_ids%5D%5B%5D=145&order=newest"
    )
    #expect(epa.shortName == "EPA")
    #expect(epa.url == "https://www.federalregister.gov/agencies/environmental-protection-agency")
  }

  @Test("The EPA detail record omits the JSON link the catalog publishes")
  func theEPADetailRecordOmitsTheJSONLinkTheCatalogPublishes() throws {
    let epa = try FederalRegisterAgency.decode(Fixture.agencyEPA.data())
    #expect(epa.id == 145)
    #expect(epa.jsonURL == nil)
    #expect(epa.fields["json_url"] == nil)
    #expect(epa.slug == .environmentalProtectionAgency)
    #expect(try FederalRegisterAgency.decode(JSONEncoder().encode(epa)) == epa)
  }

  @Test("The HHS detail record lists its child agencies in provider order")
  func theHHSDetailRecordListsItsChildAgenciesInProviderOrder() throws {
    let hhs = try FederalRegisterAgency.decode(Fixture.agencyHHS.data())
    #expect(hhs.id == 221)
    #expect(hhs.shortName == "HHS")
    #expect(
      hhs.childIDs == [
        5, 7, 8, 44, 45, 48, 49, 587, 153, 199, 559, 222, 237, 245, 353, 356, 439, 442, 448, 615,
        479,
      ])
    let expectedSlugs = [
      "agency-for-healthcare-research-and-quality",
      "agency-for-toxic-substances-and-disease-registry",
      "aging-administration",
      "centers-for-disease-control-and-prevention",
      "centers-for-medicare-medicaid-services",
      "child-support-enforcement-office",
      "children-and-families-administration",
      "community-living-administration",
      "family-assistance-office",
      "food-and-drug-administration",
      "health-care-finance-administration",
      "health-resources-and-services-administration",
      "indian-health-service",
      "inspector-general-office-health-and-human-services-department",
      "national-institutes-of-health",
      "national-library-of-medicine",
      "program-support-center",
      "public-health-service",
      "refugee-resettlement-office",
      "strategic-preparedness-and-response-administration",
      "substance-abuse-and-mental-health-services-administration",
    ]
    #expect(hhs.childSlugs?.map(\.rawValue) == expectedSlugs)
    #expect(hhs.childSlugs?.first == .agencyForHealthcareResearchAndQuality)
  }
}

/// A consumer-defined single-field agency response.
private struct AgencyName: Decodable, DocumentResponse { let name: String }

extension DocumentRequest where Response == FederalRegisterAgency {
  /// A consumer-defined named factory over the library's detail request.
  static func environmentalProtectionAgency() throws(DocumentValidationError) -> Self {
    try .agency(.environmentalProtectionAgency)
  }
}
