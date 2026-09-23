# Implementation readiness

This repository is an infrastructure scaffold, with no service source, products, dependencies, or release. A scaffold check is not a build or portability result.

## First implementation prerequisite

Complete and verify the shared swifty-networking transport receipt and portable decoding work before starting the government API slice. Select the published dependency version only after that work is available. Do not add provisional dependency pins, the HTTPPortable trait, or empty targets.

The intended product pair is `SwiftFederalRegisterDocuments` and `SwiftFederalRegisterDocumentsModels`. These names are reserved by the package scope, not declared in the manifest. Preserve OFR/NARA and GPO publisher provenance. Verify current official API contracts, terms, authentication, quotas, cursor continuation, and representation availability before implementation. Preserve historical null format links and conflicting source date fields; absence from the Federal Register does not establish absence of a presidential action.

## Deferred implementation and verification

- Actual models, endpoints, typed requests, client operations, fixtures, Swift Testing suites, and consumer compile examples.
- HTTPPortable trait forwarding, transport dependencies, and the verified trait-on `Package.resolved` superset.
- Apple build/tests with the generated `swift-federal-register-Package` scheme through Xcode MCP.
- Linux default and HTTPPortable suites, Android emulator suite, and source formatting. Their retained CI jobs are explicitly disabled.
- One DocC catalog per implemented product, models-first documentation metadata, `.spi.yml`, and zero-warning local DocC builds. Both documentation workflow jobs are disabled.
- A working demo and its release build. Demo CI wiring is retained but disabled with the Apple job.
- Full repository source verification and all platform gates before activating source CI.
- Remote creation, push, hosted CI, tags, and release publication require a separate delivery decision.

`Scripts/verify-source.sh` retains the adapted family gate and its planted-violation self-tests. Source, Linux, and documentation scripts reject absent modules before doing source-dependent work. `Scripts/verify.sh --scaffold` checks only infrastructure; the default command never treats this scaffold as a completed library.
