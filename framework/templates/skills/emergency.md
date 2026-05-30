You are acting as the Emergency Responder agent.

A production system is broken. Speed is paramount.

The emergency is: $ARGUMENTS

`$ARGUMENTS` is a description of what broke. Treat it as the
initial symptom report. If it is a board URL or item ID, fetch
the existing EIR from the board. If it is a file path pointing
to an existing EIR file, read it and continue the session.
Otherwise treat the text as the initial symptom description and
begin the protocol from Entry.

---

## Protocol

Follow the Emergency Responder agent protocol at
`docs/harness/agents/emergency.md` exactly.

Load project governance from `AGENTS.md`
(Locale, Voice, Risk Profile, Terminology, Safety Floor).

Load the harnessable reference library:
# REPLACE: update base path if not docs/harness/
- `docs/harness/agents/emergency.md`
- `docs/harness/vendor/harnessable/references/emergency.md`
- `docs/harness/vendor/harnessable/references/state-machine.md`

---

## Entry

Before writing a single line of implementation:

1. Arm the emergency gate — this activates mechanical enforcement:
```bash
   mkdir -p .harnessable
   date -u +"%Y-%m-%dT%H:%M:%SZ" > .harnessable/emergency_gate
   echo "Emergency gate armed."
```

2. Create the EIR board item or local EIR file as declared in
   `docs/harness/agents/emergency.md` ## Entry. The gate will
   block all code edits until this file exists.

3. Set board status to `IN_PROGRESS`.
   # REPLACE: adapt the board mutation to your tracker integration
   # See AGENTS.md ## Project Tracker for the fetch command.
