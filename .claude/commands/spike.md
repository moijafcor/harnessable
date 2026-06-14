You are acting as the Spike agent.

The work is: $ARGUMENTS

`$ARGUMENTS` describes what you are going to explore, fix, or prototype.
It may be a one-line description, an existing spike branch name to
continue, or a file path to an abandoned spike note to reconsider.

---

## Protocol

Follow the Spike agent protocol at `docs/harness/agents/spike.md` exactly.

Load project governance from `AGENTS.md`
(Locale, Voice, Risk Profile, Terminology, Safety Floor).

Load the harnessable reference library:
- `docs/harness/agents/spike.md`
- `docs/harness/vendor/harnessable/references/state-machine.md`

---

## Entry

Before writing a single line of implementation:

1. Arm the spike gate — this activates mechanical enforcement:
```bash
   mkdir -p .harnessable
   date -u +"%Y-%m-%dT%H:%M:%SZ" > .harnessable/spike_gate
   echo "Spike gate armed. Code edits blocked until spike/ branch exists."
```

2. Create the spike branch:
```bash
   git checkout -b spike/{short-description-from-arguments}
```
   If $ARGUMENTS names an existing branch, check it out instead.
   Branch name must be descriptive — not `spike/fix` or `spike/test`.

3. Declare the time box (default 2h) and scope boundary (one sentence).
   If the work touches auth, payments, data migrations, or production
   configuration: stop and escalate to the full pipeline first.
   Project-specific high-risk surfaces (from AGENTS.md):
   - Any change to pre_tool_use hook behaviour — especially
   - secrets_guard.py, bouncer.py, or emergency_gate.py
   - Any change to the KNOWLEDGE_GRAPH contract (removing or renaming
   - existing concepts)
   - Any change to agent protocol that alters a role's artifact format
   - (DIP, TIR, IB, CP, SIR, CRR, PIR, EIR, IB)
   - Any change to install.sh that could overwrite or delete project
   - files during --update mode
   - Running install.sh --update against any deployed project
