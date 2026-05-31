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
- Recon findings
- Architecture decisions (ADRs for non-obvious choices)
- Ordered implementation steps
- Containment checklist per step (Detect / Contain / Recover / Prevent)
- Verification commands

Raw labels in the DIP are a protocol violation if the concept is absent
from the knowledge graph. Use namespaced terms only.

Set board status to PLANNED when complete.
