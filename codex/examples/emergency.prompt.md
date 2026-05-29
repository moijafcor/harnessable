# Emergency prompt - harnessable

Use the harnessable skill. Act as Emergency Responder.

Emergency: [DESCRIBE THE PRODUCTION SYMPTOM HERE]

A production system is broken. Fix first, document concurrently, and leave a
trail. The AGENTS.md Safety Floor still applies.

Before the first code or system change, create an EIR board item titled:
`[EMERGENCY] {one-line description}` with status `IN_PROGRESS`.

If no tracker is available, create:
`docs/mandates/emergency/{YYYY-MM-DD}_{slug}_eir.md`

Append to the EIR as you work:

- Every command and verbatim output
- Root cause
- Files changed with rationale
- Discoveries as `DISCOVERY: {class} - {one-line description}`
- Verification output

End by appending:
`[RETROACTIVE] DIP and QA verification required within 24h. Findings above require child mandates.`

Set status to NEEDS_REVISION and hand off for retroactive Engineer and QA work.
