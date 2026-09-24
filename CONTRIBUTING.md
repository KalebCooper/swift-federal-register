# Contributing

Run `bash Scripts/verify.sh` before each commit and `bash Scripts/verify.sh --self-test` after editing
verification scripts. The source gate rejects missing modules; the retained historical scaffold mode is
not applicable once real sources exist. Run strict formatting over Sources, Tests, and Examples.

Implement complete service slices with portable models/endpoints, the independent client, recorded
fixtures, Swift Testing suites, consumer examples, DocC, README, and changelog changes. Preserve unknown
values, explicit nulls, identifiers, conflicting dates, and provider cursors. The public networking
dependency floor is 1.3.1. Never synthesize a representation URL from a missing format link.

Use Swift 6, the manifest's shared strict settings, alphabetical declarations within logical groups, and strict formatting. Models have no networking dependencies. Tests use recorded provider data rather than live requests. Use Xcode MCP tools for Apple project operations and generated package schemes.

Run `bash Scripts/linux-test.sh` for both Linux configurations and `bash Scripts/linux-demo.sh` for the
offline consumer. Build both catalogs models-first at zero warnings. `Scripts/build-docs.sh` consumes
Apple modules; `Scripts/linux-docs.sh` consumes the tested Linux modules and records Linux-only evidence.

Before publishing, complete the Apple, Android, documentation, and demo gates listed in
[implementation readiness](IMPLEMENTATION_READINESS.md). CI activation awaits those gates. Timeouts
remain provisional until measured green runs exist. Use focused Conventional Commits; publishing requires
owner authorization.
