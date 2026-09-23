#!/usr/bin/env bash
# Convert only this package's two products from already-built iOS simulator modules.
# Dependencies must compile, but their documentation is not part of this site.
set -euo pipefail

# Source-dependent validation is unavailable until both real service modules exist.
readiness_root="${VERIFY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
if true; then
  for module in SwiftFederalRegisterDocuments SwiftFederalRegisterDocumentsModels; do
    if [ ! -d "$readiness_root/Sources/$module" ] || ! find "$readiness_root/Sources/$module" -name '*.swift' -type f | grep -q .; then
      echo "Not ready: $module source is not implemented; see IMPLEMENTATION_READINESS.md." >&2
      exit 1
    fi
  done
fi

modules="${1:?Usage: bash Scripts/build-docs.sh MODULES_DIRECTORY OUTPUT_DIRECTORY [TARGET]}"
output="${2:?Supply a new output directory}"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
target="${3:-$(uname -m)-apple-ios26.0-simulator}"

if [[ -e "$output" ]]; then
  echo "Output already exists: $output. Supply a new directory." >&2
  exit 1
fi
mkdir -p "$output/models-symbols" "$output/sdk-symbols" "$output/module-cache"

xcrun swift-symbolgraph-extract -module-name SwiftFederalRegisterDocumentsModels \
  -target "$target" -sdk "$sdk" -I "$modules" \
  -module-cache-path "$output/module-cache" \
  -output-dir "$output/models-symbols" -minimum-access-level public
xcrun docc convert Sources/SwiftFederalRegisterDocumentsModels/SwiftFederalRegisterDocumentsModels.docc \
  --additional-symbol-graph-dir "$output/models-symbols" \
  --output-dir "$output/SwiftFederalRegisterDocumentsModels.doccarchive" \
  --enable-experimental-external-link-support --warnings-as-errors

xcrun swift-symbolgraph-extract -module-name SwiftFederalRegisterDocuments \
  -target "$target" -sdk "$sdk" -I "$modules" \
  -module-cache-path "$output/module-cache" \
  -output-dir "$output/sdk-symbols" -minimum-access-level public
xcrun docc convert Sources/SwiftFederalRegisterDocuments/SwiftFederalRegisterDocuments.docc \
  --additional-symbol-graph-dir "$output/sdk-symbols" \
  --output-dir "$output/SwiftFederalRegisterDocuments.doccarchive" \
  --enable-experimental-external-link-support \
  --dependency "$output/SwiftFederalRegisterDocumentsModels.doccarchive" --warnings-as-errors

xcrun docc merge "$output/SwiftFederalRegisterDocumentsModels.doccarchive" "$output/SwiftFederalRegisterDocuments.doccarchive" \
  --synthesized-landing-page-name swift-federal-register --synthesized-landing-page-kind Package \
  --output-path "$output/merged.doccarchive"
xcrun docc process-archive transform-for-static-hosting "$output/merged.doccarchive" \
  --output-path "$output/site" --hosting-base-path swift-federal-register

# The archive's app shell has no root route under the Pages subpath.
cat > "$output/site/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=documentation/">
    <link rel="canonical" href="https://kalebcooper.github.io/swift-federal-register/documentation/">
    <title>swift-federal-register</title>
  </head>
  <body>
    <p>Redirecting to the <a href="documentation/">swift-federal-register documentation</a>.</p>
  </body>
</html>
HTML
