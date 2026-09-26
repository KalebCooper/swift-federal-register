# Implementation readiness

Document detail, presidential search, general document search, regulatory metadata projections, and
agency discovery are implemented. The package is not released. The local qualification below was
collected September 26, 2026 UTC on candidate commit `2432354`, superseding the prior record at `c30d9a8`.
Hosted CI, Android, documentation publication, and release have not run for this candidate; the last
hosted qualification is for `22371b9`, before search and agencies existed. No result is inferred from an
earlier commit unless the row says so.

Since the prior record, a document search continuation now fails closed whenever a next link's current
page number is present but malformed (repeated, non-integer, or otherwise not exactly one integer), the
same way an entirely absent page number already did; only a bare absent page still counts as page one.
Raw JSON value decoding checks container shapes (array and object) ahead of scalar types, which decodes
container-heavy responses such as the agency catalog measurably faster with no change to any decoded
value. Documentation was corrected to state hosted test coverage precisely and to describe presidential
continuation as cursor or page-number links rather than cursor-only.

## Evidence classes

Each result below carries one class. A class is never promoted by a result from another class.

| Class | Meaning |
| --- | --- |
| Source | Repository gate, checker self-test, strict format lint, generator drift check, fixture digests. |
| Local correctness | Test suites on this host: Apple simulator through Xcode, Linux in the `swift:6.3-noble` container. |
| Platform | Documentation builds, the offline consumer demo, and the iOS demo build on this host. |
| Hosted | GitHub Actions CI and documentation workflows on the candidate commit. |
| Release | Tag, release, and GitHub Pages publication. |

## Verified dependency and provider evidence

Public swifty-networking tag `1.3.1` was verified with `git ls-remote`: annotated tag
`61a238a34051e0b1e15876291d0eef7bc2b6adfe`, peeled commit
`04bbf231eabb95b90a5be786034e07cf351ee1d5`. The manifest floor is 1.3.1, and the tracked
lockfile is the verified HTTPPortable-enabled superset. The SDK uses PageSequence's response decoding
hook for receipts without a second fetch; models have no third-party dependency.

