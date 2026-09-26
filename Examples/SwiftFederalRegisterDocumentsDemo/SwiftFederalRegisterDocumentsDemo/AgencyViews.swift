import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels
import SwiftUI

/// Agency lookup by slug and a link to the complete provider catalog.
struct AgencySection: View {
  let client: FederalRegisterClient

  @State private var slug = "environmental-protection-agency"

  var body: some View {
    Section("Agencies") {
      TextField("Agency slug", text: $slug)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
      NavigationLink("Load agency") {
        AgencyDetailView(client: client, identifier: AgencyIdentifier(rawValue: slug))
      }.disabled(slug.isEmpty)
      NavigationLink("Browse agency catalog") { AgencyCatalogView(client: client) }
    }
  }
}

/// The complete agency list from one request, filtered locally by name or slug.
struct AgencyCatalogView: View {
  let client: FederalRegisterClient

  @State private var agencies: [FederalRegisterAgency]?
  @State private var errorMessage: String?
  @State private var filter = ""

  var body: some View {
    List {
      if let errorMessage {
        Section("Request failed") { Text(errorMessage).foregroundStyle(.red) }
      } else if let agencies {
        Section {
          ForEach(Array(matching(agencies).enumerated()), id: \.offset) { _, agency in
            NavigationLink {
              List { AgencyRecordSections(agency: agency) }
                .navigationTitle(agency.shortName ?? agency.name ?? "Agency")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
              VStack(alignment: .leading) {
                Text(FieldText.describe(agency.name, key: "name", in: agency.fields))
                Text(FieldText.describe(agency.slug?.rawValue, key: "slug", in: agency.fields))
                  .font(.caption)
              }
            }
          }
        } footer: {
          Text(
            String(agencies.count)
              + " agencies returned by the provider, historical agencies included.")
        }
      } else {
        ProgressView("Loading agency catalog")
      }
    }
    .navigationTitle("Agency catalog")
    .searchable(text: $filter, prompt: "Filter by name or slug")
    .task { await load() }
  }

  private func load() async {
    guard agencies == nil else { return }
    do { agencies = try await client.agencies().agencies } catch {
      errorMessage = String(describing: error)
    }
  }

  private func matching(_ agencies: [FederalRegisterAgency]) -> [FederalRegisterAgency] {
    guard !filter.isEmpty else { return agencies }
    return agencies.filter { agency in
      (agency.name?.localizedCaseInsensitiveContains(filter) ?? false)
        || (agency.slug?.rawValue.localizedCaseInsensitiveContains(filter) ?? false)
    }
  }
}

/// Fetches one agency by slug and shows its fields or the request failure.
struct AgencyDetailView: View {
  let client: FederalRegisterClient
  let identifier: AgencyIdentifier

  @State private var agency: FederalRegisterAgency?
  @State private var errorMessage: String?

  var body: some View {
    List {
      if let errorMessage {
        Section("Agency request failed") { Text(errorMessage).foregroundStyle(.red) }
      } else if let agency {
        AgencyRecordSections(agency: agency)
      } else {
        ProgressView("Loading " + identifier.rawValue)
      }
    }
    .navigationTitle(identifier.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: identifier) { await load() }
  }

  private func load() async {
    errorMessage = nil
    do { agency = try await client.agency(identifier) } catch {
      errorMessage = String(describing: error)
    }
  }
}

/// The fields of one agency record, with absent, null, and empty values shown distinctly.
struct AgencyRecordSections: View {
  let agency: FederalRegisterAgency

  var body: some View {
    Section(FieldText.describe(agency.name, key: "name", in: agency.fields)) {
      row("Short name", agency.shortName, key: "short_name")
      row("Slug", agency.slug?.rawValue, key: "slug")
      row("ID", agency.id.map(String.init), key: "id")
      row("Parent ID", agency.parentID.map(String.init), key: "parent_id")
      row("Child IDs", agency.childIDs.map(list), key: "child_ids")
      row("Child slugs", agency.childSlugs.map { list($0.map(\.rawValue)) }, key: "child_slugs")
      row("Agency website", agency.agencyURL, key: "agency_url")
    }
    Section("Description") {
      Text(FieldText.describe(agency.description, key: "description", in: agency.fields))
    }
    Section {
      link("FederalRegister.gov page", agency.url, key: "url")
      link("Recent documents", agency.recentArticlesURL, key: "recent_articles_url")
      row("JSON URL as advertised", agency.jsonURL, key: "json_url")
      row("Logo", agency.logo?.thumbURL, key: "logo")
    } header: {
      Text("Provider links")
    } footer: {
      Text("Retained raw fields: " + String(agency.fields.count) + ".")
    }
  }

  private func link(_ title: String, _ value: String?, key: String) -> some View {
    Group {
      if let value, !value.isEmpty, let url = URL(string: value) {
        Link(title, destination: url)
      } else {
        row(title, value, key: key)
      }
    }
  }

  private func list<Element: CustomStringConvertible>(_ values: [Element]) -> String {
    values.isEmpty ? "Empty" : values.map(\.description).joined(separator: ", ")
  }

  private func row(_ title: String, _ value: String?, key: String) -> some View {
    LabeledContent(title) {
      Text(FieldText.describe(value, key: key, in: agency.fields)).multilineTextAlignment(.trailing)
    }
  }
}
