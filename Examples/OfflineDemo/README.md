# Recorded-data demo

This executable demonstrates the public SDK against attributed recorded responses without contacting
the API. It runs two independent flows, each with its own recorded transport and request count.

The first flow looks up the Environmental Protection Agency in the recorded agency catalog and fetches
its agency detail, follows a newest-first general search over 2024 publication dates for two lazy
cursor pages, then fetches regulatory document 2024-31396 and prints its typed projections: type,
agencies, CFR references, docket identifiers, Regulation Identifier Numbers, and the significance flag.
A value the provider did not supply prints as "not supplied", and an empty list stays distinct from it.
The flow reports 5 recorded requests.

The second flow prints the historical presidential date conflict, unavailable format links, original
text representation, and two lazy presidential cursor-page receipts, and reports 4 recorded requests.
Neither flow prefetches a third page.

Run from the repository root:

```sh
swift run --package-path Examples/OfflineDemo FederalRegisterOfflineDemo "$PWD/Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures"
```

The separate example package depends on HTTPTesting only to supply its recorded transport. The SDK
and models products do not depend on HTTPTesting. The source fixtures' provenance and hashes remain
in their original `receipts.json` manifest.
