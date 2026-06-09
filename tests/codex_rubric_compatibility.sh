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

require_pattern ".agents/skills/harnessable/SKILL.md" "harnessable Rubric" "Rubric loop"
require_pattern ".agents/skills/harnessable/SKILL.md" "per-criterion" "per-criterion verdict table"

require_pattern "codex/qa.prompt.md" "Layer 1.*Acceptance Criteria" "Rubric Layer 1"
require_pattern "codex/qa.prompt.md" "Layer 2.*Verification Checklists" "Rubric Layer 2"
require_pattern "codex/qa.prompt.md" "Layer 3.*Completion Gate" "Rubric Layer 3"
require_pattern "codex/qa.prompt.md" "Per-Criterion Verdict Table" "Per-Criterion Verdict Table"
require_pattern "codex/qa.prompt.md" "Overall verdict derivation" "overall verdict derivation"
require_pattern "codex/qa.prompt.md" "NEEDS_REVISION Handoff" "NEEDS_REVISION handoff"

require_pattern "codex/examples/qa.prompt.md" "three-layer Rubric" "example Rubric"
require_pattern "codex/examples/qa.prompt.md" "Per-Criterion Verdict Table" "example per-criterion table"
require_pattern "codex/examples/qa.prompt.md" "NEEDS_REVISION" "example NEEDS_REVISION handoff"

require_pattern "codex/engineer.prompt.md" "Verification Checklists.*Rubric Layer 2" "Engineer Rubric Layer 2"
require_pattern "codex/examples/engineer.prompt.md" "Verification Checklists as Rubric Layer 2" "Engineer example Rubric Layer 2"

require_pattern "codex/README.md" "harnessable Rubric loop" "README Rubric loop"
require_pattern "codex/README.md" "per-criterion verdict table" "README per-criterion table"

echo "codex_rubric_compatibility: OK"
