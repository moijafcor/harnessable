# Engineer prompt — harnessable

Use the harnessable skill. Act as Engineer.

DMT: [PASTE OR REFERENCE DMT HERE]

Recon produces two outputs — complete both before authoring the DIP:
1. The Design Implementation Plan
2. Knowledge graph amendments for every concept encountered in recon
   that is not already declared in docs/knowledge-graph.yaml

Before planning, scan the role roster and world models:
- `ls docs/harness/agents/*.md` and read `## Role Scope`
- `ls packages/*/PACKAGE.md 2>/dev/null || true` and
  `ls packages/*/skills/*.md 2>/dev/null || true`; read each package
  manifest and `harnessable:` block before using package commands
- `find world_models/ -name "*_world_model.md" | sort`
- Read relevant world model files: `fleet_world_model.md` for cross-service,
  `vendor_world_model.md` for infrastructure, `staging_world_model.md` for
  staging, plus cross-repo pointers from `WORLD_MODEL.md`
- Map every mandate step to an available role. If no role fits, file a
  Protocol Enhancement Request at `docs/mandates/per/PER-{NNN}.md` using
  `docs/harness/templates/per.md`, then mark the step as `[GAP]` in the
  Execution Manifest. If a package skill fits, include the package command
  in the Execution Manifest and cite the `packages/{name}/` adapter path

Produce a DIP that includes:
- Prerequisites copied from the DMT plus the criterion validity audit
  result; file `BLOCKER: BLOCKED_CRITERION` and do not set PLANNED if an
  undeclared pre-existing defect prevents a criterion from passing
- Credential Operations for SRE mandates: declare credential files,
  permitted verify-only operations, and justification; if none, state
  "None - this mandate does not handle credential files"
- Recon findings
- Architecture decisions (ADRs for non-obvious choices)
- Ordered implementation steps
- For multi-role mandates, label every step with its executing type:
  agent roles `[Coder]`, `[SRE]`, `[Security]`, `[QA]`, `[Analyst]`,
  `[Reviewer]`, `[Inspector]`, `[Designer]`; human-executed `[OPERATOR]`;
  browser automation `[PLAYWRIGHT]`
- For `[Designer]` steps, declare exact visual specification values,
  output paths, formats, dimensions, size-specific variations, and CLI
  tool prerequisites; missing values are `DESIGN_AMBIGUITY` blockers
- For `[OPERATOR]` steps, declare action, evidence, completion signal,
  and blocked path
- For `[PLAYWRIGHT]` steps, declare test file, command, pass criteria,
  evidence path, and confirm `AGENTS.md ## Browser Testing`
- Containment checklist per step (Detect / Contain / Recover / Prevent)
- Execution Manifest: ordered `/role docs/mandates/{path}/dip.md` sessions,
  with `[GAP] — PER filed: docs/mandates/per/PER-NNN.md` entries where no
  existing role fits
- Verification Checklists as Rubric Layer 2: `[REQUIRED]` checks QA will
  re-execute alongside DMT Acceptance Criteria and the Completion Gate

Raw labels in the DIP are a protocol violation if the concept is absent
from the knowledge graph. Use namespaced terms only.

Set board status to PLANNED when complete.
