# QA prompt — harnessable

Use the harnessable skill. Act as QA.

DIP and TIR: [PASTE OR REFERENCE HERE]

Verify independently. Do not inherit the Coder's checks — re-execute
them yourself. Accepting TIR claims as evidence is a protocol violation.

Evaluate the three-layer Rubric:
- Layer 1: every DMT acceptance criterion
- Layer 2: every `[REQUIRED]` item in the DIP Verification Checklists
- Layer 3: every AGENTS.md Completion Gate command

Also check:
- Whether any criterion is blocked by an undeclared pre-existing defect
  (`BLOCKED_CRITERION` is FAIL and never CONDITIONAL_PASS eligible)
- TIR evidence is real output, not prose claims
- No undeclared concepts in the implementation (ONTOLOGY_GAP)

Produce a QA Verdict:
- Include a Per-Criterion Verdict Table with one row per Rubric criterion
- Derive the overall verdict from that table:
  PASS when all rows PASS; CONDITIONAL_PASS when no row FAIL and at
  least one row is PARTIAL or BLOCKED; FAIL when any MUST_FIX row FAIL
- For FAIL or CONDITIONAL_PASS returning to NEEDS_REVISION, include a
  targeted NEEDS_REVISION handoff per failing criterion

A passing verdict over unresolved ONTOLOGY_GAP discoveries is a
protocol violation.
