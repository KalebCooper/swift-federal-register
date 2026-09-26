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
- Source verification, pinned Linux test/demo/documentation scripts, and pending Apple/Android CI lanes.

### Changed

- Enabled Android, Apple, Linux, lint, source verification, and DocC builds in GitHub Actions.
- Enabled GitHub Pages documentation deployment on main pushes and manual workflow runs.
- Updated DocC builds to use the generated package scheme.

### Fixed

- Removed force unwraps from custom request test factories rejected by the CI formatter.
