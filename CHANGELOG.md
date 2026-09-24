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
- Source verification, pinned Linux test/demo/documentation scripts, and pending Apple/Android CI lanes.
