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

Cursor links are verified from recorded responses. They remain opaque and retain source query parameters.
`total_pages` can be capped at 50 while `next_page_url` continues, so it never controls traversal.
An absent or null next link ends traversal. An advertised next link with no cursor, changed filters,
unsafe origin/path, or repeated cursor fails explicitly. These checks do not promise a stable snapshot.

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
- ``DocumentRequest``
- ``Endpoint``
- ``DocumentResponse``

### Receipts and failures
- ``SourceResponse``
- ``SourceHeader``
- ``DocumentContentError``
- ``DocumentPaginationError``
- ``DocumentValidationError``
