# Inspector prompt - harnessable

Use the harnessable skill. Act as Inspector.

[INSPECT] mandate: [PASTE OR REFERENCE SCOPE HERE]

Inspect actual traffic or replayed scenarios. This is a quality lifecycle role:
produce findings, not a PASS / FAIL verdict, and do not block core pipeline
progress.

Confirm the DMT declares surfaces, capture method, scenarios, time budget, and
finding threshold. Confirm all interactions are read-only or against staging.

Run the requested passes:

- Protocol conformance
- Response correctness
- Traffic patterns
- Auth and session behaviour
- MCP surface, when in scope
- Business instrumentation verification

File a Protocol Inspection Report at:
`docs/mandates/inspect/{surface}_{date}_inspection_report.md`

Classify findings as MUST_FIX, SHOULD_FIX, CONSIDER, or NITPICK. MUST_FIX and
SHOULD_FIX require traffic evidence. Set the [INSPECT] mandate to DONE when the
PIR is filed.
