#!/usr/bin/env bash
# The source gate remains nonvacuous; scaffold validation is retained only for historical tooling.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  --scaffold) python3 "$ROOT/Scripts/verify-scaffold.py" ;;
  --self-test)
    bash "$ROOT/Scripts/verify-source.sh" --self-test
    ;;
  "") bash "$ROOT/Scripts/verify-source.sh" ;;
  *) echo "Usage: $0 [--scaffold|--self-test]" >&2; exit 2 ;;
esac
