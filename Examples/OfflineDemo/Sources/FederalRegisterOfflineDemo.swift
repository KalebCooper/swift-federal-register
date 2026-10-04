import Foundation
import HTTPTesting
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels

@main
struct FederalRegisterOfflineDemo {
  static func main() async throws {
    guard CommandLine.arguments.count == 2 else {
      print(
        "Supply the absolute path to Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures.")
      return
    }
    let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    func recorded(_ name: String) throws -> Result<Response, TransportError> {
      .success(
        Response(body: try Data(contentsOf: directory.appendingPathComponent(name)), status: .ok))
    }
    try await runAgencyAndSearchFlow(recorded: recorded)
    print("")
    try await runExpandedFlow(recorded: recorded)
    try await runPresidentialFlow(recorded: recorded)
  }

  /// Agency discovery, a general search traversal, and typed regulatory metadata.
  static func runAgencyAndSearchFlow(
    recorded: (String) throws -> Result<Response, TransportError>
  ) async throws {
    let transport = MockTransport(results: [
      try recorded("agencies.json"),
      try recorded("agency-epa.json"),
      try recorded("search-newest-page-one.json"),
      try recorded("search-newest-page-two.json"),
      try recorded("regulatory-document.json"),
    ])
    let client = FederalRegisterClient(
      transport: transport, userAgent: "swift-federal-register-offline-demo")

    let catalog = try await client.agencies()
    let listed = catalog.agencies.first { $0.slug == .environmentalProtectionAgency }
    print("Recorded agency catalog: \(catalog.agencies.count) agencies")
    print(
      "Catalog entry: \(listed?.name ?? "not supplied") (\(listed?.shortName ?? "not supplied"))")

    let epa = try await client.agency(.environmentalProtectionAgency)
    print("Agency detail: \(epa.name ?? "not supplied")")
    print(
      "  Slug: \(epa.slug?.rawValue ?? "not supplied"); id: \(epa.id.map(String.init) ?? "not supplied")"
    )
    print("  Parent id: \(epa.parentID.map(String.init) ?? "not supplied")")

    let search = try DocumentSearchQuery(
      pageSize: 2, publicationDate: .range(from: "2024-01-01", through: "2024-12-31"))
    var pages = client.documentResponses(searching: search).makeAsyncIterator()
    for _ in 0..<2 {
      guard let page = try await pages.next() else { break }
      print("Recorded search page receipt: \(page.requestURL)")
      print(
        "  Reported count: \(page.value.count); advertised total pages: "
          + "\(page.value.totalPages.map(String.init) ?? "not supplied")")
      for item in page.value.results {
        print("  \(item.documentNumber) [\(item.type ?? "not supplied")]: \(item.title)")
      }
    }

    let document = try await client.document("2024-31396")
    print("Regulatory detail: \(document.documentNumber): \(document.title)")
    print("  Type: \(document.documentType?.rawValue ?? "not supplied")")
    let agencyNames = document.agencies?.map { $0.name ?? $0.rawName ?? "unnamed" }
    print("  Agencies: \(listing(agencyNames, separator: "; "))")
    let citations = document.cfrReferences?.map { reference in
      "\(reference.title.map(String.init) ?? "?") CFR \(reference.part ?? "?")"
    }
    print("  CFR references: \(listing(citations))")
    print("  Docket ids: \(listing(document.docketIDs))")
    print("  Docket id field: \(document.docketID ?? "not supplied")")
    print("  Regulation identifier numbers: \(listing(document.regulationIDNumbers))")
    print("  Significant: \(document.significant.map(String.init) ?? "not supplied")")
    print(
      "Sent \(transport.requests.count) recorded agency and search requests; stopped without prefetching."
    )
  }

  /// Distinguishes a value the provider did not supply from an empty list it did supply.
  static func listing(_ values: [String]?, separator: String = ", ") -> String {
    guard let values else { return "not supplied" }
    return values.isEmpty ? "none (empty list)" : values.joined(separator: separator)
  }

