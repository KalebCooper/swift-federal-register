import Foundation

/// Recorded OFR/NARA and GPO responses; exact requests and hashes are in Fixtures/receipts.json.
package enum Fixture: String, CaseIterable, Sendable {
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
  /// `/api/v1/documents.json?conditions[type][]=PRESDOCU&order=newest&per_page=2`.
  case pageOne = "presidential-page-one.json"
  /// The exact `next_page_url` of pageOne, including its search_after_cursor; see receipts.json.
  case pageTwo = "presidential-page-two.json"

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
