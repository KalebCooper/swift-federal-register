# Federal Register response fixtures

These original responses were retrieved from official FederalRegister.gov routes on September 24,
2026 UTC using `(swift-federal-register, https://github.com/KalebCooper/swift-federal-register)`.
`receipts.json` records each exact URL/query, UTC retrieval instant, HTTP status, media type, byte count,
SHA-256 digest, and publisher attribution. Filenames retain their source representation; content is not
reformatted. Document identities are `2026-19417` and `93-32104`; list identities remain in each result.

Publisher: Office of the Federal Register, National Archives and Records Administration, in partnership
with the Government Publishing Office. These government document fixtures are separate from the package's
MIT-licensed implementation. FederalRegister.gov provides informational renditions; official editions
are published by GPO. See the [API documentation](https://www.federalregister.gov/developers/documentation/api/v1)
and [legal status](https://www.federalregister.gov/reader-aids/using-federalregister-gov/legal-status).

Current detail, two presidential pages, the terminal January 3, 1994 page, current HTML/XML/text,
and historical text returned 200. Historical text contains an HTML pre wrapper despite text/plain.
`historical-content.html` is the original 404 response, not a successfully retrieved historical document.
Historical PDF/XML links are null, so neither format was requested or inferred.

The live malformed `search_after_cursor=invalid` probe returned HTTP 400. Deterministic negative tests
mutate recorded envelopes or use literal HTTP failures; they do not claim these mutations are official
responses. Unit tests never call the live API.
