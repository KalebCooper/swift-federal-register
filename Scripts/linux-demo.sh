#!/usr/bin/env bash
# Run the recorded-data consumer example with the same Linux compiler as the test gate.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
docker run --rm \
  --volume "$root:/workspace" \
  --volume swift-federal-register-linux-build:/scratch \
  --workdir /workspace swift:6.3-noble \
  swift run --package-path Examples/OfflineDemo --scratch-path /scratch/offline-demo \
  FederalRegisterOfflineDemo /workspace/Sources/SwiftFederalRegisterDocumentsTestSupport/Fixtures
