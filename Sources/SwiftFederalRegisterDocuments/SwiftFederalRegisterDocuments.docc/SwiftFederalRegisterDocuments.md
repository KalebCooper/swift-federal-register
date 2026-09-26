# ``SwiftFederalRegisterDocuments``

Retrieve Federal Register documents, their full text, agencies, and search results through a typed
client.

## Overview

``FederalRegisterClient`` sends the requests that `SwiftFederalRegisterDocumentsModels` describes. It
pages search results on demand, validates every next link before following it, and maps each failure
into one typed ``FederalRegisterError``.

```swift
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels

let client = FederalRegisterClient(userAgent: "(MyApp, contact@example.com)")
let document = try await client.document("2024-31396")
print(document.title, document.publicationDate ?? "")
```

The API needs no key. The client requires a User-Agent naming your application and has no default.
On Apple platforms, the short initializer sends through a URL session. On Linux and Android, enable
the `HTTPPortable` trait and pass a swifty-networking portable transport to
``FederalRegisterClient/init(maximumResponseBytes:retrievalTime:transport:userAgent:)``.

Every operation is available at three levels that share one executor: an everyday method such as
``FederalRegisterClient/document(_:)``, a reusable `DocumentRequest` executed by
``FederalRegisterClient/value(for:)``, and the individual `Endpoint` values sent by
``FederalRegisterClient/send(_:)``.

```swift
let everyday = try await client.document("2024-31396")
let reusable = try await client.value(for: .document("2024-31396"))
let direct = try await client.send(.document("2024-31396"))
```

### Searching documents

A `DocumentSearchQuery` filters every document type by agency, CFR location, docket, effective and
publication date, Regulation Identifier Number, full-text term, and type.

```swift
let query = try DocumentSearchQuery(
  agencies: [.environmentalProtectionAgency],
  publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
  types: [.rule])

let firstPage = try await client.searchDocuments(matching: query)
for try await result in client.documents(searching: query) {
  print(result.documentNumber, result.title)
}
```

``FederalRegisterClient/searchDocuments(matching:)`` retrieves one page; a zero-match search returns
an empty page. Search results carry only the service's default fields, so regulatory metadata such as
CFR references is usually nil on them. A result never triggers a detail fetch; call
``FederalRegisterClient/document(_:)`` when you need the full record.

Results are newest or oldest first. Relevance order is not a query option: a consumer-defined
relevance `Endpoint` yields its first page only, and `DocumentPage.continuation(after:seenCursors:)`
validates its next link if you want to go further.

### Presidential documents

A `DocumentQuery` always searches presidential documents, optionally narrowed by president and
presidential document type.

```swift
let presidential = try DocumentQuery(
  publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
for try await document in client.documents(matching: presidential) {
  print(document.documentNumber, document.title)
}
```

### Paging

The `searching:` and `matching:` sequences yield documents, pages, or raw receipts:
``FederalRegisterClient/documents(searching:)``, ``FederalRegisterClient/documentPages(searching:)``,
and ``FederalRegisterClient/documentResponses(searching:)``, with the same three for presidential
queries. ``FederalRegisterClient/documentPages(for:)`` and its siblings accept a reusable request.

Creating a sequence or an iterator sends nothing. Each iterator starts its own traversal, fetches one
page only when needed, and never prefetches. Items keep the service's order and duplicates.
Cancellation is checked before each request and while draining buffered items, and breaking out of a
loop sends no further requests. Any failure ends the iterator.

Library-created searches follow the service's validated next links, which continue by an opaque
cursor or, for term searches, by a strictly increasing page number. An unsafe, changed, repeated, or
nonprogressing link throws ``FederalRegisterError/pagination(_:)``. `total_pages` can be capped while
the next link keeps going, so it never stops traversal, and pages beyond the service's depth limit
are not promised. A request built from a custom endpoint yields its first page only.

### Agencies

```swift
let catalog = try await client.agencies()
let epa = try await client.agency(.environmentalProtectionAgency)
print(catalog.agencies.count, epa.name ?? "", epa.childSlugs ?? [])
```

``FederalRegisterClient/agencies()`` retrieves the complete agency list, historical agencies included,
in one request. ``FederalRegisterClient/agency(_:)`` validates the slug before sending and sends any
well-formed slug; an unknown one returns the service's HTTP failure. The generated `AgencyIdentifier`
members come from one recorded catalog and are not the set of agencies that exist. Logos, links,
parents, and children are never fetched automatically.

### Full text

```swift
let text = try await client.content(.text, for: document)
print(text.source)
```

``FederalRegisterClient/content(_:for:)`` returns the exact UTF-8 source, markup included. It does
not render HTML or parse XML. A representation the document does not advertise fails before sending,
and an advertised link can still return 404. PDF and MODS links are kept on the document but never
downloaded.

### Raw receipts

```swift
let receipt = try await client.response(for: DocumentRequest.document("2024-31396"))
print(receipt.status, receipt.requestURL, receipt.publisher, receipt.body.count)
```

A receipt holds the decoded value with the exact bytes, status, header fields, request URL, and
OFR/NARA and GPO attribution, with no second request. Supply `retrievalTime` when you need a
retrieval instant; by default it is nil. The 8 MiB default limit applies to the buffered body after
transport, not as a streaming memory cap.

### What the client does not do

Each request is sent once. There is no automatic retry, redirect, caching, or fallback. HTTP failures
keep their status, body, and header fields, including `Retry-After`, so you control retry and
backoff.

The client keeps what the service sends. It does not normalize dates, reconcile conflicting ones, or
promise freshness, a stable snapshot between pages, or a complete result set. A publication date is
not the date of the action a document records, and absence from the Federal Register does not prove
absence of an action. FederalRegister.gov is an informational rendition; GPO publishes the official
edition.

## Topics

### Essentials

- ``FederalRegisterClient``
- ``FederalRegisterError``

### Lazy sequences

- ``DocumentPageSequence``
- ``DocumentSequence``
