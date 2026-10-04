import Foundation

/// Recorded OFR/NARA and GPO responses; exact requests and hashes are in Fixtures/receipts.json.
package enum Fixture: String, CaseIterable, Sendable {
  /// `/api/v1/agencies.json`.
  case agencyCatalog = "agencies.json"
  /// `/api/v1/agencies/environmental-protection-agency.json`.
  case agencyEPA = "agency-epa.json"
  /// `/api/v1/agencies/health-and-human-services-department.json`.
  case agencyHHS = "agency-hhs.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case batchMissingDuplicate = "batch-missing-duplicate.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case batchPublished = "batch-published.json"
  /// `/api/v1/documents/2026-19417.json`.
  case currentDocument = "current-document.json"
  /// `/documents/full_text/html/2026/09/22/2026-19417.html`.
  case currentHTML = "current-content.html"
  /// `/documents/full_text/text/2026/09/22/2026-19417.txt`.
  case currentText = "current-content.txt"
  /// `/documents/full_text/xml/2026/09/22/2026-19417.xml`.
  case currentXML = "current-content.xml"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case eoTerm = "eo-term.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case eoTermTwo = "eo-term-two.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case eoUnfiltered = "eo-unfiltered.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case executiveOrder = "executive-order.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case executiveOrderTwo = "executive-order-two.json"
  /// Derived name lists from the attributed September 29 schema; not an HTTP response body.
  case expandedVocabulary = "expanded-vocabulary.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsAgency = "facets-agency.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsDaily = "facets-daily.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsEmpty = "facets-empty.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsMonthlyYear = "facets-monthly-year.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsQuarterly = "facets-quarterly.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsSection = "facets-section.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsSubtypeYear = "facets-subtype-year.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsTopic = "facets-topic.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsTopicFilter = "facets-topic-filter.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsType = "facets-type.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsWeekly = "facets-weekly.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case facetsYearly = "facets-yearly.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case fieldsDetail = "fields-detail.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case fieldsUnknown = "fields-unknown.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case geographic = "geographic.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case geographicTwo = "geographic-two.json"
  /// `/api/v1/documents/93-32104.json`.
  case historicalDocument = "historical-document.json"
  /// `/documents/full_text/html/1994/01/03/93-32104.html`, HTTP 404.
  case historicalHTMLFailure = "historical-content.html"
  /// `/api/v1/documents.json?conditions[type][]=PRESDOCU&conditions[publication_date][is]=1994-01-03&order=newest&per_page=2`.
  case historicalPage = "historical-page.json"
  /// `/documents/full_text/text/1994/01/03/93-32104.txt`, an HTML wrapper served as text/plain.
  case historicalText = "historical-content.txt"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionBatch = "inspection-batch.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionBatchAllMissing = "inspection-batch-all-missing.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionBatchMissing = "inspection-batch-missing.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionBatchSingle = "inspection-batch-single.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionCurrent = "inspection-current.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionDateEmpty = "inspection-date-empty.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionDateOnly = "inspection-date-only.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionDetail = "inspection-detail.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionFilteredFields = "inspection-filtered-fields.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionFilteredFieldsTwo = "inspection-filtered-fields-two.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionSearch = "inspection-search.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionSearchTwo = "inspection-search-two.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case inspectionZero = "inspection-zero.json"
  /// An HTTP 400 from `/api/v1/documents` for a `search_after_cursor=invalid` probe (2026-09-24).
  /// The full request query was never logged; only this fragment, the status, and the response
  /// body bytes are evidenced.
  case invalidCursorFailure = "invalid-cursor.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case issue = "issue.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case issueNonpublication = "issue-nonpublication.json"
  /// `/api/v1/documents.json?conditions[type][]=PRESDOCU&order=newest&per_page=2`.
  case pageOne = "presidential-page-one.json"
  /// The exact `next_page_url` of pageOne, including its search_after_cursor; see receipts.json.
  case pageTwo = "presidential-page-two.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case publishedBatchAllMissing = "published-batch-all-missing.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case publishedBatchReverseFields = "published-batch-reverse-fields.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case publishedBatchSingle = "published-batch-single.json"
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
  /// `/api/v1/documents.json?conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31&conditions[term]=clean%20water&order=newest`
  /// `&per_page=2`. Its `next_page_url` sends the space as `+` and carries no search_after_cursor.
  case searchSpacedTermPageOne = "search-spaced-term-page-one.json"
  /// `/api/v1/documents.json?order=newest&per_page=2&conditions[publication_date][gte]=2024-01-01`
  /// `&conditions[publication_date][lte]=2024-12-31&conditions[term]=codexNoMatchingDocument987654321`.
  case searchTerminal = "search-terminal.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case significant0 = "significant-0.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case significant1 = "significant-1.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case significant1Two = "significant-1-two.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case sparseTitle = "sparse-title.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case suggestedCatalog = "suggested-catalog.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case suggestedDetail = "suggested-detail.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case suggestedSection = "suggested-section.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case topicFilterCrosscheck = "topic-filter-crosscheck.json"
  /// Recorded official response; exact URL, status, and digest are retained in receipts.json.
  case topicsSections = "topics-sections.json"

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
