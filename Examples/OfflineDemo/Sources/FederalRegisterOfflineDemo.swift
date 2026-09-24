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
    func bytes(_ name: String) throws -> Data {
      try Data(contentsOf: directory.appendingPathComponent(name))
    }
    let transport = MockTransport(results: [
      .success(Response(body: try bytes("historical-document.json"), status: .ok)),
      .success(Response(body: try bytes("historical-content.txt"), status: .ok)),
      .success(Response(body: try bytes("presidential-page-one.json"), status: .ok)),
      .success(Response(body: try bytes("presidential-page-two.json"), status: .ok)),
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
