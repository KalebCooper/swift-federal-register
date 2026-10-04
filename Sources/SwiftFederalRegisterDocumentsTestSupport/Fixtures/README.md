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

The agency catalog, both agency detail records, regulatory and RIN document detail, and the search
variants (newest, oldest, fields-selected, and their two-page continuations; relevance, one page; and
the zero-match `search-terminal.json`) were retrieved from official FederalRegister.gov routes on
September 26, 2026 UTC using the same User-Agent.
`receipts.json` records each exact URL/query, retrieval instant, HTTP status, media type, byte count,
SHA-256 digest, and publisher attribution for these captures as well. Each two-page pair's second
capture used the first page's own `next_page_url`, including its `fields[]` selection where present.

The `search_after_cursor=invalid` probe (September 24, 2026 UTC) returned HTTP 400 and is shipped as
`invalid-cursor.json`. Its receipt's status, byte count, media type, and SHA-256 are evidenced from
that capture; the full request query line was never logged, so the receipt and the `Fixture` doc
comment state only the evidenced `search_after_cursor=invalid` fragment rather than an invented
complete query.

The two-word term search `search-spaced-term-page-one.json` (`conditions[term]=clean%20water`, newest,
two per page) was retrieved from the official documents route on September 26, 2026 UTC with the same
User-Agent. Its `next_page_url` is kept as published: the provider writes the space as `+` in the
query and gives a `page` number with no `search_after_cursor`.

The expanded API captures were retrieved September 28–29, 2026 UTC from the exact official URLs
in `receipts.json`. They cover selected fields, batches, combined filters, facets, issue hierarchies,
public-inspection listings/details/search continuations, and suggested-search metadata. All 75 HTTP
fixture bodies retain their original bytes, status, retrieval timestamp, and digest.

`expanded-vocabulary.json` is a derived extraction of documented names from the retained official
API schema. Its metadata records that schema's URL, capture time, and SHA-256. It is not an HTTP
response fixture and is deliberately excluded from the 75 response receipts. Tests compare public
shorthands with these recorded names; unknown values remain supported independently.
