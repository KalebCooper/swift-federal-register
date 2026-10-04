# Implementation readiness

The expanded API is implemented and locally qualified at source candidate
`811c7b4b5ec5796cab2dd752e2a7a789dc2323d7` on October 4, 2026. This record supersedes the
September 26 local record at `2432354`. Documentation-only follow-up commits do not change the
tested source. The package is unreleased. Android and hosted checks have not run on this candidate;
live inspection paging and in-flight demo cancellation remain unverified.

## Implemented surface

Both products retain their existing roles: portable models and request values have no third-party
dependency; the SDK executes them through swifty-networking with one typed failure model.

- Published detail, selected fields, batches, presidential and general searches, textual representations,
  agency discovery, and regulatory metadata.
- Open published/inspection field names, topic and section identifiers, presidential subtype codes,
  significance, geographic conditions, and executive-order-number ordering.
- Condition-only facet counts for all ten documented groupings and daily issue contents with explicit
  document-number references.
- Separate public-inspection current/dated listings, detail, batches, search, and lazy page/item/receipt
  traversal over verified increasing page-number links.
- Suggested-search catalog/detail metadata, retaining raw conditions without converting or executing them.
- Everyday methods, constrained request factories, independent endpoints, original response receipts,
  models-only consumer factories, and custom response types for the expanded routes.

Nonempty built-in field selections include `document_number` and `title`; an empty selection preserves
provider defaults. Batch results retain source order, partial errors, and singleton detail shapes with
no chunking, deduplication, input-order reconstruction, or retry. Inspection listings are one-shot;
search is separate. Custom endpoint sequences remain single-page.

Raw unknown fields, nulls, markup, duplicates, and date strings remain intact. Filing, intended
publication, PDF update, and listing update timestamps are separate facts. No implied publication,
stable snapshot, complete history, hidden document hydration, PDF download, or cross-provider identity
resolution is promised. Response limits apply after transport buffering. Receipts use only an optional
caller-supplied retrieval time. The client refuses redirects and performs no automatic retry.

The typed presidential query subtype replaces a String input. New enum cases affect exhaustive
switches; new defaulted query arguments can affect stored initializer references. Migration examples
and exact compatibility notes are in the README and changelog. Existing no-fields detail overloads
remain available.

## Source and provider evidence

Swift tools 6.2, language mode 6, platform 26 floors, `defaultIsolation(nil)`,
`NonisolatedNonsendingByDefault`, and strict memory safety remain unchanged. The public networking
minimum is still 1.3.1. Its previously verified peeled tag commit is
`04bbf231eabb95b90a5be786034e07cf351ee1d5`. No dependency or manifest change was made.
The tracked lockfile remains the original HTTPPortable-enabled superset.

The September 24–29 official captures now supply 75 byte-exact HTTP fixtures, each with the evidenced
URL/query, UTC retrieval instant, status, media type, byte count, SHA-256, and OFR/NARA/GPO attribution.
All 75 hashes and lengths matched on October 4. The malformed-cursor receipt retains only the query
fragment actually recorded. A separately labeled derived vocabulary fixture retains the official
schema URL, capture time, and digest; it is not represented as an HTTP response.

Vocabulary tests cover all 56 published fields, 27 inspection fields, six sections, and seven
presidential types in the retained schema. The agency generator still matches all 473 catalog slugs.
Unknown values remain open. Negative fixtures and changed envelopes are labeled synthetic.

