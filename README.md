# swift-federal-register

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Swift models and a typed client for the [Federal Register API](https://www.federalregister.gov/developers/documentation/api/v1).

`SwiftFederalRegisterDocumentsModels` describes each supported FederalRegister.gov request as a plain
value and decodes every response, so any networking stack can send them. `SwiftFederalRegisterDocuments`
sends them for you through [swifty-networking](https://github.com/KalebCooper/swifty-networking),
pages search results on demand, and maps failures into one typed error. Both run on Apple platforms,
Linux, and Android.

The full reference is the
[documentation site](https://kalebcooper.github.io/swift-federal-register/documentation/).

## Status

There is no tagged release yet, and the public API may change before one. Every change is recorded
in [CHANGELOG.md](CHANGELOG.md).

| Feature | Service routes | Client methods | Paged |
|---|---|---|---|
| Document detail | `/api/v1/documents/{number}.json` | `document(_:)` | No |
| Full text | a document's advertised HTML, text, and XML links | `content(_:for:)` | No |
| Document search | `/api/v1/documents.json` | `searchDocuments(matching:)`, `documents(searching:)` | Yes |
| Presidential documents | `/api/v1/documents.json`, presidential type | `presidentialDocuments(matching:)`, `documents(matching:)` | Yes |
| Agencies | `/api/v1/agencies.json`, `/api/v1/agencies/{slug}.json` | `agencies()`, `agency(_:)` | No |

Also built: regulatory metadata on each document (CFR references, Regulation Identifier Numbers,
dockets, document type, significance), raw response receipts that keep the exact bytes and
publisher attribution, and validated following of every next-page link the service returns.

What the package does not guarantee, because the service does not:

- **Completeness.** A search is not a stable snapshot. `total_pages` can be capped while the next
  link keeps going, and pages beyond the service's depth limit are not promised. A missing record
  does not prove that an action did not occur.
- **Format availability.** Older documents can have null PDF or XML links, and an advertised link can
  still return 404. No replacement link is guessed.
- **Normalization.** Dates stay as the strings the service sent, and a publication date is not the
  date of the action a document records. Conflicting dates are kept side by side.
- **Official status.** FederalRegister.gov is an informational rendition from OFR/NARA and GPO. GPO
  publishes the official edition.

## Usage

```swift
import SwiftFederalRegisterDocuments
import SwiftFederalRegisterDocumentsModels

let client = FederalRegisterClient(userAgent: "(MyApp, contact@example.com)")

let document = try await client.document("2024-31396")
print(document.title, document.publicationDate ?? "")
```

The API needs no key. The client requires a `User-Agent` naming your application and has no
default. On Apple platforms, `userAgent:` sends through the shared URL session; pass `session:` for
your own, or use `FederalRegisterClient(transport:userAgent:)` with any swifty-networking transport.

Every operation is available at three levels, and all three share one executor:

```swift
let everyday = try await client.document("2024-31396")               // the domain value
let reusable = try await client.value(for: .document("2024-31396"))  // a stored, inspectable request
let direct = try await client.send(.document("2024-31396"))          // one HTTP operation
```

### Searching documents

```swift
let query = try DocumentSearchQuery(
  agencies: [.environmentalProtectionAgency],
  publicationDate: .range(from: "2024-01-01", through: "2024-12-31"),
  term: "water",
  types: [.rule])

let firstPage = try await client.searchDocuments(matching: query)

for try await result in client.documents(searching: query) {
  print(result.documentNumber, result.title)
}
```

Filters cover agencies, CFR title and part, docket, effective and publication dates, Regulation
Identifier Number, full-text term, and document type. Results come newest or oldest first. Search
results carry only the service's default fields, so fetch a document's detail to read its full
regulatory metadata:

```swift
if let result = firstPage.results.first {
  let rule = try await client.document(result.documentNumber)
  print(rule.cfrReferences ?? [], rule.regulationIDNumbers ?? [], rule.docketIDs ?? [])
}
```

### Presidential documents

```swift
let query = try DocumentQuery(publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
for try await document in client.documents(matching: query) {
  print(document.documentNumber, document.signingDate ?? "", document.title)
}
```

`DocumentQuery` always searches presidential documents, optionally narrowed by president and
presidential document type.

### Paging

`documents(searching:)` and `documents(matching:)` yield one document at a time.
`documentPages(searching:)` and `documentPages(matching:)` yield whole pages.

```swift
for try await page in client.documentPages(searching: query) {
  print(page.count, page.results.count)
}
```

Sequences are lazy, never prefetch, and start over for each iterator. They keep the service's order
and duplicates. A next link from another origin, with changed filters, or one that does not move
forward throws `FederalRegisterError.pagination` before its page is fetched. Break out of the loop
when you have enough.

### Agencies

```swift
let catalog = try await client.agencies()
let epa = try await client.agency(.environmentalProtectionAgency)
print(catalog.agencies.count, epa.name ?? "", epa.childSlugs ?? [])
```

`AgencyIdentifier` is an open slug. Its static members are a convenience generated from one
recorded catalog; any other slug works through `AgencyIdentifier(rawValue:)`. Call `agencies()` for
the current list.

### Full text

```swift
let text = try await client.content(.text, for: document)
print(text.source)
```

HTML, text, and XML come back as the exact UTF-8 source, markup included. A representation the
document does not advertise fails with `FederalRegisterError.content` before anything is sent. PDF
and MODS links are available on the document but never downloaded.

### Raw responses

```swift
let receipt = try await client.response(for: DocumentRequest.document("2024-31396"))
print(receipt.status, receipt.requestURL, receipt.publisher, receipt.body.count)

for try await receipt in client.documentResponses(searching: query) {
  print(receipt.requestURL)
}
```

A receipt holds the decoded value alongside the exact bytes, status, and header fields it came
from, with no second request.

### Reusable requests

Creating a request performs no I/O. Name your own:

```swift
extension DocumentRequest where Response == DocumentPage {
  static func rules(from agency: AgencyIdentifier) throws -> Self {
    .searchDocuments(matching: try DocumentSearchQuery(agencies: [agency], types: [.rule]))
  }
}

let rules = try await client.value(for: .rules(from: .environmentalProtectionAgency))
```

`DocumentRequest(endpoint:)` wraps an `Endpoint` with a response model of your own, for a route this
package does not build.

### Other networking stacks

A consumer with its own networking stack needs only `SwiftFederalRegisterDocumentsModels`:

```swift
let endpoint = try Endpoint<FederalRegisterDocument>.document("2024-31396")
// GET https://www.federalregister.gov/api/v1/documents/2024-31396.json
// Accept: application/json
let document = try FederalRegisterDocument.decode(responseBody)
```

Send a GET to `https://www.federalregister.gov` plus `endpoint.path`, set `Accept` to
`endpoint.accept`, and decode with the response type. Validate a next link with
`DocumentPage.continuation(after:seenCursors:)` before following it.

### Errors

Every client method throws `FederalRegisterError`: input rejected before sending (`.validation`), an
unavailable representation (`.content`), an unusable next link (`.pagination`), a body over the size
limit (`.responseTooLarge`), a decoding failure, or a transport failure. HTTP errors keep their status,
body, and header fields, including `Retry-After`. Each request is sent once, with no automatic retry
or redirect; retries and backoff are yours.

## Example

[`Examples/SwiftFederalRegisterDocumentsDemo`](Examples/SwiftFederalRegisterDocumentsDemo) is an iOS
app that searches documents by agency, term, and type, shows a result's regulatory metadata, browses
the agency catalog, and loads a document's full text. It references this package by local path; open
`SwiftFederalRegisterDocumentsDemo.xcodeproj` with the package itself closed in Xcode, since Xcode
opens a local package in only one window.

[`Examples/OfflineDemo`](Examples/OfflineDemo) is a command-line tool that runs the same client
against recorded responses, with no network access. See its [README](Examples/OfflineDemo/README.md).

## Products

| Product | What it is | Depends on |
|---|---|---|
| `SwiftFederalRegisterDocumentsModels` | `Codable` documents, pages, and agencies, validated search queries, typed `Endpoint` and `DocumentRequest` values, and full-text decoding. Usable with any networking stack. | Nothing. |
| `SwiftFederalRegisterDocuments` | `FederalRegisterClient`, `FederalRegisterError`, and the lazy page, document, and receipt sequences. Re-exports swifty-networking's `HTTPCore`, so `Transport` and `TransportError` need no import of their own. | `SwiftFederalRegisterDocumentsModels`, swifty-networking, swift-http-types. |

A consumer with its own networking stack adds only `SwiftFederalRegisterDocumentsModels` and fetches
no dependency at all.

## Requirements

- Swift 6.2 or later.
- iOS, macOS, tvOS, visionOS, and watchOS 26 or later, Linux, or Android.
- `SwiftFederalRegisterDocuments` depends on
  [swifty-networking](https://github.com/KalebCooper/swifty-networking) 1.3.1 or later and
  [swift-http-types](https://github.com/apple/swift-http-types) 1.6.0 or later. On Apple platforms it
  sends through `URLSession`. On Linux and Android, enable the off-by-default `HTTPPortable` trait,
  which pulls in AsyncHTTPClient and SwiftNIO, and pass swifty-networking's
  `AsyncHTTPClientTransport` to `FederalRegisterClient(transport:userAgent:)`. A consumer who leaves
  the trait off never fetches or builds either.

## Installation

Until the first release is tagged, depend on `main`:

```swift
.package(url: "https://github.com/KalebCooper/swift-federal-register.git", branch: "main")
```

On Linux or Android, enable the trait on the dependency:

```swift
.package(
  url: "https://github.com/KalebCooper/swift-federal-register.git", branch: "main",
  traits: ["HTTPPortable"])
```

Then add `SwiftFederalRegisterDocuments`, or only `SwiftFederalRegisterDocumentsModels`, to your
target's dependencies. See [CONTRIBUTING.md](CONTRIBUTING.md) to build and test the package locally.

## License

MIT. See [LICENSE](LICENSE). This project is independent of the Office of the Federal Register. The
package license does not grant rights to Federal Register content; the recorded test responses carry
their own [source attribution](Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures/README.md).
