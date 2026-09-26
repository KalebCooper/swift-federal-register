# swift-federal-register

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Portable Swift models and an SDK for Federal Register documents.

## Status

Implemented locally: document detail, presidential-document searches, general document search filtered by
agency, CFR location, docket, effective and publication date, Regulation Identifier Number, term, and type,
regulatory metadata projections, agency discovery, lazy cursor and page-number sequences, raw response
receipts, and lossless UTF-8 content from advertised HTML, text, and XML links. Models preserve every JSON
field, explicit null, unknown code, and conflicting date assertion. `agencies()` retrieves the complete
agency list and `agency(_:)` one agency's detail by slug, each in one request with no logo or link fetching.
`searchDocuments(matching:)` retrieves the first page of a general document search built from
`DocumentSearchQuery` filters; a zero-match search returns one empty page. `documents(searching:)`,
`documentPages(searching:)`, and `documentResponses(searching:)` traverse it lazily, following the provider's
validated cursor or page-number links with no prefetch. `FederalRegisterDocument` projects CFR references,
Regulation Identifier Numbers, docket identifiers, the `significant` flag, and `DocumentType` from `fields`;
search results carry only the provider's default projection, so most of these stay nil there by design.
There is no published release.

Current and 1994 fixtures are verified. Historical PDF/XML links can be null, and an advertised HTML link
returned 404; no replacement format is inferred. Text responses can contain HTML wrappers. PDF/MODS links
are retained but not downloaded. Content decoding does not render HTML or parse XML into an element model.

FederalRegister.gov is an informational rendition from OFR/NARA and GPO; GPO publishes the official edition.
This package promises neither complete presidential history nor stable snapshots, freshness, or format
availability. General search offers newest and oldest chronological order only; relevance order is not a
query option, and a consumer-built relevance `Endpoint` yields a single page, continued only by validating
its next link directly with `DocumentPage.continuation(after:seenCursors:)`. Repeated `agencies` and `types`
filters are sent with their multiplicity; the provider does not document an AND, OR, or parent-agency
combination rule for them. `total_pages` can be capped while a next link keeps continuing, so it never stops
traversal, and pages beyond the provider's depth cap are not guaranteed. Absence from the Federal Register
does not prove absence of a presidential action. See
[verification and remaining gates](IMPLEMENTATION_READINESS.md).

## Usage

```swift
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels

let client = FederalRegisterClient(userAgent: "(MyApp, contact@example.com)")

// Explicit document detail, at three equivalent levels.
let document = try await client.document("93-32104")
let request = try DocumentRequest.document("93-32104")
let same = try await client.value(for: request)
let direct = try await client.send(.document("93-32104"))

// General document search, then its typed regulatory metadata.
let search = try DocumentSearchQuery(
  agencies: [.environmentalProtectionAgency],
  publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
  types: [.rule])
let page = try await client.searchDocuments(matching: search)
for try await result in client.documents(searching: search) {
  print(result.documentNumber, result.cfrReferences ?? [])
}

// Agency discovery.
let agencyList = try await client.agencies()
let epa = try await client.agency(.environmentalProtectionAgency)
print(agencyList.agencies.count, epa.name ?? "")

let query = try DocumentQuery(pageSize: 20, publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
for try await presidentialDocument in client.documents(matching: query) {
  print(presidentialDocument.documentNumber, presidentialDocument.title)
}
for try await receipt in client.documentResponses(matching: query) {
  print(receipt.requestURL, receipt.body.count)
}
```

Use `documentPages(matching:)` and `documentPages(searching:)` for page envelopes, and
`presidentialDocuments(matching:)` and `searchDocuments(matching:)` for one page. Request-based sequence
overloads accept `.presidentialDocuments(matching:)` and `.searchDocuments(matching:)`; custom endpoint
requests yield one page only. Every iterator is independent, performs no construction I/O or prefetch,
checks cancellation, and terminates after a failure. Provider order and duplicates remain intact. Capped
`total_pages` never stops a cursor or page-number traversal; unsafe, changed, missing, repeated, or
nonprogressing continuations throw typed errors.

The API needs no key. The SDK sends once, refuses redirects, and preserves HTTP failure bodies and headers,
including Retry-After. No numerical quota was verified. Callers own retry and backoff. Receipt timestamps
are optional and supplied through `retrievalTime`; the default does not invent an instant. The default
8 MiB decoding/receipt limit applies after transport buffering, not as a streaming memory limit.

## Example

The [offline consumer demo](Examples/OfflineDemo/README.md) runs against attributed recorded responses and
shows agency discovery, a two-page general search, typed regulatory metadata, historical date evidence,
null formats, source text, and two presidential cursor pages. Run
`bash Scripts/linux-demo.sh` to build and execute it in the pinned Linux container.

The iOS example is `Examples/SwiftFederalRegisterDocumentsDemo/SwiftFederalRegisterDocumentsDemo.xcodeproj`.
It supports general search by agency, term, and document type with explicit next-page loading and a
cancel control, typed regulatory metadata for a selected result, agency lookup by slug, the agency
catalog, document lookup, source-content loading, and presidential next-page loading. Its Debug and
Release simulator builds pass locally, and search, next-page loading, regulatory metadata, agency lookup,
an invalid-slug error, the catalog, and presidential detail were checked on an iOS 27 simulator.
Cancelling an in-flight page has not been observed at runtime and remains unverified.
Close the standalone package workspace before opening the demo.

## Products

| Product | Contents |
| --- | --- |
| `SwiftFederalRegisterDocuments` | Client, typed failures, lazy page/item/receipt sequences. |
| `SwiftFederalRegisterDocumentsModels` | Source values, content decoding, queries, requests, endpoints, receipts; no third-party dependencies. |

## Requirements

Swift tools 6.2, Swift 6 language mode, and iOS/macOS/tvOS/visionOS/watchOS 26 floors. Linux validation uses
Swift 6.3 in `swift:6.3-noble`, with both default traits and `HTTPPortable`. Hosted iOS 27 and Android
tests last passed at `22371b9`, before general search and agency discovery; this candidate has local
qualification only (see IMPLEMENTATION_READINESS.md). Cancelling an in-flight demo page is unverified.
Enable `HTTPPortable` and inject a portable transport for Linux or Android networking.
The default Apple convenience uses URLSession; default-trait Linux consumers supply their own transport.

## Installation

Use a local path dependency until a public repository and release are published:

```swift
.package(path: "../swift-federal-register")
```

Choose either product independently. SDK dependencies use the verified public swifty-networking `1.3.1`
minimum and swift-http-types. `Package.resolved` records the HTTPPortable-enabled dependency superset.

## License

MIT. See [LICENSE](LICENSE). The package license does not grant rights to upstream content. Recorded
responses carry separate [source attribution and receipts](Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures/README.md).
