# ``SwiftFederalRegisterDocumentsModels``

Describe Federal Register document, search, and agency operations and preserve their source evidence
without a networking dependency.

## Overview

Use ``FederalRegisterDocument`` for detail responses and list entries, ``DocumentPage`` for search
envelopes, ``DocumentSearchQuery`` for general document searches, ``DocumentQuery`` for
presidential-document filters, and ``FederalRegisterAgency`` for agency records. All JSON attributes
remain in `fields`, including unknown attributes and explicit nulls. Dates remain strings: a signing date
is not a publication date, and a conflicting descriptive date is never reconciled automatically.

```swift
let request = try DocumentRequest.document("93-32104")
let endpoint = request.endpoint
let document = try FederalRegisterDocument.decode(downloadedBytes)
```

Create custom responses by conforming a `Decodable` type to ``DocumentResponse``. Its default decoder reads
JSON; custom conformances can supply a source-specific decoder. ``DocumentContent`` reads UTF-8 source
without stripping HTML or interpreting XML. In the recorded 1994 sample, the text endpoint returns an
HTML `pre` wrapper even though its Content-Type is text/plain. Original bytes remain available in SDK receipts.

## General search inputs

``DocumentSearchQuery`` describes a search of every document type. It adds no condition of its own, so an
empty query asks for every document in the provider's default projection. ``DocumentQuery`` stays
presidential-only and always sends the presidential type condition.

```swift
let search = try DocumentSearchQuery(
  agencies: [.environmentalProtectionAgency],
  cfr: CFRFilter(part: "52", title: 40),
  effectiveDate: .inYear(2025),
  publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
  term: "water",
  types: [.proposedRule, .rule])
let first = DocumentRequest.searchDocuments(matching: search)
let endpoint = Endpoint<DocumentPage>.searchDocuments(matching: search)
```

``DocumentDateFilter`` has three forms, created only by its throwing factories: a single date from
``DocumentDateFilter/on(_:)``, an inclusive range with at least one bound from
``DocumentDateFilter/range(from:through:)``, or a calendar year from ``DocumentDateFilter/inYear(_:)``.
Dates are real Gregorian `YYYY-MM-DD` strings kept exactly as given, never converted to instants or time
zones. The query property that carries a filter decides which document date it constrains: publication
and effective dates are separate conditions.

``CFRFilter`` names a Code of Federal Regulations title, optionally with a part or an inclusive part range
such as `"1-50"`. Parts are ASCII digits, keep their spelling and leading zeros, and compare numerically.
A filter names a location to search for; it says nothing about whether that location exists.

Agencies and types are sent as repeated `conditions[agencies][]` and `conditions[type][]` parameters, with
their order and multiplicity intact. The provider does not document how it combines repeated values, so
this package promises no AND, OR, or parent-agency expansion. Unknown agency slugs and type codes are
valid inputs. Terms, docket identifiers, and Regulation Identifier Numbers are sent as written, without
trimming or interpretation of the provider's full-text syntax.

A general search offers newest and oldest chronological order. Relevance order is not a query option; a
consumer can build it as a custom ``Endpoint`` from a provider link with ``Endpoint/init(accept:link:)``.

## Agency discovery

``AgencyList`` is the complete `/api/v1/agencies.json` response, a bare array with no envelope and no
pagination. ``FederalRegisterAgency`` is one record from that list or from `/api/v1/agencies/{slug}.json`.
Every property is a projection of `fields`, and a record missing its slug or name still decodes.

```swift
let list = try AgencyList.decode(agencyListBytes)
let epa = list.agencies.first { $0.slug == .environmentalProtectionAgency }
let lookup = try DocumentRequest.agency(.environmentalProtectionAgency)
```

