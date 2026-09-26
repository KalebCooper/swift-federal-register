# ``SwiftFederalRegisterDocuments``

Retrieve Federal Register documents, source representations, agencies, and lazy general and
presidential document search pages.

## Overview

Everyday methods, reusable requests, and typed endpoints share the same execution path and failures.
No API key is required. Supply your application's User-Agent identity explicitly.

```swift
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels

let client = FederalRegisterClient(userAgent: "(MyApp, contact@example.com)")
let document = try await client.document("93-32104")
let same = try await client.value(for: .document("93-32104"))
let direct = try await client.send(.document("93-32104"))
let content = try await client.content(.text, for: document)
```

The URLSession convenience is Apple-only. On Linux and Android enable `HTTPPortable` and inject a
swifty-networking portable transport. Models remain usable with any HTTP stack.

## General search

A `DocumentSearchQuery` searches every document type, filtered by
agencies, CFR location, docket, effective and publication dates, Regulation Identifier Number, full-text
term, and type codes. It adds no condition of its own. The same search runs at three levels, with the
same request and the same failures:

```swift
let query = try DocumentSearchQuery(
  agencies: [.environmentalProtectionAgency],
  publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
  types: [.rule])
let page = try await client.searchDocuments(matching: query)
let samePage = try await client.value(for: .searchDocuments(matching: query))
let directPage = try await client.send(.searchDocuments(matching: query))
```

Each of these retrieves only the first page. A zero-match search returns an empty page whose `count` is 0.
Repeated agencies and types are sent as repeated parameters; the provider does not document whether it
combines them with AND or OR, and this package promises neither.

The `searching:` sequences traverse later pages lazily:

```swift
for try await document in client.documents(searching: query) {
  print(document.documentNumber, document.title)
}
```

Search results carry only the provider's default search projection, so regulatory metadata such as CFR
references and Regulation Identifier Numbers is usually nil on them. A result never triggers a detail
fetch. Retrieve the detail explicitly when you need it:

```swift
for try await result in client.documents(searching: query) {
  let detail = try await client.document(result.documentNumber)
  print(detail.cfrReferences ?? [], detail.regulationIDNumbers ?? [])
  break
}
```

General searches are newest or oldest first. Relevance order is not a query option. A consumer-defined
relevance `Endpoint` runs through `send(_:)`, `value(for:)`, or
`documentPages(for:)`, and the sequences yield only its first page because they follow links only for
library-created search requests. To go further, validate the page's next link with
`DocumentPage.continuation(after:seenCursors:)` and send the endpoint
it returns.

## Agency discovery

```swift
let list = try await client.agencies()
let epa = try await client.agency(.environmentalProtectionAgency)
print(list.agencies.count, epa.name ?? "", epa.childSlugs ?? [])
```

``FederalRegisterClient/agencies()`` retrieves the provider's complete agency list in one request, in the
provider's order; the recorded list includes historical agencies. It has no page sequence. Use it for discovery; the
generated `AgencyIdentifier` members come from one recorded
snapshot and are not the set of agencies that exist. ``FederalRegisterClient/agency(_:)`` validates the
slug before sending and sends any well-formed slug, cataloged or not; an unknown slug returns the
provider's HTTP failure. Logos, agency links, parents, and children are never fetched automatically.

## Lazy traversal

```swift
let presidential = try DocumentQuery(
  pageSize: 20, publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
for try await document in client.documents(matching: presidential) {
  print(document.documentNumber, document.title)
}
for try await page in client.documentPages(searching: query) {
  print(page.count, page.results.count)
}
```

Construction and iterator creation send nothing. Each iterator starts independently; one page is fetched
only when needed, with no prefetch. Items preserve source order and duplicates. Cancellation is checked
before requests and while draining buffered items. Early break sends no further requests. Any failure
terminates the iterator, and later reads return nil. Previous results are not a complete result set.

`documentPages(for:)`, `documentResponses(for:)`, and `documents(for:)` accept reusable requests. Library
general and presidential search requests follow the provider's validated next links, which continue by an
opaque cursor or, for term searches, by a strictly increasing page number. The provider caps its page
depth and does not promise pages beyond it; `total_pages` never stops traversal. Consumer-defined endpoint
requests yield only their single page. For a single page, use `searchDocuments(matching:)`,
`presidentialDocuments(matching:)`, `value(for:)`, or `send(_:)`.

## Raw receipts

```swift
let receipt = try await client.response(for: DocumentRequest.document("93-32104"))
let pages = client.documentResponses(searching: query)
for try await receipt in pages {
  print(receipt.requestURL, receipt.status, receipt.body.count)
}
```

Each receipt contains the exact bytes decoded, HTTP fields, status, requested URL, and OFR/NARA and GPO
publisher attribution. No second fetch occurs. Duplicate headers remain separate. Supply `retrievalTime`
when a retrieval instant is required; its default is nil, not an invented timestamp. Redirects are refused,
so the receipt URL is unambiguous. The 8 MiB default limit bounds accepted decoding and retained receipts
after transport buffering; it is not a streaming network-memory cap. Large PDF, image, and metadata
downloads are outside this package.

## Failures and availability

Requests are sent once. There is no automatic retry, fallback, redirect, caching, or cross-provider lookup.
HTTP failures retain body, status, and headers including Retry-After through ``FederalRegisterError``.
Callers control retry/backoff and must honor provider limits. No numerical API quota has been verified.
Search results and agency data reflect the provider at request time; nothing here promises freshness, a
stable snapshot between pages, or a complete result set.

Text, HTML, and XML retrieval retains UTF-8 source markup. It does not render HTML, resolve XML external
entities, normalize dates, or extract legal meaning. Null representation links fail before sending. A
non-null link can still return 404, as the recorded 1994 HTML link did. PDF and MODS links are preserved
but not fetched by this package. A publication date is not the date of the action a document records, and
absence from the Federal Register does not prove absence of an action.

## Topics

### Execution
- ``FederalRegisterClient``
- ``FederalRegisterError``

### Lazy sequences
- ``DocumentPageSequence``
- ``DocumentSequence``
