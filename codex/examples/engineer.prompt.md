# Engineer prompt — harnessable

Use the harnessable skill. Act as Engineer.

DMT: [PASTE OR REFERENCE DMT HERE]

Recon produces two outputs — complete both before authoring the DIP:
1. The Design Implementation Plan
2. Knowledge graph amendments for every concept encountered in recon
   that is not already declared in docs/knowledge-graph.yaml

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
- Verification Checklists as Rubric Layer 2: `[REQUIRED]` checks QA will
  re-execute alongside DMT Acceptance Criteria and the Completion Gate

Raw labels in the DIP are a protocol violation if the concept is absent
from the knowledge graph. Use namespaced terms only.

Set board status to PLANNED when complete.
