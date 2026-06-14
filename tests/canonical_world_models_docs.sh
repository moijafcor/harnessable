#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_pattern() {
  local file="$1" pattern="$2" label="$3"
  grep -Eq "$pattern" "$ROOT/$file" || fail "$label missing in $file"
}

reject_pattern() {
  local pattern="$1"
  shift
  if grep -REn "$pattern" "$@" >/tmp/harnessable_world_model_stale.$$; then
    cat /tmp/harnessable_world_model_stale.$$ >&2
    rm -f /tmp/harnessable_world_model_stale.$$
    fail "stale single-file WORLD_MODEL.md guidance found"
  fi
  rm -f /tmp/harnessable_world_model_stale.$$
}

ACTIVE_FILES=(
  "$ROOT/README.md"
  "$ROOT/CHEAT_SHEET.md"
  "$ROOT/framework/templates/dip.md"
  "$ROOT/framework/agents/sre.md"
  "$ROOT/framework/agents/emergency.md"
  "$ROOT/framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"
  "$ROOT/framework/vendor/harnessable/references/classifier.md"
  "$ROOT/framework/vendor/harnessable/references/error-modes.md"
)

reject_pattern \
  "WORLD_MODEL\\.md ##|WORLD_MODEL\\.md updated|WORLD_MODEL\\.md does not require update|WORLD_MODEL\\.md failure patterns|Check WORLD_MODEL\\.md|First check WORLD_MODEL\\.md|If the pattern exists in WORLD_MODEL\\.md|not already in WORLD_MODEL\\.md|WORLD_MODEL\\.md update" \
  "${ACTIVE_FILES[@]}"

require_pattern "README.md" "world_models/.*directory" "README world_models directory guidance"
require_pattern "README.md" "thin discovery index" "README thin index guidance"
require_pattern "framework/templates/dip.md" "world_models/ updated" "DIP world_models update declaration"
require_pattern "framework/agents/sre.md" "world_models/ updated" "SRE world_models update declaration"
require_pattern "framework/agents/emergency.md" "world_models/ updated" "Emergency world_models update declaration"
require_pattern "framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml" "world_models/\\*_world_model.md failure patterns" "KG world model pattern guidance"
require_pattern "framework/vendor/harnessable/references/classifier.md" "world_models/\\*_world_model.md" "classifier world model guidance"
require_pattern "framework/vendor/harnessable/references/error-modes.md" "world_models/\\*_world_model.md" "error modes world model guidance"

echo "canonical_world_models_docs: OK"
