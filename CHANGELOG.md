# Changelog

All notable changes are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- `SwiftFederalRegisterDocumentsModels`, portable `Codable` models, validated queries, and typed
  `Endpoint` and `DocumentRequest` values with no third-party dependency, and
  `SwiftFederalRegisterDocuments`, a `FederalRegisterClient` that sends them through
  swifty-networking 1.3.1 or later. Every operation is available as an everyday client method, a
  reusable request, and an endpoint, all sharing one executor and one typed `FederalRegisterError`.
- Document detail through `document(_:)`. `FederalRegisterDocument` keeps every source field,
  explicit null, and conflicting date assertion in `fields`, with typed projections alongside.
- Full text through `content(_:for:)`: a document's advertised HTML, text, or XML as lossless UTF-8,
  markup included. A missing link fails before sending, and no replacement link is guessed. PDF and
  MODS links are kept but never downloaded.
- General document search through `searchDocuments(matching:)` with `DocumentSearchQuery`, filtered
  by agency, CFR title and part, docket, effective and publication date (`DocumentDateFilter`),
  Regulation Identifier Number, full-text term, and document type, newest or oldest first. A
  zero-match search returns one empty page.
- Presidential document search through `presidentialDocuments(matching:)` with `DocumentQuery`.
- Lazy sequences for both searches: `documents`, `documentPages`, and `documentResponses`, with
  `searching:` and `matching:` labels. They follow the service's cursor and page-number links with no
  prefetch, check cancellation before each request, and throw `FederalRegisterError.pagination` for
  an unsafe, changed, repeated, or nonprogressing next link.
- Regulatory metadata on `FederalRegisterDocument`: `action`, `agencies`, `cfrReferences`,
  `commentURL`, `commentsCloseOn`, `docketID`, `docketIDs`, `documentType`,
  `regulationIDNumberInfo`, `regulationIDNumbers`, `regulationsDotGovURL`, and `significant`, with
  the `CFRReference`, `DocumentAgency`, `DocumentType`, `DocumentTypeCode`, and
  `RegulationIDNumberInfo` models. A projection of an unexpected JSON kind is nil rather than a
  decoding failure.
- Agency discovery through `agencies()` and `agency(_:)`, returning `AgencyList` and
  `FederalRegisterAgency`. `AgencyIdentifier` is an open slug with static members generated from the
  473 slugs in a recorded catalog.
- Raw response receipts through `response(for:)` and `documentResponses`: the decoded value with its
  exact bytes, status, header fields, request URL, and publisher attribution, without a second
  request.
- An iOS demo app and an offline command-line demo that runs against recorded responses.
- Linux and Android support through the `HTTPPortable` trait.
