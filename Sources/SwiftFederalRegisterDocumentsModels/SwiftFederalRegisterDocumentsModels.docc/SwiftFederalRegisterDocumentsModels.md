# ``SwiftFederalRegisterDocumentsModels``

Describe Federal Register document operations and preserve their source evidence without a networking dependency.

## Overview

Use ``FederalRegisterDocument`` for detail responses and list entries, ``DocumentPage`` for search envelopes,
and ``DocumentQuery`` for presidential-document filters. All JSON attributes remain in `fields`, including
unknown attributes and explicit nulls. Dates remain strings: a signing date is not a publication date, and
a conflicting descriptive date is never reconciled automatically.

```swift
let request = try DocumentRequest.document("93-32104")
let endpoint = request.endpoint
let document = try FederalRegisterDocument.decode(downloadedBytes)
```

Create custom responses by conforming a `Decodable` type to ``DocumentResponse``. Its default decoder reads
JSON; custom conformances can supply a source-specific decoder. ``DocumentContent`` reads UTF-8 source
without stripping HTML or interpreting XML. In the recorded 1994 sample, the text endpoint returns an
HTML `pre` wrapper even though its Content-Type is text/plain. Original bytes remain available in SDK receipts.

## Source contracts

The [official API contract](https://www.federalregister.gov/api/v1/documentation) describes search since
1994 and page sizes of 1 through 1000, defaulting to 20. Queries impose no product-era cutoff. Actual
source holdings determine availability. Newest and oldest chronological order are supported here.

Next links are verified from recorded responses. Cursors remain opaque, and every link retains its
source query parameters. `total_pages` can be capped at 50 while `next_page_url` continues, so it never
controls traversal, and pages beyond the provider's depth cap are not guaranteed. An absent or null next
link ends traversal, as does a zero-match page. A next link continues by a cursor or, as recorded term
searches publish, by a strictly increasing page number; a link with neither, changed filters, an unsafe
origin/path, a repeated cursor, or a nonprogressing page fails explicitly. These checks do not promise a
stable snapshot.

OFR/NARA and GPO publish the source. FederalRegister.gov's renditions are informational; GPO publishes
the official edition. An advertised format link can fail: the recorded 1994 HTML link returned 404,
while its PDF and XML fields were null. No replacement URLs are synthesized.

## Topics

### Source values
- ``FederalRegisterDocument``
- ``DocumentPage``
- ``JSONValue``
- ``DocumentContent``
- ``DocumentRepresentation``
- ``CFRReference``
- ``DocumentType``
- ``DocumentTypeCode``
- ``RegulationIDNumberInfo``

### Operations
- ``DocumentQuery``
- ``DocumentSearchQuery``
- ``DocumentDateFilter``
- ``CFRFilter``
- ``DocumentRequest``
- ``Endpoint``
- ``DocumentResponse``

### Receipts and failures
- ``SourceResponse``
- ``SourceHeader``
- ``DocumentContentError``
- ``DocumentPaginationError``
- ``DocumentValidationError``
