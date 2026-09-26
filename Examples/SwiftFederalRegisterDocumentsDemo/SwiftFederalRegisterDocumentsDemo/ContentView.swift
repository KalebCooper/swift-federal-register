import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftUI

struct ContentView: View {
  @State private var document: FederalRegisterDocument?
  @State private var documents: [FederalRegisterDocument] = []
  @State private var errorMessage: String?
  @State private var isLoading = false
  @State private var iterator: DocumentPageSequence<DocumentPage>.Iterator?
  @State private var number = "93-32104"
  @State private var source: String?

  private let client = FederalRegisterClient(
    userAgent:
      "(swift-federal-register-demo, https://github.com/KalebCooper/swift-federal-register)")

  var body: some View {
    NavigationStack {
      List {
        SearchView(client: client)
        AgencySection(client: client)
        Section("Document detail") {
          TextField("Document number", text: $number)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
          Button("Load document") { Task { await loadDocument() } }.disabled(isLoading)
        }
        if let errorMessage {
          Section("Request failed") { Text(errorMessage).foregroundStyle(.red) }
        }
        if let document {
          Section(document.title) {
            LabeledContent("Publication", value: document.publicationDate ?? "Not supplied")
            LabeledContent("Signing date field", value: document.signingDate ?? "Not supplied")
            if let description = document.tocDoc { Text(description) }
            Text("Office of the Federal Register, NARA; Government Publishing Office").font(
              .caption)
            Text("Source date assertions are shown independently.").font(.caption)
            ForEach([DocumentRepresentation.html, .text, .xml], id: \.rawValue) { representation in
              Button("Load " + representation.rawValue.uppercased() + " source") {
                Task { await loadContent(representation, for: document) }
              }.disabled(isLoading || !hasLink(representation, document: document))
            }
            if let link = document.pdfURL, let url = URL(string: link) {
              Link("Advertised GPO PDF", destination: url)
            } else {
              Text("PDF link not supplied")
            }
          }
        }
        if let source {
          Section("Original source") {
            Text(source).font(.caption.monospaced()).textSelection(.enabled)
          }
        }
        Section("Presidential documents") {
          Button("Start newest documents") { Task { await startPages() } }.disabled(isLoading)
          ForEach(Array(documents.enumerated()), id: \.offset) { _, document in
            Button {
              number = document.documentNumber
              Task { await loadDocument() }
            } label: {
              VStack(alignment: .leading) {
                Text(document.title)
                Text(document.publicationDate ?? "Publication date not supplied").font(.caption)
              }
            }.disabled(isLoading)
          }
          if iterator != nil {
            Button("Load next page") { Task { await loadPage() } }.disabled(isLoading)
          }
        }
      }
      .navigationTitle("Federal Register")
      .overlay { if isLoading { ProgressView() } }
    }
  }

  private func hasLink(_ representation: DocumentRepresentation, document: FederalRegisterDocument)
    -> Bool
  {
    switch representation {
    case .html: document.bodyHTMLURL != nil
    case .text: document.rawTextURL != nil
    case .xml: document.fullTextXMLURL != nil
    }
  }

  private func loadContent(
    _ representation: DocumentRepresentation, for document: FederalRegisterDocument
  ) async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil
    source = nil
    do { source = try await client.content(representation, for: document).source } catch {
      errorMessage = String(describing: error)
    }
  }

  private func loadDocument() async {
    isLoading = true
    defer { isLoading = false }
    document = nil
    errorMessage = nil
    source = nil
    do { document = try await client.document(number) } catch {
      errorMessage = String(describing: error)
    }
  }

  private func loadPage() async {
    guard var current = iterator else { return }
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil
    do {
      if let page = try await current.next() {
        documents.append(contentsOf: page.results)
        iterator = page.nextPageURL == nil ? nil : current
      } else {
        iterator = nil
      }
    } catch {
      iterator = nil
      errorMessage = String(describing: error)
    }
  }

  private func startPages() async {
    do {
      documents = []
      iterator = client.documentPages(matching: try DocumentQuery(pageSize: 5)).makeAsyncIterator()
      await loadPage()
    } catch { errorMessage = String(describing: error) }
  }
}
