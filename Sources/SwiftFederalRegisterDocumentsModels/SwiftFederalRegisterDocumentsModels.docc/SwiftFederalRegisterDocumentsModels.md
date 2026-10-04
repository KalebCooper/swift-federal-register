# ``SwiftFederalRegisterDocumentsModels``

Describe Federal Register requests and decode their responses, with no networking dependency.

## Overview

This module has no dependencies. Use it on its own with any networking stack, or with
`SwiftFederalRegisterDocuments`, which sends these descriptions for you.

```swift
let endpoint = try Endpoint<FederalRegisterDocument>.document("2024-31396")
// GET https://www.federalregister.gov/api/v1/documents/2024-31396.json
// Accept: application/json
let document = try FederalRegisterDocument.decode(responseBody)
print(document.title, document.publicationDate ?? "")
```

Send a GET to `https://www.federalregister.gov` plus ``Endpoint/path``, set `Accept` to
``Endpoint/accept``, and decode with the response type. A ``DocumentRequest`` wraps the same
operation as a reusable value whose `resolution` a custom executor can interpret.

Responses keep everything the service sends. ``FederalRegisterDocument``, ``DocumentPage``, and
``FederalRegisterAgency`` hold every JSON attribute in `fields`, including unknown attributes and
explicit nulls, and expose typed projections alongside. Dates stay strings: a signing date is not a
publication date, and conflicting dates are never reconciled.

### Search queries

``DocumentSearchQuery`` searches every document type and adds no condition of its own.
``DocumentQuery`` always searches presidential documents.

```swift
let search = try DocumentSearchQuery(
  agencies: [.environmentalProtectionAgency],
  cfr: CFRFilter(part: "52", title: 40),
  effectiveDate: .inYear(2025),
  publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
  term: "water",
  types: [.proposedRule, .rule])
let request = DocumentRequest.searchDocuments(matching: search)
```

``DocumentDateFilter`` is a single day from ``DocumentDateFilter/on(_:)``, an inclusive range from
``DocumentDateFilter/range(from:through:)``, or a calendar year from
``DocumentDateFilter/inYear(_:)``. Dates are validated Gregorian `YYYY-MM-DD` strings, kept as given
and never converted to instants. ``CFRFilter`` names a CFR title, optionally with a part or a part
range such as `"1-50"`.

Strings are sent exactly as written. Repeated agencies and types are sent as repeated parameters; the
service does not document whether it combines them with AND or OR, and this package promises
neither. Unknown agency slugs and type codes are valid inputs. Results are newest or oldest first;
relevance order is not a query option, though a consumer can build it as a custom ``Endpoint`` with
``Endpoint/init(accept:link:)``.

### Paging

A ``DocumentPage`` carries its results and the service's `next_page_url`.
``DocumentPage/continuation(after:seenCursors:)`` validates that link and returns the next endpoint,
or nil at the end. It accepts an opaque cursor or, as term searches publish, a strictly increasing
page number, and throws ``DocumentPaginationError`` for another origin or path, changed filters, a
repeated cursor, or a page that does not move forward. `total_pages` can be capped at 50 while the
next link continues, so it never ends traversal.

### Agencies

``AgencyList`` is the complete agency catalog, and ``FederalRegisterAgency`` one record from it or
from an agency's detail route.

```swift
let catalog = try AgencyList.decode(responseBody)
let epa = catalog.agencies.first { $0.slug == .environmentalProtectionAgency }
let lookup = try DocumentRequest.agency(.environmentalProtectionAgency)
```

``AgencyIdentifier`` is an agency slug. Its static members are generated from one recorded catalog,
historical agencies included, so they are a convenience, not the set of agencies that exist; any
other slug works through ``AgencyIdentifier/init(rawValue:)``. Numeric agency, parent, and child IDs
are preserved but never used to build a request.

A document's ``FederalRegisterDocument/agencies`` lists ``DocumentAgency`` attributions as printed at
publication. ``DocumentAgency/rawName`` keeps the printed name, while ``DocumentAgency/name`` and
``DocumentAgency/slug`` point at the current catalog where a match exists.

### Regulatory metadata

```swift
let rule = try FederalRegisterDocument.decode(responseBody)
for reference in rule.cfrReferences ?? [] {
  print(reference.title.map(String.init) ?? "?", reference.part ?? "?")
}
print(rule.regulationIDNumbers ?? [], rule.docketIDs ?? [], rule.significant as Any)
```

A projection is never a decoding failure. It is nil when its key is absent, null, or of an
unexpected JSON kind, while `fields` keeps the raw value. ``FederalRegisterDocument/cfrReferences``
is all or nothing: one malformed reference makes the whole list nil. Search results carry only the
service's default fields, so most regulatory projections are nil on them; decode a document's detail
to read its full metadata.

