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
require_pattern ".agents/skills/harnessable/SKILL.md" "executing type" "executing type guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "OPERATOR" "OPERATOR skill guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "PLAYWRIGHT" "PLAYWRIGHT skill guidance"

require_pattern "codex/qa.prompt.md" "Layer 1.*Acceptance Criteria" "Rubric Layer 1"
require_pattern "codex/qa.prompt.md" "Layer 2.*Verification Checklists" "Rubric Layer 2"
require_pattern "codex/qa.prompt.md" "Layer 3.*Completion Gate" "Rubric Layer 3"
require_pattern "codex/qa.prompt.md" "Per-Criterion Verdict Table" "Per-Criterion Verdict Table"
require_pattern "codex/qa.prompt.md" "OPERATOR" "QA OPERATOR source"
require_pattern "codex/qa.prompt.md" "PLAYWRIGHT" "QA PLAYWRIGHT source"
require_pattern "codex/qa.prompt.md" "Overall verdict derivation" "overall verdict derivation"
require_pattern "codex/qa.prompt.md" "NEEDS_REVISION Handoff" "NEEDS_REVISION handoff"

require_pattern "codex/examples/qa.prompt.md" "three-layer Rubric" "example Rubric"
require_pattern "codex/examples/qa.prompt.md" "Per-Criterion Verdict Table" "example per-criterion table"
require_pattern "codex/examples/qa.prompt.md" "OPERATOR" "example QA OPERATOR source"
require_pattern "codex/examples/qa.prompt.md" "PLAYWRIGHT" "example QA PLAYWRIGHT source"
require_pattern "codex/examples/qa.prompt.md" "NEEDS_REVISION" "example NEEDS_REVISION handoff"

require_pattern "codex/engineer.prompt.md" "Verification Checklists.*Rubric Layer 2" "Engineer Rubric Layer 2"
require_pattern "codex/engineer.prompt.md" "executing type" "Engineer executing type guidance"
require_pattern "codex/engineer.prompt.md" "OPERATOR" "Engineer OPERATOR guidance"
require_pattern "codex/engineer.prompt.md" "PLAYWRIGHT" "Engineer PLAYWRIGHT guidance"
require_pattern "codex/examples/engineer.prompt.md" "Verification Checklists as Rubric Layer 2" "Engineer example Rubric Layer 2"
require_pattern "codex/examples/engineer.prompt.md" "OPERATOR" "Engineer example OPERATOR guidance"
require_pattern "codex/examples/engineer.prompt.md" "PLAYWRIGHT" "Engineer example PLAYWRIGHT guidance"

require_pattern "codex/inspector.prompt.md" "Playwright" "Inspector Playwright guidance"
require_pattern "codex/inspector.prompt.md" "first-class" "Inspector first-class Playwright"
require_pattern "codex/examples/inspector.prompt.md" "PLAYWRIGHT" "Inspector example PLAYWRIGHT guidance"

require_pattern "codex/README.md" "harnessable Rubric loop" "README Rubric loop"
require_pattern "codex/README.md" "per-criterion verdict table" "README per-criterion table"
require_pattern "codex/README.md" "OPERATOR" "README OPERATOR guidance"
require_pattern "codex/README.md" "PLAYWRIGHT" "README PLAYWRIGHT guidance"

echo "codex_rubric_compatibility: OK"