``AgencyIdentifier`` is an agency slug. Its static members are generated from one recorded snapshot of the
provider's catalog, so they are a convenience, not the set of agencies that exist. The snapshot includes
historical agencies alongside current ones; it is not an active-only list, and a member's presence says
nothing about whether that agency still publishes. Any other slug is representable through
``AgencyIdentifier/init(rawValue:)``. Retrieve the provider's current list for discovery.

A slug is the identity this package sends. Numeric agency IDs, parent IDs, and child IDs are preserved as
the provider publishes them, and each record's `json_url` remains the provider's numeric `http` link
without being rewritten or fetched. The provider marks numeric agency lookup as deprecated, so requests
are built from slugs only.

A document's ``FederalRegisterDocument/agencies`` lists ``DocumentAgency`` attributions as printed at
publication. Their ``DocumentAgency/name`` and ``DocumentAgency/slug`` link to the provider's current
catalog where a match exists, and ``DocumentAgency/rawName`` keeps the printed name. The current
catalog's hierarchy does not describe the agency that published a historical document.

## Regulatory metadata

``FederalRegisterDocument`` projects regulatory metadata from `fields`: ``CFRReference`` values for the
CFR locations a document names, Regulation Identifier Numbers with their ``RegulationIDNumberInfo``,
docket identifiers, the `significant` flag, and the document's ``DocumentType``.

```swift
let rule = try FederalRegisterDocument.decode(detailBytes)
for reference in rule.cfrReferences ?? [] {
  print(reference.title.map(String.init) ?? "?", reference.part ?? "?")
}
print(rule.regulationIDNumbers ?? [], rule.docketIDs ?? [], rule.significant as Any)
```

No projection is ever a decoding failure. A projection is nil when its key is absent, explicitly null,
or of an unexpected JSON kind, while `fields` keeps the raw value, so a missing key, a null, an empty
array, `false`, and zero stay distinguishable there. ``FederalRegisterDocument/cfrReferences`` is all or
nothing: one reference with an incompatible title, part, or citation link makes the whole list nil. The
agency list and the Regulation Identifier Number details require JSON objects, but an odd property inside
one object only makes that property nil. The CFR chapter has no typed projection because no recorded
response carries a non-null chapter; read it from ``CFRReference/fields``.

Search results carry only the provider's default search projection, so most regulatory projections are
nil on search results by design. Retrieve a document's detail to read its full metadata.

Document types have two vocabularies. A document publishes a ``DocumentType`` display label such as
`Rule`, while searches accept a ``DocumentTypeCode`` such as `RULE`. ``DocumentType/code`` maps only the
four documented labels to their codes and is nil for any other label rather than guessing. Both types
keep unknown values.

## Source contracts

The [official API contract](https://www.federalregister.gov/api/v1/documentation) describes search since
1994 and page sizes of 1 through 1000, defaulting to 20. Queries impose no product-era cutoff. Actual
source holdings determine availability. Newest and oldest chronological order are supported by both
query types.

Next links are verified from recorded responses. Cursors remain opaque, and every link retains its
source query parameters. `total_pages` can be capped at 50 while `next_page_url` continues, so it never
controls traversal, and pages beyond the provider's depth cap are not guaranteed. An absent or null next
link ends traversal, as does a zero-match page. A next link continues by a cursor or, as recorded term
searches publish, by a strictly increasing page number, where only an absent current `page` counts as 1
and any present `page` must be a single integer; a link with neither, changed filters, an unsafe
origin/path, a repeated cursor, or a nonprogressing page fails explicitly. Every library-created
sequence, presidential included, shares this rule. These checks do not promise a stable snapshot,
freshness, or a complete result set. Search results and the agency list arrive in the
provider's order.

OFR/NARA and GPO publish the source. FederalRegister.gov's renditions are informational; GPO publishes
the official edition. An advertised format link can fail: the recorded 1994 HTML link returned 404,
while its PDF and XML fields were null. No replacement URLs are synthesized. A document's publication
date is not the date of the action it records, and a missing Federal Register record does not prove that
an action did not occur.

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