The official schema at [API documentation JSON](https://www.federalregister.gov/api/v1/documentation)
was successfully retrieved. It describes search since 1994, page sizes 1...1000 with default 20,
presidential filters, and chronological order. The [documentation page](https://www.federalregister.gov/developers/documentation/api/v1)
states that API keys are not required and distinguishes informational renditions from GPO's official
edition. Direct documentation-page redirects encountered an access challenge; the API schema and payloads
succeeded. A numerical request quota remains unverified. The client sends once, refuses redirects, and
retains HTTP errors and Retry-After fields for caller-controlled backoff.

Current `2026-19417`, historical `93-32104`, two sequential presidential pages, and a terminal historical
page were fetched on September 24, 2026 UTC. The live next link contains an opaque `search_after_cursor`
despite `total_pages = 50`. A malformed cursor returned HTTP 400.

Historical `pdf_url` and `full_text_xml_url` are null. Its advertised HTML body returned 404; its text
link returned 200 with text/plain and an HTML pre wrapper. That text and `signing_date` assert December
18, 1993, while `toc_doc` and `toc_subject` say December 19. These assertions remain separate. Current
HTML/XML/text payloads all succeeded. No historical PDF/XML availability is claimed or synthesized.

On September 26, 2026 UTC the agency catalog, the EPA and HHS agency detail records, a regulatory and RIN
document detail, and general search variants (newest, oldest, relevance, a `fields[]` selection, a keyword
term, a zero-match search, and their recorded continuations) were retrieved from official routes with the
package User-Agent. The schema's agency enumeration and the recorded catalog carry the same 473 slugs.
One further authorized request that day, a two-word term search (`conditions[term]=clean water`, newest,
two per page, 2024 publication range) at 19:28:15 UTC, returned HTTP 200 with 4204 bytes and SHA-256
`f9bdb534ca5bfc4624644af0ef23808f676226cdeed3a91dd6cd1d34c55d249d`; its next link writes the space as `+`.
Every recorded search with a term continues through a `page` number and no `search_after_cursor`; every
recorded search without a term continues through a cursor. A zero-match search body carries only
`description` and `count: 0`, with no `results` or `total_pages`.

All 25 shipped fixture bodies are byte-exact and have URL/query, UTC instant, status, media type, byte
count, SHA-256, and publisher receipts. Every digest and byte count matched its receipt at `c30d9a8` and
again at `2432354` (25 receipts, zero mismatches each time; no fixture changed between the two). The
September 24 malformed-cursor probe's full query was never logged, so its receipt states only the
evidenced `search_after_cursor=invalid` fragment.

## Implemented surface

- `SwiftFederalRegisterDocumentsModels`: complete JSON field retention; document, page, and agency
  values; validated date, page-size, CFR, and agency-slug inputs; `DocumentSearchQuery` filters for
  agency, CFR location, docket, effective and publication date, Regulation Identifier Number, term, and
  type, in newest or oldest order; `AgencyIdentifier` with the generated 473-slug catalog; typed
  endpoints for detail, content, presidential and general search, the agency catalog, and one agency;
  constrained requests with public value resolutions; UTF-8 source-content decoding; cursor and
  page-number continuation validation; and portable receipts.
- Regulatory projections on `FederalRegisterDocument`: CFR references, Regulation Identifier Numbers,
  docket identifiers, the `significant` flag, agency attributions, and `DocumentType`, each read from
  retained `fields` with no defaults. Search results carry only the provider's default projection, so
  most of these are nil there by design.
- `SwiftFederalRegisterDocuments`: everyday detail, content, presidential and general search first-page
  methods, `agencies()` and `agency(_:)`, typed request and endpoint execution, raw response receipts, and
  lazy page, item, and receipt sequences over shared PageSequence for presidential and general searches.
  A zero-match search returns one empty page.
- Independent iterators, no prefetch, order and duplicate preservation, cancellation before each request
  and while draining buffered items, and explicit invalid-link, repeated-cursor, missing-cursor, and
  nonprogressing-page errors. Continuation refuses other origins, credentials, fragments, agency routes,
  and a changed query. Custom endpoint requests remain one page.
- API inference and consumer-extension examples in deterministic tests, two DocC catalogs, attributed
  fixtures, an offline consumer executable covering agency, search, regulatory, and presidential flows,
  and an iOS demo with presidential, search, and agency screens.

Content decoding preserves UTF-8 markup; it does not implement an XML element model, HTML rendering,
PDF/MODS downloading, or cross-provider reconciliation. Agency discovery does not fetch logos or follow
agency links. Relevance order is not a query option, and repeated agency and type filters are sent with
their multiplicity without a documented provider combination rule. Response limits apply after transport
buffering. Receipts retain optional caller-supplied retrieval timestamps; no clock instant is invented.

## Local qualification for `2432354`

Run September 26, 2026 UTC on macOS 27.0 with Xcode 27 and Docker. Exit statuses were read from files.

| Gate | Command or tool | Result | Class |
| --- | --- | --- | --- |
| Repository source gate | `bash Scripts/verify.sh` | Exit 0; 16 checks passed, including strict format and the agency catalog drift check. | Source |
| Source checker self-test | `bash Scripts/verify.sh --self-test` | Exit 0; 49 planted-violation arms. | Source |
| Strict format lint | `swift format lint --strict --recursive Sources Tests` | Exit 0; zero findings. | Source |
| Agency catalog generator | `python3 Scripts/generate-agency-identifiers.py --check` against the recorded catalog | Exit 0; 473 identifiers match. Generator unit tests: 10 passed. | Source |
| Fixture digests | SHA-256 and byte count of each body against `receipts.json` | 25 receipts, zero mismatches. | Source |
| Apple package tests | Xcode MCP `RunAllTests`, scheme `swift-federal-register-Package` (from the result), iPhone 18 Pro simulator, iOS 27.0 | 293 passed, 0 failed, 0 skipped (parameterized cases counted individually). Models target 160: `AgencyIdentifierTests` 4, `AgencyModelsTests` 29, `DocumentModelsTests` 17, `DocumentSearchQueryTests` 97, `RegulatoryMetadataTests` 13. SDK target 133: `AdditionalContractTests` 7, `AgencyClientTests` 12, `DocumentSearchClientTests` 11, `DocumentSearchPaginationTests` 83, `FederalRegisterClientTests` 20. Same suite breakdown as the prior record. | Local correctness |
| Linux, HTTPPortable | `bash Scripts/linux-test.sh`, trait variable unset | Exit 0; 119 tests in 10 suites, 0.563 s. | Local correctness |
| Linux, default traits | Same run, second pass | Exit 0; 119 tests in 10 suites, 0.491 s. | Local correctness |
| Lockfile | `git diff --exit-code Package.resolved` after the Linux run, and after each Xcode workspace open | Clean. Opening the package workspace and the demo project each pruned the lockfile; the tracked superset was restored and is byte-identical to the committed file each time. | Local correctness |
| DocC, Linux symbols | `bash Scripts/linux-docs.sh` | Exit 0; models then SDK catalogs and the merged archive, zero warnings under `--warnings-as-errors`. | Platform |
| DocC, Apple symbols | `bash Scripts/build-docs.sh` with iOS simulator modules built fresh from this record's Apple test run | Exit 0; models then SDK catalogs, merged archive, and static site, zero warnings under `--warnings-as-errors`. | Platform |
| Offline consumer demo | `bash Scripts/linux-demo.sh` | Exit 0; agency catalog (473), EPA detail, two search pages, regulatory detail in 5 recorded requests, then the presidential flow in 4 recorded requests, with no prefetch. | Platform |
| iOS demo, Debug | Xcode MCP `BuildProject`, scheme `SwiftFederalRegisterDocumentsDemo`, iPhone 18 Pro | Succeeded; Debug-iphonesimulator, iPhoneSimulator27.0 SDK, zero warnings. Built with the package workspace closed. | Platform |
| iOS demo, Release | Xcode MCP `BuildProject`, scheme `SwiftFederalRegisterDocumentsDemoRelease` | Succeeded at `c30d9a8` when that commit was made, zero warnings; not rebuilt for this record. | Platform |
| iOS demo runtime | Xcode MCP `RunProject` and device interaction against the live API, at `c30d9a8` when that commit was made | Search results, next page appended, regulatory metadata with distinct not-supplied and empty states, agency catalog and detail, an invalid slug's HTTP 404 error, and presidential `93-32104` detail rendered. Cancel of an in-flight page is unverified: each page loaded before the tap landed. Not re-run for this record. | Platform |
| Android | None on this host | Not run: no Swift Android SDK or `adb` is installed. Hosted only. | Hosted |

## Hosted verification

Hosted jobs have not run for `2432354`; nothing has been pushed since `22371b9`. That includes the
verification lane's `python3` installation step, which runs the agency catalog drift check in CI and has
been exercised only in a local `swift:6.3-noble` container.

The last hosted qualification is for `22371b9`, which predates search, regulatory metadata, and agency
discovery. All five jobs in its [CI run](https://github.com/KalebCooper/swift-federal-register/actions/runs/36249651383)
and its [DocC run](https://github.com/KalebCooper/swift-federal-register/actions/runs/36249651388)
completed successfully. It does not qualify `2432354`.

| Gate at `22371b9` | Result |
| --- | --- |
| Android | Passed all 29 tests in three suites on the emulator with Swift 6.3.3 and HTTPPortable. |
| Apple package tests | Passed all three Swift Testing suites on iPhone 18 Pro / iOS 27 with Xcode 27. |
| DocC | Both catalogs, merged archive, static site, and uploaded artifact passed. Pages deployment is enabled for main pushes and manual workflow runs. |
| Linux | Passed all 29 tests in three suites under both HTTPPortable and default traits. |
| Release demo | Hosted simulator Release build passed. |
| Source verification and lint | Passed, including 45 source-checker self-test arms. |

GitHub origin is configured and main is pushed through `22371b9`. No tag or release is published.

## Remaining delivery gates

- Hosted CI on the candidate: Linux both trait modes, Android emulator, Apple simulator, source
  verification with the `python3` step, and lint.
- Hosted DocC on the candidate, and GitHub Pages publication.
- Android test execution, which has no local route on this host.
- iOS demo cancellation of an in-flight page, which remains unverified.
- Tag and release.

Timeouts remain provisional. Pushes, tags, releases, and hosted documentation publication require the
owner's delivery decision.

Use `bash Scripts/verify.sh` and `--self-test` for implementation changes. The historical scaffold validator
is no longer an applicable source gate and is not run by the source checker self-test. No missing-subject
protection was removed.