Documents publish a ``DocumentType`` label such as `Rule`, while searches take a ``DocumentTypeCode``
such as `RULE`. ``DocumentType/code`` maps only the four documented labels and is nil for any other.

### Full text

``DocumentContent`` decodes an HTML, text, or XML representation as the exact UTF-8 source. It does
not strip HTML or interpret XML. Older text representations can arrive wrapped in an HTML `pre`
element even when labeled `text/plain`.

Create a custom response by conforming a `Decodable` type to ``DocumentResponse``. Its default decoder
reads JSON; a conformance can supply its own.

### Source and availability

The [official API documentation](https://www.federalregister.gov/api/v1/documentation) describes
search since 1994 and page sizes of 1 through 1000, defaulting to 20. OFR/NARA and GPO publish the
source; FederalRegister.gov renditions are informational, and GPO publishes the official edition.

Older documents can have null PDF or XML links, and an advertised link can return 404. No replacement
link is guessed. A publication date is not the date of the action a document records, and a missing
Federal Register record does not prove that an action did not occur.

## Topics

### Documents

- ``FederalRegisterDocument``
- ``DocumentPage``
- ``JSONValue``
- ``DocumentContent``
- ``DocumentRepresentation``

### Regulatory metadata

- ``CFRReference``
- ``RegulationIDNumberInfo``
- ``DocumentType``
- ``DocumentTypeCode``

### Agencies

- ``AgencyIdentifier``
- ``AgencyList``
- ``FederalRegisterAgency``
- ``AgencyLogo``
- ``DocumentAgency``

### Search inputs

- ``DocumentSearchQuery``
- ``DocumentDateFilter``
- ``CFRFilter``
- ``DocumentQuery``

### Operations

- ``DocumentRequest``
- ``Endpoint``
- ``DocumentResponse``

### Receipts and failures

- ``SourceResponse``
- ``SourceHeader``
- ``DocumentContentError``
- ``DocumentPaginationError``
- ``DocumentValidationError``

## Selected fields

Use `DocumentField` with document detail or `DocumentSearchQuery(fields:significant:)`.
An empty selection preserves provider defaults. A nonempty selection includes `document_number`
and `title`; it does not inject values into a sparse response. False significance sends `0`.
Unknown field names are preserved and may be rejected by the provider.

- ``DocumentField``

## Batch lookup

`DocumentRequest.documents(numbered:fields:)` performs one request. Source partial errors remain
successful response data. Singleton results retain the original detail object and have no source count.
No batching ceiling is promised, and the SDK does not chunk or retry missing records.

- ``BatchLookupErrors``
- ``DocumentBatch``

## Additional search conditions

Topic and section slugs remain open values. Geographic search sends location text unchanged;
a nil radius preserves the provider default, while explicit values must be 1...200 miles.
Executive-order-number ordering preserves null-numbered corrections and adds no subtype condition.
Use `.executiveOrder` for the typed presidential query subtype, or `.init(rawValue:)` for future codes.

- ``DocumentLocation``
- ``PresidentialDocumentTypeCode``
- ``SectionIdentifier``
- ``TopicIdentifier``

## Facets

Facet requests reuse search conditions and exclude fields, page size, and order. Topic conditions
are supported by a retained live capture despite their omission from the schema's facet parameters.
Counts carry no sum-to-total or mutually-exclusive-bucket guarantee.

- ``DocumentFacet``
- ``DocumentFacetBucket``
- ``DocumentFacetCounts``

## Daily issues

Issue contents retain source groups and document-number references. Resolve references with an
explicit separate `documents(numbered:)` operation when needed; reading an issue performs no hydration.

- ``IssueTableOfContents``

## Public inspection

Public inspection previews scheduled documents; an intended publication date is not proof of final
publication, and absence is not proof of withdrawal. Current and dated listings are single responses.
The dated listing accepts only its date because the provider ignores other search filters in that mode.

- ``PublicInspectionBatch``
- ``PublicInspectionDocument``
- ``PublicInspectionFilingType``
- ``PublicInspectionListing``

## Inspection search

Inspection search uses a separate query and page family. Its next links use verified underscore
aliases with exact routing parameters. Only increasing page numbers continue; cursors are rejected.
Current and dated listings never become search sequences. Counts do not guarantee exhaustive coverage.

- ``PublicInspectionDocumentField``
- ``PublicInspectionFilingFilter``
- ``PublicInspectionPage``
- ``PublicInspectionQuery``

## Suggested searches

Suggested searches are discovery metadata. Conditions can contain internal agency IDs and incomplete
geographic conditions; the SDK neither converts them into a query nor executes them automatically.
Description markup is retained without rendering. Counts and position may be absent from details.

- ``SuggestedSearch``
- ``SuggestedSearchCatalog``
- ``SuggestedSearchIdentifier``
