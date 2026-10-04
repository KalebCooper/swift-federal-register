import Foundation
import SwiftFederalRegisterDocumentsModels
import SwiftFederalRegisterDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ExpandedVocabularyTests {
  private struct Vocabulary: Decodable {
    let names: [String: [String]]
  }

  @Test("Known shorthands match the retained official schema vocabulary")
  func documentedNames() throws {
    let evidence = try JSONDecoder().decode(
      Vocabulary.self, from: Fixture.expandedVocabulary.data())
    let documentField: [DocumentField] = [
      .abstract,
      .action,
      .agencies,
      .agencyNames,
      .amendatoryInstructions,
      .bodyHTMLURL,
      .cfrReferences,
      .cfrTopics,
      .citation,
      .commentURL,
      .commentsCloseOn,
      .correctionOf,
      .corrections,
      .dates,
      .dispositionNotes,
      .docketID,
      .docketIDs,
      .dockets,
      .documentNumber,
      .effectiveOn,
      .endPage,
      .excerpts,
      .executiveOrderNotes,
      .executiveOrderNumber,
      .explanation,
      .fullTextXMLURL,
      .htmlURL,
      .images,
      .imagesMetadata,
      .jsonURL,
      .modsURL,
      .notReceivedForPublication,
      .pageLength,
      .pageViews,
      .pdfURL,
      .president,
      .presidentialDocumentNumber,
      .proclamationNumber,
      .publicInspectionPDFURL,
      .publicationDate,
      .rawTextURL,
      .regulationIDNumberInfo,
      .regulationIDNumbers,
      .regulationsDotGovInfo,
      .regulationsDotGovURL,
      .relatedDocuments,
      .significant,
      .signingDate,
      .startPage,
      .subtype,
      .title,
      .tocDoc,
      .tocSubject,
      .topics,
      .type,
      .volume,
    ]
    #expect(documentField.map(\.rawValue).sorted() == evidence.names["DocumentField"]?.sorted())
    let presidentialDocumentType: [PresidentialDocumentTypeCode] = [
      .determination,
      .executiveOrder,
      .memorandum,
      .notice,
      .other,
      .presidentialOrder,
      .proclamation,
    ]
    #expect(
      presidentialDocumentType.map(\.rawValue).sorted()
        == evidence.names["PresidentialDocumentType"]?.sorted())
    let publicInspectionDocumentField: [PublicInspectionDocumentField] = [
      .agencies,
      .agencyLetters,
      .agencyNames,
      .docketNumbers,
      .documentNumber,
      .editorialNote,
      .excerpts,
      .filedAt,
      .filingType,
      .htmlURL,
      .jsonURL,
      .lastPublicInspectionIssue,
      .numPages,
      .pageViews,
      .pdfFileName,
      .pdfFileSize,
      .pdfUpdatedAt,
      .pdfURL,
      .publicationDate,
      .rawTextURL,
      .subject1,
      .subject2,
      .subject3,
      .title,
      .tocDoc,
      .tocSubject,
      .type,
    ]
    #expect(
      publicInspectionDocumentField.map(\.rawValue).sorted()
        == evidence.names["PublicInspectionDocumentField"]?.sorted())
    let section: [SectionIdentifier] = [
      .businessAndIndustry,
      .environment,
      .healthAndPublicWelfare,
      .money,
      .scienceAndTechnology,
      .world,
    ]
    #expect(section.map(\.rawValue).sorted() == evidence.names["Section"]?.sorted())
  }

  @Test("Open request vocabularies round-trip future values unchanged")
  func unknownValues() throws {
    try check(DocumentField(rawValue: " future_field "))
    try check(PresidentialDocumentTypeCode(rawValue: "future_type"))
    try check(PublicInspectionDocumentField(rawValue: "future_field"))
    try check(PublicInspectionFilingType(rawValue: "future_filing"))
    try check(SectionIdentifier(rawValue: "future-section"))
    try check(SuggestedSearchIdentifier(rawValue: "future-search"))
    try check(TopicIdentifier(rawValue: "future-topic"))
  }

  private func check<Value: Codable & Equatable>(_ value: Value) throws {
    #expect(try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value)) == value)
  }
}
