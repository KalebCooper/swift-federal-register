# Implementation readiness

The first document/detail and presidential-search slices are implemented locally. The package is not
released; Apple and Android qualification remains incomplete. Validation below was performed September
24, 2026 UTC. Implementation commit: `80c340e`. No source or build result is inferred from project
creation or scaffold validation.

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
page were fetched. The live next link contains an opaque `search_after_cursor` despite `total_pages = 50`.
A malformed cursor returned HTTP 400. All fixture bodies remain byte-exact and have URL/query, UTC instant,
status, media type, byte count, SHA-256, and publisher receipts. Ten fixture hashes were checked locally.

Historical `pdf_url` and `full_text_xml_url` are null. Its advertised HTML body returned 404; its text
link returned 200 with text/plain and an HTML pre wrapper. That text and `signing_date` assert December
18, 1993, while `toc_doc` and `toc_subject` say December 19. These assertions remain separate. Current
HTML/XML/text payloads all succeeded. No historical PDF/XML availability is claimed or synthesized.

## Implemented surface

- `SwiftFederalRegisterDocumentsModels`: complete JSON field retention, document/page values, validated
  date/page-size filters, typed endpoints, constrained requests with public value resolutions, UTF-8
  source-content decoding, continuation validation, and portable receipts.
- `SwiftFederalRegisterDocuments`: everyday detail/content/first-page methods, typed request and endpoint
  execution, raw response receipts, and lazy page/item/receipt sequences over shared PageSequence.
- Independent iterators, no prefetch, order/duplicate preservation, cancellation while buffered, and
  explicit invalid/repeated continuation errors. Custom endpoint requests remain one page.
- API inference and consumer-extension examples in deterministic tests, two DocC catalogs, attributed
  fixtures, an offline consumer executable, and an iOS demo source/project using objectVersion 77.

Content decoding preserves UTF-8 markup; it does not implement an XML element model, HTML rendering,
PDF/MODS downloading, or cross-provider reconciliation. Response limits apply after transport buffering.
Receipts retain optional caller-supplied retrieval timestamps; no clock instant is invented.

## Local verification

| Gate | Result |
| --- | --- |
| Repository source gate | Passed, including strict format and absent-subject protection. |
| Source checker self-tests | Passed, 45 planted-violation arms. |
| Linux, HTTPPortable | Passed, 29 tests in three suites, Swift 6.3 container. |
| Linux, default traits | Passed, the same 29 tests; verified trait-on lockfile restored afterward. |
| DocC, models then SDK | Both catalogs and merged archive passed with zero warnings using Linux symbol graphs and, separately, Apple-built iOS simulator modules. |
| Offline consumer demo | Built and ran in Linux; historical receipt/content and two cursor pages used exactly four recorded requests. |
| iOS demo project | Created with MCP, configured through XcodeGen, format 77 verified. MCP BuildProject timed out after 300 seconds without a compiler result; runtime remains unverified. |
| Apple package build | Passed through MCP with build-for-testing on iPhone 18 Pro / iOS 27. Two linker warnings reported a macOS 27 sysroot while targeting the iOS 26 simulator deployment floor. |
| Apple package tests | Unavailable: RunAllTests timed out after 300 seconds and left an incomplete xcresult. A second attempt after selecting iPhone 17 Pro (26.5) was refused as already running. No test result is claimed. |
| Apple DocC | Passed both catalogs, merged archive, and static site with warnings-as-errors against Apple-built simulator modules. |
| Release demo | Release scheme supplied; verification unavailable while demo workspace operations time out. |
| Android | Unavailable: no installed Swift SDK or adb on this host. Retained emulator CI pins remain unchanged. |
| Hosted CI, remote, tag, release | Not performed; no remote is configured. |

The Xcode service was not reset, and sibling workspaces were not closed. Subsequent demo build-log
retrieval also timed out after 300 seconds, so no hidden demo compiler result is inferred. Opening the package root with
`XcodeOpenWorkspace` and using its returned workspace handle recovered build, scheme, and destination
operations after earlier path-based timeouts. The test runner remained stuck despite `StopProject`
reporting no running app. Only this package workspace was closed before opening its demo. MCP has no
package-edge, project-format, or scheme-configuration operation, so XcodeGen configured the demo's local
dependency, Debug/Release schemes, and format 77.

## Remaining delivery gates

Recover Apple test-runner completion on the generated package scheme and finish the iOS demo build/run
including Release. Run the Android
emulator suite and qualify the retained Xcode 27 Apple lane. All retained
CI/docs lanes remain disabled until qualification is complete; timeouts remain provisional.

Use `bash Scripts/verify.sh` and `--self-test` for implementation changes. The historical scaffold validator
is no longer an applicable source gate and is not run by the source checker self-test. No missing-subject
protection was removed. Public repository creation, pushes, tags, releases, and hosted publication still
require the owner's delivery decision.
