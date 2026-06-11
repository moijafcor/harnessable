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
require_pattern ".agents/skills/harnessable/SKILL.md" "Designer" "Designer skill guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "Asset Package" "Asset Package skill guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "Project Manager" "Project Manager skill guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "WORLD_MODEL.md" "World Model skill guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "OPERATOR" "OPERATOR skill guidance"
require_pattern ".agents/skills/harnessable/SKILL.md" "PLAYWRIGHT" "PLAYWRIGHT skill guidance"

require_pattern "codex/qa.prompt.md" "Layer 1.*Acceptance Criteria" "Rubric Layer 1"
require_pattern "codex/qa.prompt.md" "Layer 2.*Verification Checklists" "Rubric Layer 2"
require_pattern "codex/qa.prompt.md" "Layer 3.*Completion Gate" "Rubric Layer 3"
require_pattern "codex/qa.prompt.md" "Per-Criterion Verdict Table" "Per-Criterion Verdict Table"
require_pattern "codex/qa.prompt.md" "fresh-context classifier" "QA classifier role"
require_pattern "codex/qa.prompt.md" "error-modes.md" "QA error modes reference"
require_pattern "codex/qa.prompt.md" "OPERATOR" "QA OPERATOR source"
require_pattern "codex/qa.prompt.md" "PLAYWRIGHT" "QA PLAYWRIGHT source"
require_pattern "codex/qa.prompt.md" "Overall verdict derivation" "overall verdict derivation"
require_pattern "codex/qa.prompt.md" "NEEDS_REVISION Handoff" "NEEDS_REVISION handoff"

require_pattern "codex/examples/qa.prompt.md" "three-layer Rubric" "example Rubric"
require_pattern "codex/examples/qa.prompt.md" "Per-Criterion Verdict Table" "example per-criterion table"
require_pattern "codex/examples/qa.prompt.md" "fresh-context classifier" "example QA classifier role"
require_pattern "codex/examples/qa.prompt.md" "error-modes.md" "example QA error modes reference"
require_pattern "codex/examples/qa.prompt.md" "OPERATOR" "example QA OPERATOR source"
require_pattern "codex/examples/qa.prompt.md" "PLAYWRIGHT" "example QA PLAYWRIGHT source"
require_pattern "codex/examples/qa.prompt.md" "NEEDS_REVISION" "example NEEDS_REVISION handoff"

require_pattern "codex/engineer.prompt.md" "Verification Checklists.*Rubric Layer 2" "Engineer Rubric Layer 2"
require_pattern "codex/engineer.prompt.md" "executing type" "Engineer executing type guidance"
require_pattern "codex/engineer.prompt.md" "Designer" "Engineer Designer guidance"
require_pattern "codex/engineer.prompt.md" "DESIGN_AMBIGUITY" "Engineer design ambiguity guidance"
require_pattern "codex/engineer.prompt.md" "OPERATOR" "Engineer OPERATOR guidance"
require_pattern "codex/engineer.prompt.md" "PLAYWRIGHT" "Engineer PLAYWRIGHT guidance"
require_pattern "codex/examples/engineer.prompt.md" "Verification Checklists as Rubric Layer 2" "Engineer example Rubric Layer 2"
require_pattern "codex/examples/engineer.prompt.md" "Designer" "Engineer example Designer guidance"
require_pattern "codex/examples/engineer.prompt.md" "DESIGN_AMBIGUITY" "Engineer example design ambiguity guidance"
require_pattern "codex/examples/engineer.prompt.md" "OPERATOR" "Engineer example OPERATOR guidance"
require_pattern "codex/examples/engineer.prompt.md" "PLAYWRIGHT" "Engineer example PLAYWRIGHT guidance"

require_pattern "codex/designer.prompt.md" "Act as Designer" "Designer prompt role"
require_pattern "codex/designer.prompt.md" "Asset Package" "Designer prompt AP"
require_pattern "codex/designer.prompt.md" "DESIGN_AMBIGUITY" "Designer prompt blocker"
require_pattern "codex/examples/designer.prompt.md" "Act as Designer" "Designer example role"
require_pattern "codex/examples/designer.prompt.md" "Asset Package" "Designer example AP"

require_pattern "codex/pm.prompt.md" "Act as Project Manager" "PM prompt role"
require_pattern "codex/pm.prompt.md" "Decision Request" "PM decision request"
require_pattern "codex/pm.prompt.md" "Orchestrator" "PM Orchestrator boundary"
require_pattern "codex/examples/pm.prompt.md" "Act as Project Manager" "PM example role"
require_pattern "codex/examples/pm.prompt.md" "Communication Package" "PM example CP deployment"

require_pattern "codex/inspector.prompt.md" "Playwright" "Inspector Playwright guidance"
require_pattern "codex/inspector.prompt.md" "first-class" "Inspector first-class Playwright"
require_pattern "codex/examples/inspector.prompt.md" "PLAYWRIGHT" "Inspector example PLAYWRIGHT guidance"

require_pattern "codex/sre.prompt.md" "WORLD_MODEL.md" "SRE World Model guidance"
require_pattern "codex/sre.prompt.md" "no new pattern" "SRE no-new-pattern guidance"
require_pattern "codex/emergency.prompt.md" "WORLD_MODEL.md" "Emergency World Model guidance"
require_pattern "codex/emergency.prompt.md" "no new pattern" "Emergency no-new-pattern guidance"
require_pattern "codex/examples/sre.prompt.md" "WORLD_MODEL.md" "SRE example World Model guidance"
require_pattern "codex/examples/emergency.prompt.md" "WORLD_MODEL.md" "Emergency example World Model guidance"

require_pattern "codex/README.md" "harnessable Rubric loop" "README Rubric loop"
require_pattern "codex/README.md" "per-criterion verdict table" "README per-criterion table"
require_pattern "codex/README.md" "WORLD_MODEL.md" "README World Model guidance"
require_pattern "codex/README.md" "error-modes.md" "README error modes guidance"
require_pattern "codex/README.md" "Designer" "README Designer guidance"
require_pattern "codex/README.md" "Project Manager" "README PM guidance"
require_pattern "codex/README.md" "Asset Package" "README Asset Package guidance"
require_pattern "codex/README.md" "OPERATOR" "README OPERATOR guidance"
require_pattern "codex/README.md" "PLAYWRIGHT" "README PLAYWRIGHT guidance"

echo "codex_rubric_compatibility: OK"
