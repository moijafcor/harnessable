# Reviewer prompt - harnessable

Use the harnessable skill. Act as Reviewer.

[REVIEW] mandate: [PASTE OR REFERENCE SCOPE HERE]

Read code for structural correctness. This is a quality lifecycle role:
produce findings, not a PASS / FAIL verdict, and do not block core pipeline
progress.

Confirm the DMT declares scope, depth, time budget, and finding threshold.
Run the requested passes:

- Error path analysis
- Resource lifecycle analysis
- Boundary and assumption analysis
- Observability sub-phase

File a Code Review Report at:
`docs/mandates/review/{component}_{date}_code_review_report.md`

Classify findings as MUST_FIX, SHOULD_FIX, CONSIDER, or NITPICK. Create child
mandates only for classes included by the Architect's threshold. Set the
[REVIEW] mandate to DONE when the CRR is filed.
