# ``SwiftFederalRegisterDocuments``

Retrieve Federal Register documents, source representations, and lazy presidential-document search pages.

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

## Lazy traversal

```swift
let query = try DocumentQuery(pageSize: 20, publishedFrom: "1994-01-01", publishedThrough: "1994-12-31")
for try await document in client.documents(matching: query) {
  print(document.documentNumber, document.title)
}
for try await page in client.documentPages(matching: query) {
  print(page.count, page.results.count)
}
```

Construction and iterator creation send nothing. Each iterator starts independently; one page is fetched
only when needed, with no prefetch. Items preserve source order and duplicates. Cancellation is checked
before requests and while draining buffered items. Early break sends no further requests. Any failure
terminates the iterator, and later reads return nil. Previous results are not a complete result set.

`documentPages(for:)` and `documents(for:)` accept reusable requests. Library presidential requests follow
validated source cursor links. Consumer-defined endpoint requests yield only their single page. For a
single page, use `presidentialDocuments(matching:)`, `value(for:)`, or `send(_:)`.

## Raw receipts

```swift
let receipt = try await client.response(for: DocumentRequest.document("93-32104"))
let pages = client.documentResponses(matching: query)
for try await receipt in pages {
  print(receipt.requestURL, receipt.status, receipt.body.count)
}
```

Each receipt contains the exact bytes decoded, HTTP fields, status, requested URL, and publisher attribution.
No second fetch occurs. Duplicate headers remain separate. Supply `retrievalTime` when a retrieval instant
is required; its default is nil, not an invented timestamp. Redirects are refused, so the receipt URL is
unambiguous. The 8 MiB default limit bounds accepted decoding and retained receipts after transport buffering;
it is not a streaming network-memory cap. Large PDF, image, and metadata downloads are outside this slice.

## Failures and availability

Requests are sent once. There is no automatic retry, fallback, redirect, caching, or cross-provider lookup.
HTTP failures retain body, status, and headers including Retry-After through ``FederalRegisterError``.
Callers control retry/backoff and must honor provider limits. No numerical API quota has been verified.

Text, HTML, and XML retrieval retains UTF-8 source markup. It does not render HTML, resolve XML external
entities, normalize dates, or extract legal meaning. Null representation links fail before sending. A
non-null link can still return 404, as the recorded 1994 HTML link did. PDF and MODS links are preserved
but not fetched by this package. Absence from the Federal Register does not prove absence of an action.

## Topics

### Execution
- ``FederalRegisterClient``
- ``FederalRegisterError``

### Lazy sequences
- ``DocumentPageSequence``
- ``DocumentSequence``
