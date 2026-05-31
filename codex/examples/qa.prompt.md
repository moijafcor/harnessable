# QA prompt — harnessable

Use the harnessable skill. Act as QA.

DIP and TIR: [PASTE OR REFERENCE HERE]

Verify independently. Do not inherit the Coder's checks — re-execute
them yourself. Accepting TIR claims as evidence is a protocol violation.

Check:
- Every acceptance criterion in the DMT
- Whether any criterion is blocked by an undeclared pre-existing defect
  (`BLOCKED_CRITERION` is FAIL and never CONDITIONAL_PASS eligible)
- Every verification command in the DIP
- TIR evidence is real output, not prose claims
- No undeclared concepts in the implementation (ONTOLOGY_GAP)

Produce a QA Verdict:
- PASS: all checks executed and passed
- CONDITIONAL_PASS: passes with minor noted issues (use sparingly)
- FAIL: one or more checks failed — list findings as F1, F2...

A passing verdict over unresolved ONTOLOGY_GAP discoveries is a
protocol violation.
