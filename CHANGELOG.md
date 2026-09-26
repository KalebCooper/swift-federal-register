# Changelog

All notable changes will be documented here, following Keep a Changelog and Semantic Versioning.

## Unreleased

### Added

- Portable `SwiftFederalRegisterDocumentsModels` and `SwiftFederalRegisterDocuments` products.
- Document detail and presidential-document queries through everyday methods, constrained typed requests,
  and independently executable endpoints.
- Lazy cursor page, item, and response-receipt sequences with independent iterators, cancellation,
  origin/filter validation, repeated-cursor failures, and no prefetch.
- Full source JSON fields, explicit nulls, unmodified date assertions, publisher attribution, and exact
  response-byte receipts without a second request.
- UTF-8 source-content decoding for advertised HTML, text, and XML links, preserving markup and historical
  text wrappers. Missing formats remain unavailable; PDF and MODS links are retained without downloads.
- Attributed current and 1994 fixtures, deterministic Swift Testing coverage, two DocC catalogs, and
  recorded-data and iOS examples.
- Verified swifty-networking 1.3.1 dependency floor and HTTPPortable trait forwarding.
- `AgencyIdentifier`, an open agency slug value with a generated catalog of the 473 slugs in the
  recorded `/api/v1/agencies.json` snapshot; unknown slugs remain representable.
- `FederalRegisterAgency`, `AgencyList`, `AgencyLogo`, and `DocumentAgency` models that retain every
  source field and explicit null. Typed projections are optional and become nil, never a decoding
  failure, when a field is missing or has an unexpected JSON kind.
- Agency catalog and detail endpoints and requests, `Endpoint<AgencyList>.agencies()`,
  `Endpoint<FederalRegisterAgency>.agency(_:)`, and their `DocumentRequest` factories. Custom endpoint
  paths may name `/api/v1/agencies.json` or one detail segment under `/api/v1/agencies/`; document
  continuations still refuse agency links. `DocumentValidationError.invalidAgencyIdentifier` rejects a
  slug outside ASCII letters, digits, and hyphens before any path forms.
- `FederalRegisterClient.agencies()` and `agency(_:)`, equivalent to `value(for:)` with the agency
  requests and `send(_:)` with the agency endpoints. Each sends one request with no page sequence and
  no logo or link fetching; a malformed slug fails as `FederalRegisterError.validation` before sending.
- Regulatory metadata projections on `FederalRegisterDocument`: `action`, `agencies`, `cfrReferences`,
  `commentURL`, `commentsCloseOn`, `docketID`, `docketIDs`, `documentType`, `regulationIDNumberInfo`,
  `regulationIDNumbers`, `regulationsDotGovURL`, and `significant`, with the `CFRReference`,
  `DocumentType`, `DocumentTypeCode`, and `RegulationIDNumberInfo` models. Dates stay source strings,
  `type` is unchanged, and an unexpected JSON kind makes a projection nil while `fields` keeps the value.
- `DocumentSearchQuery`, `DocumentDateFilter`, and `CFRFilter`, validated general search filters for
  agencies, CFR title and part, docket identifier, effective and publication dates as an exact day,
  inclusive range, or year, Regulation Identifier Number, full-text term, and document types, with no
  implicit type condition. Filter strings are kept exactly as given; repeated agencies and types are
  sent with their multiplicity. `DocumentValidationError` gains `emptyFilterValue`, `invalidAgencyIdentifier`,
  `invalidCFRFilter`, `invalidDateRange`, and `invalidYear`; exhaustive switches over it need those arms.
- `Endpoint<DocumentPage>.searchDocuments(matching:)` and `DocumentRequest.searchDocuments(matching:)`
  for general searches. Query values are percent-encoded outside the RFC 3986 unreserved characters, so
  a term containing `+`, `&`, `=`, or `%` reaches the provider as given. The request resolves to the new
  `DocumentRequest.Resolution.documentSearch` case; exhaustive switches over `Resolution` need that arm.
  Page continuations compare queries as the provider parses them, reading `+` as a space, so a published
  `clean+water` matches a sent `clean%20water`.
- Page-number continuation. Term searches publish next links with a page number and no cursor, so
  `DocumentPage.continuation(after:seenCursors:)` also accepts a validated link whose single integer
  `page` exceeds the current endpoint's page with every other query item unchanged; only an absent
  current `page` means 1, and a present current `page` must be a single integer. Its returned `cursor`
  is now `String?`, nil for a page-number link. A same-or-lower page, or a current `page` that is
  repeated or not an integer, fails with the new `DocumentPaginationError.nonprogressingPage`, and a
  link with neither a cursor nor a page fails with `missingCursor`. Every library-created sequence,
  presidential included, shares this rule. No page is computed locally, and pages beyond the
  provider's depth cap are not guaranteed.
- Zero-match search pages decode: `DocumentPage.totalPages` is optional, nil when the provider omits
  `total_pages`, and an absent `results` beside a zero `count` is an empty page. Absent results with a
  nonzero count, or a null `results`, remain a decoding error.
- `FederalRegisterClient.searchDocuments(matching:)`, `documents(searching:)`, `documentPages(searching:)`,
  and `documentResponses(searching:)` for general searches, equivalent to `value(for:)` and the sequence
  executors with `DocumentRequest.searchDocuments(matching:)` and to `send(_:)` with
  `Endpoint<DocumentPage>.searchDocuments(matching:)`. The `searching:` label keeps `matching:` inferring the
  presidential `DocumentQuery`. Sequences follow cursor and page-number links lazily, a zero-match search is
  one empty page, and search results are never completed by a detail fetch.
- Source verification, pinned Linux test/demo/documentation scripts, and pending Apple/Android CI lanes.

### Changed

- Enabled Android, Apple, Linux, lint, source verification, and DocC builds in GitHub Actions.
- Enabled GitHub Pages documentation deployment on main pushes and manual workflow runs.
- Updated DocC builds to use the generated package scheme.

### Fixed

- Removed force unwraps from custom request test factories rejected by the CI formatter.
