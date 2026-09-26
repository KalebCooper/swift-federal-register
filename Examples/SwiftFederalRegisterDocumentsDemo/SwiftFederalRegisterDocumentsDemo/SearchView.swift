import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftUI

/// General document search sections that load one page per tap and never prefetch.
struct SearchView: View {
  /// A document type filter choice: one of the four known codes, or no type condition.
  enum TypeChoice: CaseIterable, Hashable, Identifiable {
    case any
    case notice
    case presidentialDocument
    case proposedRule
    case rule

    var code: DocumentTypeCode? {
      switch self {
      case .any: nil
      case .notice: .notice
      case .presidentialDocument: .presidentialDocument
      case .proposedRule: .proposedRule
      case .rule: .rule
      }
    }

    var id: Self { self }

    var title: String { code?.rawValue ?? "Any" }
  }

  let client: FederalRegisterClient

  @State private var agency = "environmental-protection-agency"
  @State private var errorMessage: String?
  @State private var iterator: DocumentPageSequence<DocumentPage>.Iterator?
  @State private var loadTask: Task<Void, Never>?
  @State private var matchCount: Int?
  @State private var pagesLoaded = 0
  @State private var results: [FederalRegisterDocument] = []
  @State private var status: String?
  @State private var term = ""
  @State private var type = TypeChoice.rule

  var body: some View {
    Section("General search") {
      TextField("Agency slug (optional)", text: $agency)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
      TextField("Search term (optional)", text: $term)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
      Picker("Document type", selection: $type) {
        ForEach(TypeChoice.allCases) { choice in Text(choice.title).tag(choice) }
      }
      Button("Search") { start() }.disabled(loadTask != nil)
    }
    if let errorMessage {
      Section("Search failed") { Text(errorMessage).foregroundStyle(.red) }
    }
    if pagesLoaded > 0 || loadTask != nil || status != nil {
      Section {
        ForEach(Array(results.enumerated()), id: \.offset) { _, document in
          NavigationLink {
            DocumentMetadataView(client: client, number: document.documentNumber)
          } label: {
            VStack(alignment: .leading) {
              Text(document.title).lineLimit(3)
              Text(
                document.documentNumber + " | "
                  + (document.type ?? "Type not supplied") + " | "
                  + (document.publicationDate ?? "Publication date not supplied")
              ).font(.caption)
            }
          }
        }
        if loadTask != nil {
          HStack {
            ProgressView()
            Spacer()
            Button("Cancel", role: .cancel) { loadTask?.cancel() }
          }
        } else if iterator != nil {
          Button("Load next page") { loadNext() }
        } else if pagesLoaded > 0 {
          Text("No further page advertised").foregroundStyle(.secondary)
        }
        if let status { Text(status).font(.caption) }
      } header: {
        Text("Search results")
      } footer: {
        Text(
          String(results.count) + " results from " + String(pagesLoaded)
            + " pages. Provider count: "
            + (matchCount.map(String.init) ?? "not yet loaded") + ".")
      }
    }
  }

  private func loadNext() {
    guard var current = iterator else { return }
    errorMessage = nil
    status = nil
    loadTask = Task {
      defer { loadTask = nil }
      do {
        let page = try await current.next()
        guard !Task.isCancelled else {
          status = "Cancelled. Loaded results are unchanged."
          return
        }
        if let page {
          results.append(contentsOf: page.results)
          pagesLoaded += 1
          matchCount = page.count
          iterator = page.nextPageURL == nil ? nil : current
        } else {
          iterator = nil
        }
      } catch {
        if Task.isCancelled {
          status = "Cancelled. Loaded results are unchanged."
        } else {
          iterator = nil
          errorMessage = String(describing: error)
        }
      }
    }
  }

  private func start() {
    errorMessage = nil
    status = nil
    let query: DocumentSearchQuery
    do {
      query = try DocumentSearchQuery(
        agencies: trimmed(agency).map { [AgencyIdentifier(rawValue: $0)] } ?? [], pageSize: 5,
        term: trimmed(term), types: type.code.map { [$0] } ?? [])
    } catch {
      errorMessage = String(describing: error)
      return
    }
    results = []
    pagesLoaded = 0
    matchCount = nil
    iterator = client.documentPages(searching: query).makeAsyncIterator()
    loadNext()
  }

  private func trimmed(_ value: String) -> String? {
    let result = value.trimmingCharacters(in: .whitespaces)
    return result.isEmpty ? nil : result
  }
}
