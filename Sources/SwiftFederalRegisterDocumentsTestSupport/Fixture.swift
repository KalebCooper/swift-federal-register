import Foundation

/// Recorded OFR/NARA and GPO responses; exact requests and hashes are in Fixtures/receipts.json.
package enum Fixture: String, CaseIterable, Sendable {
  /// `/api/v1/agencies.json`.
  case agencyCatalog = "agencies.json"
  /// `/api/v1/agencies/environmental-protection-agency.json`.
  case agencyEPA = "agency-epa.json"
  /// `/api/v1/agencies/health-and-human-services-department.json`.
  case agencyHHS = "agency-hhs.json"
  /// `/api/v1/documents/2026-19417.json`.
  case currentDocument = "current-document.json"
  /// `/documents/full_text/html/2026/09/22/2026-19417.html`.
  case currentHTML = "current-content.html"
  /// `/documents/full_text/text/2026/09/22/2026-19417.txt`.
  case currentText = "current-content.txt"
  /// `/documents/full_text/xml/2026/09/22/2026-19417.xml`.
  case currentXML = "current-content.xml"
  /// `/api/v1/documents/93-32104.json`.
  case historicalDocument = "historical-document.json"
  /// `/documents/full_text/html/1994/01/03/93-32104.html`, HTTP 404.
  case historicalHTMLFailure = "historical-content.html"
  /// `/api/v1/documents.json?conditions[type][]=PRESDOCU&conditions[publication_date][is]=1994-01-03&order=newest&per_page=2`.
  case historicalPage = "historical-page.json"
  /// `/documents/full_text/text/1994/01/03/93-32104.txt`, an HTML wrapper served as text/plain.
  case historicalText = "historical-content.txt"
  /// An HTTP 400 from `/api/v1/documents` for a `search_after_cursor=invalid` probe (2026-09-24).
  /// The full request query was never logged; only this fragment, the status, and the response
  /// body bytes are evidenced.
  case invalidCursorFailure = "invalid-cursor.json"
  /// `/api/v1/documents.json?conditions[type][]=PRESDOCU&order=newest&per_page=2`.
  case pageOne = "presidential-page-one.json"
  /// The exact `next_page_url` of pageOne, including its search_after_cursor; see receipts.json.
  case pageTwo = "presidential-page-two.json"
  /// `/api/v1/documents/2024-31396.json`.
  case regulatoryDocument = "regulatory-document.json"
  /// `/api/v1/documents/2024-29463.json`.
  case rinDocument = "rin-document.json"
  /// `/api/v1/documents.json?order=newest&per_page=2&conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31&conditions[agencies][]=environmental-protection-agency`
  /// `&conditions[type][]=RULE` plus the complete repeated `fields[]` selection recorded in
  /// receipts.json.
  case searchFieldsPageOne = "search-fields-page-one.json"
  /// The exact `next_page_url` of searchFieldsPageOne, including every repeated `fields[]`
  /// parameter and its search_after_cursor; see receipts.json.
  case searchFieldsPageTwo = "search-fields-page-two.json"
  /// `/api/v1/documents.json?order=newest&per_page=2&conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31`.
  case searchNewestPageOne = "search-newest-page-one.json"
  /// The exact `next_page_url` of searchNewestPageOne, including its search_after_cursor; see
  /// receipts.json.
  case searchNewestPageTwo = "search-newest-page-two.json"
  /// `/api/v1/documents.json?order=oldest&per_page=2&conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31`.
  case searchOldestPageOne = "search-oldest-page-one.json"
  /// The exact `next_page_url` of searchOldestPageOne, including its search_after_cursor; see
  /// receipts.json.
  case searchOldestPageTwo = "search-oldest-page-two.json"
  /// `/api/v1/documents.json?order=relevance&per_page=2&conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31&conditions[term]=water`.
  case searchRelevancePageOne = "search-relevance-page-one.json"
  /// `/api/v1/documents.json?order=newest&per_page=2&conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31&conditions[term]=codexNoMatchingDocument987654321`.
  case searchTerminal = "search-terminal.json"

  /// Reads the original bytes from package resources.
  package func data() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: rawValue, withExtension: nil, subdirectory: "Fixtures")
    else {
      throw CocoaError(.fileNoSuchFile)
    }
    return try Data(contentsOf: url)
  }
}
