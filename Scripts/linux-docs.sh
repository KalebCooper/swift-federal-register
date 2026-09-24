#!/usr/bin/env bash
# Extract Linux symbols from the already-tested default graph, then convert both catalogs locally.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
bash "$root/Scripts/verify.sh" >/dev/null
output="${1:?Supply a new output directory inside the repository}"
if [[ -e "$output" ]]; then
  echo "Output already exists: $output" >&2
  exit 1
fi
mkdir -p "$output"
output="$(cd "$output" && pwd)"
case "$output" in
  "$root"/*) relative="${output#"$root"/}" ;;
  *) echo "Output must be inside the repository." >&2; exit 1 ;;
esac
mkdir -p "$output/models-symbols" "$output/sdk-symbols"
docker run --rm -i --volume "$root:/workspace" \
  --volume swift-federal-register-linux-build:/scratch \
  --workdir /workspace swift:6.3-noble bash -s -- "$relative" <<'LINUX'
set -euo pipefail
target="$(swift -print-target-info | sed -n 's/.*"triple": "\([^"]*\)".*/\1/p')"
modules="/scratch/default/$target/debug/Modules"
swift-symbolgraph-extract -module-name SwiftFederalRegisterDocumentsModels \
  -target "$target" -I "$modules" -module-cache-path /scratch/docs-module-cache \
  -output-dir "/workspace/$1/models-symbols" -minimum-access-level public
swift-symbolgraph-extract -module-name SwiftFederalRegisterDocuments \
  -target "$target" -I "$modules" -module-cache-path /scratch/docs-module-cache \
  -output-dir "/workspace/$1/sdk-symbols" -minimum-access-level public
LINUX
xcrun docc convert Sources/SwiftFederalRegisterDocumentsModels/SwiftFederalRegisterDocumentsModels.docc \
  --additional-symbol-graph-dir "$output/models-symbols" \
  --output-dir "$output/SwiftFederalRegisterDocumentsModels.doccarchive" \
  --enable-experimental-external-link-support --warnings-as-errors
xcrun docc convert Sources/SwiftFederalRegisterDocuments/SwiftFederalRegisterDocuments.docc \
  --additional-symbol-graph-dir "$output/sdk-symbols" \
  --output-dir "$output/SwiftFederalRegisterDocuments.doccarchive" \
  --enable-experimental-external-link-support \
  --dependency "$output/SwiftFederalRegisterDocumentsModels.doccarchive" --warnings-as-errors
xcrun docc merge "$output/SwiftFederalRegisterDocumentsModels.doccarchive" \
  "$output/SwiftFederalRegisterDocuments.doccarchive" \
  --synthesized-landing-page-name swift-federal-register --synthesized-landing-page-kind Package \
  --output-path "$output/merged.doccarchive"
