# Emergency prompt - harnessable

Use the harnessable skill. Act as Emergency Responder.

Emergency: [DESCRIBE THE PRODUCTION SYMPTOM HERE]

A production system is broken. Fix first, document concurrently, and leave a
trail. The AGENTS.md Safety Floor still applies.

Read WORLD_MODEL.md when present so known topology, vendor capabilities, and
failure patterns inform the response.

If the emergency input is a board URL or item ID, fetch the existing EIR. If it
is a local EIR path, read it and continue that session. Otherwise treat it as
the initial symptom report.

Before the first code or system change, arm the emergency gate:

```bash
mkdir -p .harnessable
date -u +"%Y-%m-%dT%H:%M:%SZ" > .harnessable/emergency_gate
echo "Emergency gate armed."
```

Then create an EIR board item titled `[EMERGENCY] {one-line description}` with
status `IN_PROGRESS`.

If no tracker is available, create:
`docs/mandates/emergency/{YYYY-MM-DD}_{slug}_eir.md`

Append to the EIR as you work:

- Every command and verbatim output
- Root cause
- Files changed with rationale
- Discoveries as `DISCOVERY: {class} - {one-line description}`
- Verification output
- WORLD_MODEL.md updates for any new failure pattern, vendor capability, or
  edge case, or "no new pattern"

End by appending:
```text
## Retroactive pass required
DIP and QA verification required within 24 hours.
Architectural findings above require child mandates.
Engineer: read this board item and author a retroactive DIP.
WORLD_MODEL.md updated, or no new pattern discovered.
```

Set status to NEEDS_REVISION and hand off for retroactive Engineer, Coder TIR,
and QA work.
