# swift-federal-register

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Portable Swift models and an SDK for Federal Register documents.

## Status

Implemented locally: document detail, presidential-document searches, lazy cursor page/item sequences,
raw response receipts, and lossless UTF-8 content from advertised HTML, text, and XML links. Models preserve
every JSON field, explicit null, unknown code, and conflicting date assertion. There is no published release.

Current and 1994 fixtures are verified. Historical PDF/XML links can be null, and an advertised HTML link
returned 404; no replacement format is inferred. Text responses can contain HTML wrappers. PDF/MODS links
are retained but not downloaded. Content decoding does not render HTML or parse XML into an element model.

FederalRegister.gov is an informational rendition from OFR/NARA and GPO; GPO publishes the official edition.
This package promises neither complete presidential history nor stable snapshots, freshness, or format
availability. Absence from the Federal Register does not prove absence of a presidential action.
See [verification and remaining gates](IMPLEMENTATION_READINESS.md).

## Usage

```swift
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels

let client = FederalRegisterClient(userAgent: "(MyApp, contact@example.com)")
let document = try await client.document("93-32104")
let request = try DocumentRequest.document("93-32104")
let same = try await client.value(for: request)
let direct = try await client.send(.document("93-32104"))

let query = try DocumentQuery(pageSize: 20, publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
for try await document in client.documents(matching: query) {
  print(document.documentNumber, document.title)
}
for try await receipt in client.documentResponses(matching: query) {
  print(receipt.requestURL, receipt.body.count)
}
```

Use `documentPages(matching:)` for page envelopes and `presidentialDocuments(matching:)` for one page.
Request-based sequence overloads accept `.presidentialDocuments(matching:)`; custom endpoint requests yield
one page only. Every iterator is independent, performs no construction I/O or prefetch, checks cancellation,
and terminates after a failure. Provider order and duplicates remain intact. Capped `total_pages` never
stops cursor traversal; unsafe, changed, missing, or repeated continuations throw typed errors.

The API needs no key. The SDK sends once, refuses redirects, and preserves HTTP failure bodies and headers,
including Retry-After. No numerical quota was verified. Callers own retry and backoff. Receipt timestamps
are optional and supplied through `retrievalTime`; the default does not invent an instant. The default
8 MiB decoding/receipt limit applies after transport buffering, not as a streaming memory limit.

## Example

The [offline consumer demo](Examples/OfflineDemo/README.md) runs against attributed recorded responses and
shows historical date evidence, null formats, source text, and two cursor pages. Run
`bash Scripts/linux-demo.sh` to build and execute it in the pinned Linux container.

The iOS example is `Examples/SwiftFederalRegisterDocumentsDemo/SwiftFederalRegisterDocumentsDemo.xcodeproj`.
It supports document lookup, source-content loading, and explicit next-page loading. Its Release simulator
build passes in hosted CI; Debug build and runtime verification remain pending.
Close the standalone package workspace before opening the demo.

## Products

| Product | Contents |
| --- | --- |
| `SwiftFederalRegisterDocuments` | Client, typed failures, lazy page/item/receipt sequences. |
| `SwiftFederalRegisterDocumentsModels` | Source values, content decoding, queries, requests, endpoints, receipts; no third-party dependencies. |

## Requirements

Swift tools 6.2, Swift 6 language mode, and iOS/macOS/tvOS/visionOS/watchOS 26 floors. Linux validation uses
Swift 6.3 in `swift:6.3-noble`, with both default traits and `HTTPPortable`. Hosted iOS 27 and Android
tests, the Release simulator demo build, and Apple-symbol DocC generation pass; iOS demo execution
remains unverified. Enable `HTTPPortable` and inject a portable transport for Linux or Android networking.
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