The [official schema](https://www.federalregister.gov/api/v1/documentation) and
[developer guide](https://www.federalregister.gov/developers/documentation/api/v1) describe the provider
contract. No API key is required; a numerical quota remains unverified. The guide's first-2000-results
statement and observed cursor links beyond capped page totals are distinct evidence, not a completeness
promise. Historical `93-32104` retains null PDF/XML links, advertised HTML HTTP 404, HTML markup in its
text response, and conflicting December 18/19, 1993 date assertions.

## Local qualification

Source checks and tests ran on the exact source subsequently committed as `811c7b4`; documentation
and demo builds then ran on that commit. No source changed between those runs and the commit.
Apple counts include parameterized cases; Linux reports test declarations.

| Gate | Command or tool | Result |
| --- | --- | --- |
| Source | `bash Scripts/verify.sh` | Exit 0, all 16 checks, including strict format and catalog drift. |
| Checker | `bash Scripts/verify.sh --self-test` | Exit 0, 49 planted-violation arms; missing-subject protection retained. |
| Format | `swift format lint --strict --recursive Sources Tests Examples` | Exit 0, zero findings. |
| Agency generator | Generator with recorded input/output and `--check`; `python3 Scripts/test-generate-agency-identifiers.py` | 473 identifiers match; 10 tests pass. |
| Fixture integrity | SHA-256 and byte counts against all response receipts | 75 match, zero mismatches. |
| macOS tests | Xcode 27 MCP `RunAllTests`, generated package scheme, My Mac | 381 passed, 0 failed/skipped/not-run. |
| iOS tests | Xcode 27 MCP `RunAllTests`, generated package scheme, iPhone 18 Pro / iOS 27.0 | 381 passed, 0 failed/skipped/not-run. Result bundle independently confirms iOS Simulator destination. |
| Linux HTTPPortable | `bash Scripts/linux-test.sh`, `swift:6.3-noble` | Exit 0; 160 tests / 21 suites, 3.329 s. |
| Linux default | Same script, separate default-trait build | Exit 0; 160 tests / 21 suites, 2.753 s. |
| DocC, Linux symbols | `bash Scripts/linux-docs.sh` | Exit 0; models then SDK, merged archive, zero warnings under warnings-as-errors. |
| DocC, Apple symbols | `bash Scripts/build-docs.sh` against the fresh simulator modules | Exit 0; models then SDK, merged archive/static site, zero warnings under warnings-as-errors. |
| Offline demo | `bash Scripts/linux-demo.sh` | Exit 0; 5 agency/search, 11 expanded, and 4 presidential requests; no hidden hydration or prefetch. |
| iOS demo Debug | Xcode MCP `BuildProject`, iPhone 18 Pro | Passed, zero warnings. |
| iOS demo Release | Xcode MCP `BuildProject`, same destination | Passed, zero warnings (25.806 s). |
| Android | Local availability check | No installed `adb` or Swift Android SDK; emulator execution unavailable here. |

The successful simulator test build emitted two generated test-target linker warnings:
`Using sysroot for 'macOS 27.0' but targeting 'arm64-apple-ios26.0.0-simulator'`.
These warnings are retained, not reported as a warning-free package build. The completed bundle records
381 successful cases on device `37F67FE1-6E99-43A7-9EC5-DBDD9823B599`, platform iOS Simulator,
OS 27.0 build 24A434, with no runtime warnings.

Review covered origin/path validation, strict inspection aliases, routing/query multiplicity, progress,
raw/singleton decoding, dates/nulls, API inference, and shared execution. It corrected declaration order,
copied documentation, field shorthand capitalization, and literal-plus encoding in presidential filters.
A shared matrix checks eleven new operations at everyday/request/endpoint/receipt levels for HTTP
400/404/429/302, exact failure bytes/headers, malformed JSON, response limits, and cancellation before
send. Sequence tests separately exercise lazy demand, independent iterators, early break, later-page
failures, cancellation during requests and item draining, and malicious continuation links.

Earlier test attempts encountered Xcode transport/XPC failures and an incomplete result bundle.
The complete macOS and simulator runs above supersede those missing execution receipts. Initial new
test compile errors were corrected. An ambiguous DocC overload link was corrected before both final
documentation passes. A generator invocation missing required arguments and a discovery invocation
finding zero tests were not accepted as passes; the explicit generator commands above passed.

## Demo runtime evidence

The live walkthrough on iPhone 18 Pro passed issue hierarchy/disclosures, explicit reference batch
lookup, current inspection listing, inspection detail with separately displayed timestamps, empty
search, invalid-date error/recovery, and existing general search. No functional or visual defect was
observed. The inspected demo source is unchanged from the walkthrough; final package corrections were
subsequently rebuilt in the app.

Inspection search returned `count: 0` on October 4 with the provider's notice that the public-inspection
list would return Monday, October 5 at 08:45 Eastern. This explains the observed empty search.
Live inspection next-page behavior is unavailable in that window; recorded continuation tests and the
offline demo passed separately. In-flight UI cancellation remains unverified because each request
completed before the cancellation tap. No device cancellation pass is inferred from unit tests.

Local logs, result summaries, screenshots, hierarchies, and generated archives are retained under
`plans/expanded-qualification/` in this checkout. They are ignored local evidence, not hosted artifacts.
The execution ledger records commits, failures, corrections, artifact paths, and the next action.

## Hosted and delivery limits

No push, workflow dispatch, Pages publication, tag, or release was performed for this work.
The historical hosted record at `22371b9` predates this API expansion: its
[CI run](https://github.com/KalebCooper/swift-federal-register/actions/runs/36249651383) and
[DocC run](https://github.com/KalebCooper/swift-federal-register/actions/runs/36249651388)
were recorded successful in the prior readiness document. They do not qualify this candidate.

Remaining evidence is Android emulator execution, hosted CI/DocC on the eventual delivery commit,
live inspection paging during provider availability, and observed in-flight demo cancellation.
Hosted timeouts remain provisional. Delivery requires a separate owner decision; a main push can
trigger Pages deployment. Published documentation and release status remain separate from these local
builds.
