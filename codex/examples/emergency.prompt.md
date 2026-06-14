# Emergency prompt - harnessable

Use the harnessable skill. Act as Emergency Responder.

Emergency: [DESCRIBE THE PRODUCTION SYMPTOM HERE]

A production system is broken. Fix first, document concurrently, and leave a
trail. The AGENTS.md Safety Floor still applies.

Use WORLD_MODEL.md as the thin discovery index. Discover relevant
world models with `find world_models/ -name "*_world_model.md" | sort`,
then read the applicable files so known topology, vendor capabilities, and
failure patterns inform the response.

When a fix attempt fails, use classifier.md and error-modes.md when present:
classify before retrying, honour `Loop permitted: NO`, and package
below-horizon symptoms with the access needed to proceed.

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
- world_models/ updates for any new failure pattern, vendor capability, or
  edge case, or "no new pattern"
- Knowledge Extracted: YES (full pattern encoded in the relevant
  `world_models/{domain}_world_model.md` file with commit SHA, incident
  record filed) or NO (explicit declaration:
  "No new patterns discovered. world_models/ does not require update.")

End by appending:
```text
## Retroactive pass required
DIP and QA verification required within 24 hours.
Architectural findings above require child mandates.
Engineer: read this board item and author a retroactive DIP.
world_models/ updated, or no new pattern discovered.
```

Set status to NEEDS_REVISION and hand off for retroactive Engineer, Coder TIR,
and QA work.
