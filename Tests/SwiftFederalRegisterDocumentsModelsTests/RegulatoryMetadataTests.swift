import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct RegulatoryMetadataTests {
  /// Decodes a synthetic document object that adds `members` to the two required keys.
  private func syntheticDocument(_ members: String) throws -> FederalRegisterDocument {
    try FederalRegisterDocument.decode(
      Data(#"{"document_number":"2024-31396","title":"Example",\#(members)}"#.utf8))
  }

  @Test("A CFR reference accepts absent and null keys but not a fractional title")
  func aCFRReferenceAcceptsAbsentAndNullKeysButNotAFractionalTitle() throws {
    // Synthetic literals: recorded references carry every key with a numeric title.
    let sparse = try syntheticDocument(#""cfr_references":[{"part":null},{}]"#)
    #expect(sparse.cfrReferences?.count == 2)
    #expect(sparse.cfrReferences?.first?.part == nil)
    #expect(sparse.cfrReferences?.first?.title == nil)
    let fractional = try syntheticDocument(#""cfr_references":[{"part":"52","title":40.5}]"#)
    #expect(fractional.cfrReferences == nil)
    let standalone = try JSONDecoder().decode(
      CFRReference.self, from: Data(#"{"part":"52","title":"40"}"#.utf8))
    #expect(standalone.part == "52")
    #expect(standalone.title == nil)
    #expect(standalone.fields["title"] == .string("40"))
  }

  @Test("A document keeps its attribution list when one attribute has another kind")
  func aDocumentKeepsItsAttributionListWhenOneAttributeHasAnotherKind() throws {
    // Synthetic literal: every recorded attribution carries all seven keys in their usual kinds.
    let document = try syntheticDocument(
      #""agencies":[{"id":"145","raw_name":"ENVIRONMENTAL PROTECTION AGENCY"},{"raw_name":"X"}]"#)
    let agencies = try #require(document.agencies)
    #expect(agencies.map(\.rawName) == ["ENVIRONMENTAL PROTECTION AGENCY", "X"])
    #expect(agencies.first?.id == nil)
    #expect(agencies.first?.fields["id"] == .string("145"))
  }

  @Test("A document type label maps to its search code only for the documented labels")
  func aDocumentTypeLabelMapsToItsSearchCodeOnlyForTheDocumentedLabels() throws {
    #expect(DocumentType(rawValue: "Notice").code?.rawValue == "NOTICE")
    #expect(DocumentType(rawValue: "Presidential Document").code?.rawValue == "PRESDOCU")
    #expect(DocumentType(rawValue: "Proposed Rule").code?.rawValue == "PRORULE")
    #expect(DocumentType(rawValue: "Rule").code?.rawValue == "RULE")
    #expect(DocumentType(rawValue: "rule").code == nil)
    #expect(DocumentTypeCode.notice.rawValue == "NOTICE")
    #expect(DocumentTypeCode.presidentialDocument.rawValue == "PRESDOCU")
    #expect(DocumentTypeCode.proposedRule.rawValue == "PRORULE")
    #expect(DocumentTypeCode.rule.rawValue == "RULE")
    #expect(try JSONEncoder().encode(DocumentType.rule) == Data(#""Rule""#.utf8))
    #expect(try JSONEncoder().encode(DocumentTypeCode.rule) == Data(#""RULE""#.utf8))
    #expect(
      try JSONDecoder().decode(DocumentTypeCode.self, from: Data(#""FUTURE""#.utf8))
        == DocumentTypeCode(rawValue: "FUTURE"))
  }

  @Test("A historical document keeps empty regulatory lists distinct from absent ones")
  func aHistoricalDocumentKeepsEmptyRegulatoryListsDistinctFromAbsentOnes() throws {
    let document = try FederalRegisterDocument.decode(Fixture.historicalDocument.data())
    #expect(document.cfrReferences == [])
    #expect(document.docketID == nil)
    #expect(document.docketIDs == ["Federal Register: January 3, 1994"])
    #expect(document.documentType == .presidentialDocument)
    #expect(document.effectiveOn == nil)
    #expect(document.fields["effective_on"] == .null)
    #expect(document.regulationIDNumberInfo == [:])
    #expect(document.regulationIDNumbers == [])
    #expect(document.significant == nil)
  }

  @Test("A RIN document projects its Unified Agenda details by number")
  func aRINDocumentProjectsItsUnifiedAgendaDetailsByNumber() throws {
    let document = try FederalRegisterDocument.decode(Fixture.rinDocument.data())
    #expect(document.regulationIDNumbers == ["2060-AS35"])
    let info = try #require(document.regulationIDNumberInfo?["2060-AS35"])
    #expect(document.regulationIDNumberInfo?.count == 1)
    #expect(
      info.htmlURL
        == "https://www.federalregister.gov/regulations/2060-AS35/review-of-the-secondary-national-ambient-air-quality-standards-for-ecological-effects-of-oxides-of-n"
    )
    #expect(info.issue == "202410")
    #expect(info.priorityCategory == "Other Significant")
    #expect(
      info.title
        == "Review of the Secondary National Ambient Air Quality Standards for Ecological Effects of Oxides of Nitrogen, Oxides of Sulfur and Particulate Matter"
    )
    #expect(
      info.xmlURL
        == "http://www.reginfo.gov/public/do/eAgendaViewRule?pubId=202410&RIN=2060-AS35&operation=OPERATION_EXPORT_XML"
    )
    #expect(document.significant == true)
  }

  @Test("A regulatory document projects its CFR, docket, and type metadata")
  func aRegulatoryDocumentProjectsItsCFRDocketAndTypeMetadata() throws {
    let document = try FederalRegisterDocument.decode(Fixture.regulatoryDocument.data())
    #expect(document.action == "Final rule.")
    #expect(document.agencies?.first?.slug == .environmentalProtectionAgency)
    let references = try #require(document.cfrReferences)
    #expect(references.count == 1)
    #expect(references.first?.citationURL == nil)
    #expect(references.first?.part == "52")
    #expect(references.first?.title == 40)
    #expect(references.first?.fields["chapter"] == .null)
    #expect(references.first?.fields["citation_url"] == .null)
    #expect(document.commentURL == nil)
    #expect(document.fields["comment_url"] == .null)
    #expect(document.commentsCloseOn == nil)
    #expect(document.fields["comments_close_on"] == .null)
    #expect(document.docketID == nil)
    #expect(document.fields["docket_id"] == nil)
    #expect(document.docketIDs == ["EPA-R09-OAR-2023-0649", "FRL-11647-02-R9"])
    #expect(document.documentType == .rule)
    #expect(document.documentType?.code == .rule)
    #expect(document.effectiveOn == "2025-01-30")
    #expect(document.regulationIDNumberInfo == [:])
    #expect(document.regulationIDNumbers == [])
    #expect(document.regulationsDotGovURL == nil)
    #expect(document.significant == nil)
    #expect(document.fields["significant"] == .null)
    #expect(document.type == "Rule")
  }

  @Test("A search result with explicit fields projects docket_id and docket_ids separately")
  func aSearchResultWithExplicitFieldsProjectsDocketIDAndDocketIDsSeparately() throws {
    let page = try DocumentPage.decode(Fixture.searchFieldsPageOne.data())
    let document = try #require(page.results.first)
    #expect(document.documentNumber == "2024-31396")
    #expect(document.docketID == "EPA-R09-OAR-2023-0649")
    #expect(document.docketIDs == ["EPA-R09-OAR-2023-0649", "FRL-11647-02-R9"])
  }

  @Test("A sparse search result leaves regulatory projections nil and keeps its agencies")
  func aSparseSearchResultLeavesRegulatoryProjectionsNilAndKeepsItsAgencies() throws {
    let page = try DocumentPage.decode(Fixture.searchNewestPageOne.data())
    let document = try #require(page.results.first)
    #expect(document.documentNumber == "2024-31440")
    #expect(document.action == nil)
    #expect(
      document.agencies?.map(\.slug) == [.energyDepartment, .federalEnergyRegulatoryCommission])
    #expect(document.cfrReferences == nil)
    #expect(document.fields["cfr_references"] == nil)
    #expect(document.docketIDs == nil)
    #expect(document.documentType?.rawValue == "Notice")
    #expect(document.documentType?.code == .notice)
    #expect(document.regulationIDNumberInfo == nil)
    #expect(document.regulationIDNumbers == nil)
    #expect(document.significant == nil)
  }

  @Test(
    "Every regulatory fixture survives an encode and decode round trip",
    arguments: [
      Fixture.currentDocument, .historicalDocument, .regulatoryDocument, .rinDocument,
    ])
  func everyRegulatoryFixtureSurvivesAnEncodeAndDecodeRoundTrip(_ fixture: Fixture) throws {
    let value = try FederalRegisterDocument.decode(fixture.data())
    let decoded = try FederalRegisterDocument.decode(JSONEncoder().encode(value))
    #expect(decoded == value)
    #expect(decoded.cfrReferences == value.cfrReferences)
    #expect(decoded.regulationIDNumberInfo == value.regulationIDNumberInfo)
  }

  @Test("Incompatible regulatory kinds make only their own projection nil")
  func incompatibleRegulatoryKindsMakeOnlyTheirOwnProjectionNil() throws {
    // Synthetic literals: no recorded response carries these kinds.
    let document = try syntheticDocument(
      #"""
      "agencies":[{"raw_name":"X"},"X"],"cfr_references":[{"title":"40"}],"docket_ids":["a",1],
      "regulation_id_number_info":{"2060-AS35":"x"},"significant":false,"type":"Future Kind"
      """#)
    #expect(document.agencies == nil)
    #expect(
      document.fields["agencies"] == .array([.object(["raw_name": .string("X")]), .string("X")]))
    #expect(document.cfrReferences == nil)
    #expect(document.fields["cfr_references"] == .array([.object(["title": .string("40")])]))
    #expect(document.docketIDs == nil)
    #expect(document.fields["docket_ids"] == .array([.string("a"), .number(1)]))
    #expect(document.documentType == DocumentType(rawValue: "Future Kind"))
    #expect(document.documentType?.code == nil)
    #expect(document.regulationIDNumberInfo == nil)
    #expect(document.fields["regulation_id_number_info"] == .object(["2060-AS35": .string("x")]))
    #expect(document.significant == false)
    #expect(document.type == "Future Kind")
  }
}
