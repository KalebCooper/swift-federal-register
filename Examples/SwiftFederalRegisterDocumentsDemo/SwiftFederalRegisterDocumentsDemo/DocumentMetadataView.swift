import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftUI

/// Describes a typed projection next to the raw field it came from, so an absent key, an explicit
/// null, an empty value, and an unrecognized kind stay distinguishable on screen.
enum FieldText {
  static func describe(_ value: String?, key: String, in fields: [String: JSONValue]) -> String {
    if let value { return value.isEmpty ? "Empty string" : value }
    return missing(key: key, in: fields)
  }

  static func describe(_ value: Int?, key: String, in fields: [String: JSONValue]) -> String {
    if let value { return String(value) }
    return missing(key: key, in: fields)
  }

  static func describe(_ values: [String]?, key: String, in fields: [String: JSONValue]) -> String {
    if let values { return values.isEmpty ? "Empty" : values.joined(separator: ", ") }
    return missing(key: key, in: fields)
  }

  static func missing(key: String, in fields: [String: JSONValue]) -> String {
    switch fields[key] {
    case nil: "Not supplied (field absent)"
    case .null: "Not supplied (null)"
    case .array(let values) where values.isEmpty: "Empty"
    case .object(let values) where values.isEmpty: "Empty"
    case .string(let value) where value.isEmpty: "Empty string"
    default: "Not supplied (unrecognized kind, raw value kept)"
    }
  }
}

/// Fetches one document explicitly and shows its typed regulatory metadata.
struct DocumentMetadataView: View {
  let client: FederalRegisterClient
  let number: String

  @State private var document: FederalRegisterDocument?
  @State private var errorMessage: String?

  var body: some View {
    List {
      if let errorMessage {
        Section("Request failed") { Text(errorMessage).foregroundStyle(.red) }
      } else if let document {
        summary(document)
        agencies(document)
        cfrReferences(document)
        regulationIDNumbers(document)
        dockets(document)
        links(document)
      } else {
        ProgressView("Loading " + number)
      }
    }
    .navigationTitle(number)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: number) { await load() }
  }

  private func agencies(_ document: FederalRegisterDocument) -> some View {
    Section("Agencies") {
      if let agencies = document.agencies, !agencies.isEmpty {
        ForEach(Array(agencies.enumerated()), id: \.offset) { _, agency in
          VStack(alignment: .leading) {
            Text(FieldText.describe(agency.name, key: "name", in: agency.fields))
            Text(
              "Slug: " + FieldText.describe(agency.slug?.rawValue, key: "slug", in: agency.fields)
            )
            .font(.caption)
            Text(
              "Raw name: " + FieldText.describe(agency.rawName, key: "raw_name", in: agency.fields)
            )
            .font(.caption)
          }
        }
      } else {
        Text(FieldText.missing(key: "agencies", in: document.fields))
      }
    }
  }

  private func cfrReferences(_ document: FederalRegisterDocument) -> some View {
    Section("CFR references") {
      if let references = document.cfrReferences, !references.isEmpty {
        ForEach(Array(references.enumerated()), id: \.offset) { _, reference in
          VStack(alignment: .leading) {
            Text(
              "Title " + FieldText.describe(reference.title, key: "title", in: reference.fields)
                + ", part " + FieldText.describe(reference.part, key: "part", in: reference.fields))
            if let link = reference.citationURL, let url = URL(string: link) {
              Link("eCFR citation", destination: url).font(.caption)
            } else {
              Text(
                "Citation link: "
                  + FieldText.describe(
                    reference.citationURL, key: "citation_url", in: reference.fields)
              ).font(.caption)
            }
          }
        }
      } else {
        Text(FieldText.missing(key: "cfr_references", in: document.fields))
      }
    }
  }

  private func dockets(_ document: FederalRegisterDocument) -> some View {
    Section("Dockets") {
      LabeledContent(
        "Docket ID",
        value: FieldText.describe(document.docketID, key: "docket_id", in: document.fields))
      LabeledContent(
        "Docket IDs",
        value: FieldText.describe(document.docketIDs, key: "docket_ids", in: document.fields))
    }
  }

  private func link(
    _ title: String, _ value: String?, key: String, in document: FederalRegisterDocument
  ) -> some View {
    Group {
      if let value, let url = URL(string: value) {
        Link(title, destination: url)
      } else {
        LabeledContent(title, value: FieldText.describe(value, key: key, in: document.fields))
      }
    }
  }

  private func links(_ document: FederalRegisterDocument) -> some View {
    Section {
      link("HTML page", document.htmlURL, key: "html_url", in: document)
      link("GPO PDF", document.pdfURL, key: "pdf_url", in: document)
      link("JSON record", document.jsonURL, key: "json_url", in: document)
      link(
        "Regulations.gov", document.regulationsDotGovURL, key: "regulations_dot_gov_url",
        in: document)
    } header: {
      Text("Source links")
    } footer: {
      Text(
        "Published by the Office of the Federal Register (NARA) and the Government Publishing Office. "
          + "Values appear as supplied; dates are not normalized. Retained raw fields: "
          + String(document.fields.count) + ".")
    }
  }

  private func load() async {
    errorMessage = nil
    do { document = try await client.document(number) } catch {
      errorMessage = String(describing: error)
    }
  }

  private func regulationIDNumbers(_ document: FederalRegisterDocument) -> some View {
    Section("Regulation Identifier Numbers") {
      LabeledContent(
        "RINs",
        value: FieldText.describe(
          document.regulationIDNumbers, key: "regulation_id_numbers", in: document.fields))
      if let info = document.regulationIDNumberInfo, !info.isEmpty {
        ForEach(info.keys.sorted(), id: \.self) { key in
          if let entry = info[key] {
            VStack(alignment: .leading) {
              Text(key).font(.caption.monospaced())
              Text(FieldText.describe(entry.title, key: "title", in: entry.fields))
              Text(
                "Priority: "
                  + FieldText.describe(
                    entry.priorityCategory, key: "priority_category", in: entry.fields)
              ).font(.caption)
            }
          }
        }
      } else {
        LabeledContent(
          "RIN details",
          value: FieldText.missing(key: "regulation_id_number_info", in: document.fields))
      }
    }
  }

  private func significance(_ document: FederalRegisterDocument) -> String {
    switch document.significant {
    case true?: "Yes"
    case false?: "No"
    case nil: FieldText.missing(key: "significant", in: document.fields)
    }
  }

  private func summary(_ document: FederalRegisterDocument) -> some View {
    Section(document.title) {
      LabeledContent("Document number", value: document.documentNumber)
      LabeledContent(
        "Type",
        value: document.documentType.map { type in
          type.rawValue + " (" + (type.code?.rawValue ?? "no known code") + ")"
        } ?? FieldText.missing(key: "type", in: document.fields))
      LabeledContent(
        "Action", value: FieldText.describe(document.action, key: "action", in: document.fields))
      LabeledContent(
        "Publication",
        value: FieldText.describe(
          document.publicationDate, key: "publication_date", in: document.fields))
      LabeledContent(
        "Effective on",
        value: FieldText.describe(document.effectiveOn, key: "effective_on", in: document.fields))
      LabeledContent(
        "Comments close",
        value: FieldText.describe(
          document.commentsCloseOn, key: "comments_close_on", in: document.fields))
      LabeledContent(
        "Citation",
        value: FieldText.describe(document.citation, key: "citation", in: document.fields))
      LabeledContent("Significant", value: significance(document))
    }
  }
}
