# Offline demo

A command-line tool that runs `FederalRegisterClient` against recorded FederalRegister.gov responses,
with no network access. It is a quick way to see what the SDK returns without writing an app.

## Run it

From the repository root:

```sh
swift run --package-path Examples/OfflineDemo FederalRegisterOfflineDemo "$PWD/Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures"
```

Or build and run it in the pinned Linux container:

```sh
bash Scripts/linux-demo.sh
```

## What it shows

The tool runs two independent flows, each with its own recorded transport, and prints how many
requests each one made.

**Agencies, search, and regulatory metadata** (5 requests):

- Finds the Environmental Protection Agency in the agency catalog and fetches its detail.
- Walks a newest-first search of 2024 publications for two pages, lazily.
- Fetches document 2024-31396 and prints its type, agencies, CFR references, dockets, Regulation
  Identifier Numbers, and significance. A value the service did not supply prints as "not
  supplied", distinct from an empty list.

**A historical presidential document** (4 requests):

- Prints document 93-32104's publication date beside its conflicting signing and table of contents
  dates, its null PDF and XML links, and the size of its original text representation.
- Walks two presidential search pages and prints each page's receipt URL and documents.

Neither flow fetches a third page.

## How it works

The example is its own package. It depends on swifty-networking's `HTTPTesting` only to serve the
recorded responses through a mock transport; the SDK and models products do not depend on it. Each
recording's source URL, retrieval time, and digest are listed in the fixtures' `receipts.json`.
