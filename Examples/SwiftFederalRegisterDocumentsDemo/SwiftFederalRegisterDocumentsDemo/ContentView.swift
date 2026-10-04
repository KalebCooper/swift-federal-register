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
        ExpandedSourcesView(client: client)
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

@MainActor
private struct ExpandedSourcesView: View {
  let client: FederalRegisterClient

  @State private var inspection: [PublicInspectionDocument] = []
  @State private var inspectionDetail: PublicInspectionDocument?
  @State private var inspectionIterator:
    PublicInspectionPageSequence<PublicInspectionPage>.Iterator?
  @State private var issue: IssueTableOfContents?
  @State private var issueDate = "2024-12-31"
  @State private var message: String?
  @State private var published: [FederalRegisterDocument] = []
  @State private var task: Task<Void, Never>?
  @State private var term = ""

  var body: some View {
    Section("Issues and public inspection") {
      TextField("Issue date (YYYY-MM-DD)", text: $issueDate)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
      Button("Load issue contents") {
        start {
          issue = nil
          published = []
          issue = try await client.issueTableOfContents(on: issueDate)
          if issue?.agencies?.isEmpty == true { message = "This issue contains no agency groups." }
        }
      }.disabled(task != nil)
      if let issue {
        Text("Issue publication: " + (issue.meta?.publicationDate ?? "Not supplied"))
        ForEach(Array((issue.agencies ?? []).enumerated()), id: \.offset) { _, agency in
          DisclosureGroup(agency.name ?? "Agency name not supplied") {
            ForEach(Array((agency.documentCategories ?? []).enumerated()), id: \.offset) {
              _, category in
              Text(category.type ?? "Document type not supplied").font(.headline)
              ForEach(Array((category.documents ?? []).enumerated()), id: \.offset) { _, entry in
                Text([entry.subject1, entry.subject2].compactMap { $0 }.joined(separator: ": "))
                if let numbers = entry.documentNumbers, !numbers.isEmpty {
                  Button("Load referenced documents") {
                    start { published = try await client.documents(numbered: numbers).results }
                  }.disabled(task != nil)
                }
              }
            }
          }
        }
      }
      ForEach(Array(published.enumerated()), id: \.offset) { _, document in
        VStack(alignment: .leading) {
          Text(document.title)
          Text("Published: " + (document.publicationDate ?? "Not supplied")).font(.caption)
        }
      }

      Button("Load current inspection listing") {
        start {
          inspectionIterator = nil
          inspectionDetail = nil
          inspection = try await client.currentPublicInspectionDocuments().results
          if inspection.isEmpty { message = "No inspection records in this listing." }
        }
      }.disabled(task != nil)
      TextField("Inspection search term (optional)", text: $term)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
      Button("Search public inspection") {
        start {
          inspection = []
          inspectionDetail = nil
          inspectionIterator = nil
          let query = try PublicInspectionQuery(pageSize: 20, term: term.isEmpty ? nil : term)
          inspectionIterator = client.publicInspectionPages(searching: query).makeAsyncIterator()
          try await nextInspectionPage()
        }
      }.disabled(task != nil)
      ForEach(Array(inspection.enumerated()), id: \.offset) { _, record in
        Button {
          start {
            inspectionDetail = try await client.publicInspectionDocument(record.documentNumber)
          }
        } label: {
          VStack(alignment: .leading) {
            Text(record.title)
            Text("Filed: " + (record.filedAt ?? "Not supplied")).font(.caption)
            Text("Intended publication: " + (record.publicationDate ?? "Not supplied")).font(
              .caption)
          }
        }.disabled(task != nil)
      }
      if inspectionIterator != nil {
        Button("Load next inspection page") { start { try await nextInspectionPage() } }
          .disabled(task != nil)
      }
      if let inspectionDetail {
        Text(inspectionDetail.documentNumber + ": " + inspectionDetail.title).font(.headline)
        LabeledContent("Filed", value: inspectionDetail.filedAt ?? "Not supplied")
        LabeledContent(
          "Intended publication", value: inspectionDetail.publicationDate ?? "Not supplied")
        LabeledContent("PDF updated", value: inspectionDetail.pdfUpdatedAt ?? "Not supplied")
        if let editorial = inspectionDetail.editorialNote { Text(editorial) }
      }
      if task != nil {
        ProgressView("Loading source")
        Button("Cancel request", role: .cancel) { task?.cancel() }
      }
      if let message { Text(message).textSelection(.enabled) }
      Text(
        "Public inspection is a preview. An intended publication date is not proof of publication."
      )
      .font(.caption)
      Text("Office of the Federal Register, NARA; Government Publishing Office").font(.caption)
    }
    .onDisappear { task?.cancel() }
  }

  private func nextInspectionPage() async throws {
    guard var iterator = inspectionIterator else { return }
    inspectionIterator = nil
    guard let page = try await iterator.next() else {
      if inspection.isEmpty { message = "No matching inspection records." }
      return
    }
    inspection += page.results
    if page.nextPageURL != nil { inspectionIterator = iterator }
    if inspection.isEmpty { message = "No matching inspection records." }
  }

  private func start(_ operation: @escaping @MainActor () async throws -> Void) {
    guard task == nil else { return }
    message = nil
    task = Task { @MainActor in
      do { try await operation() } catch {
        message = Task.isCancelled ? "Request cancelled." : String(describing: error)
      }
      task = nil
    }
  }
}