  /// Selected fields, explicit issue references, inspection pages, and discovery metadata.
  static func runExpandedFlow(recorded: (String) throws -> Result<Response, TransportError>)
    async throws
  {
    let transport = MockTransport(results: [
      try recorded("fields-detail.json"), try recorded("issue.json"),
      try recorded("published-batch-single.json"), try recorded("facets-type.json"),
      try recorded("inspection-current.json"), try recorded("inspection-date-empty.json"),
      try recorded("inspection-detail.json"), try recorded("inspection-search.json"),
      try recorded("inspection-search-two.json"), try recorded("suggested-section.json"),
      try recorded("suggested-detail.json"),
    ])
    let client = FederalRegisterClient(
      transport: transport, userAgent: "swift-federal-register-offline-demo")
    let selected = try await client.document("2024-31396", fields: [.significant])
    print("Selected source fields: \(selected.fields.keys.sorted())")
    let issue = try await client.issueTableOfContents(on: "2024-12-31")
    let references =
      issue.agencies?.first { $0.slug == "environmental-protection-agency" }?
      .documentCategories?.first?.documents?.first?.documentNumbers ?? []
    guard references == ["2024-31396"] else { throw DemoFailure.unexpectedRecording }
    let batch = try await client.documents(numbered: references)
    print(
      "Explicit issue reference lookup: \(batch.results.map(\.documentNumber)); count \(batch.count.map(String.init) ?? "not supplied")"
    )
    let counts = try await client.documentFacets(.type, matching: .init())
    print("Facet keys: \(counts.buckets?.keys.sorted() ?? [])")
    let current = try await client.currentPublicInspectionDocuments()
    print(
      "Inspection listing: \(current.count); regular update \(current.regularFilingsUpdatedAt ?? "not supplied")"
    )
    let empty = try await client.publicInspectionDocuments(availableOn: "2024-12-29")
    guard empty.results.isEmpty else { throw DemoFailure.unexpectedRecording }
    let detail = try await client.publicInspectionDocument("2026-19958")
    print(
      "Inspection filed: \(detail.filedAt ?? "not supplied"); intended publication: \(detail.publicationDate ?? "not supplied")"
    )
    var receipts = client.publicInspectionResponses(searching: try .init(pageSize: 2))
      .makeAsyncIterator()
    for _ in 0..<2 {
      guard let receipt = try await receipts.next() else { throw DemoFailure.unexpectedRecording }
      print("Inspection receipt: \(receipt.requestURL); \(receipt.body.count) bytes")
    }
    let suggestions = try await client.suggestedSearches(section: .environment)
    let suggestion = try await client.suggestedSearch(.init(rawValue: "climate-change"))
    print(
      "Suggested groups: \(suggestions.searchesBySection?.keys.sorted() ?? []); \(suggestion.title ?? "not supplied")"
    )
    guard transport.requests.count == 11 else { throw DemoFailure.unexpectedRecording }
    print("Sent 11 expanded requests; no implicit hydration or suggested-search execution.")
  }

  /// Historical presidential evidence and two lazy cursor pages.
  static func runPresidentialFlow(
    recorded: (String) throws -> Result<Response, TransportError>
  ) async throws {
    let transport = MockTransport(results: [
      try recorded("historical-document.json"),
      try recorded("historical-content.txt"),
      try recorded("presidential-page-one.json"),
      try recorded("presidential-page-two.json"),
    ])
    let client = FederalRegisterClient(
      transport: transport, userAgent: "swift-federal-register-offline-demo")
    let receipt = try await client.response(for: DocumentRequest.document("93-32104"))
    let document = receipt.value
    print("Recorded document: \(document.documentNumber): \(document.title)")
    print("Publisher: \(receipt.publisher)")
    print("Publication: \(document.publicationDate ?? "not supplied")")
    print("Signing date field: \(document.signingDate ?? "not supplied")")
    print("Table of contents: \(document.tocDoc ?? "not supplied")")
    print(
      "PDF advertised: \(document.pdfURL != nil); XML advertised: \(document.fullTextXMLURL != nil)"
    )
    let content = try await client.content(.text, for: document)
    print("Original text representation: \(content.source.utf8.count) UTF-8 bytes")
    var pages = client.documentResponses(matching: try DocumentQuery(pageSize: 2))
      .makeAsyncIterator()
    for _ in 0..<2 {
      guard let page = try await pages.next() else { break }
      print("Recorded page receipt: \(page.requestURL)")
      for item in page.value.results { print("  \(item.documentNumber): \(item.title)") }
    }
    print("Sent \(transport.requests.count) recorded requests; stopped without prefetching.")
  }
}

private enum DemoFailure: Error {
  case unexpectedRecording
}
