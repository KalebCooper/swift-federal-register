# Recorded-data demo

This executable demonstrates the public SDK against attributed recorded responses without contacting
the API. It prints the historical date conflict, unavailable format links, original text representation,
and two lazy cursor-page receipts. It stops without prefetching a third page.

Run from the repository root:

```sh
swift run --package-path Examples/OfflineDemo FederalRegisterOfflineDemo "$PWD/Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures"
```

The separate example package depends on HTTPTesting only to supply its recorded transport. The SDK
and models products do not depend on HTTPTesting. The source fixtures' provenance and hashes remain
in their original `receipts.json` manifest.
