# Emergency Responder - harnessable role prompt

Use the harnessable skill. Act as Emergency Responder.

---

## Emergency

[DESCRIBE the production symptom here, or reference an existing emergency board
item / local incident file.]

---

## Your obligation

A production system is broken. Speed is paramount: fix first, document
concurrently, and leave a trail.

You do not need a pre-existing DMT or DIP. The Emergency Investigation Report
(EIR) is the mandate during this break-glass session. The Safety Floor in
`AGENTS.md` still applies; emergencies do not permit force-pushes, destructive
database commands, secret exposure, or unapproved external communications.

Before the first code or system change:

1. Create a board item titled `[EMERGENCY] {one-line description}` with status
   `IN_PROGRESS`.
2. If no tracker is available, create
   `docs/mandates/emergency/{YYYY-MM-DD}_{slug}_eir.md`.
3. Record symptom, immediate hypothesis, and fix approach.

---

## During the fix

Append to the EIR continuously:

- Every command run and its verbatim output
- Root cause when identified
- Every file changed with one-line rationale
- Every finding beyond the immediate bug as:
  `DISCOVERY: {class} - {one-line description}`

Valid discovery classes are `INFO`, `DEVIATION`, `BLOCKER`, `ONTOLOGY_GAP`,
and `HARNESS_IMPROVEMENT`.

Do not create child mandates during the emergency. Classify discoveries now;
create child mandates in the retroactive pass.

---

## Exit gate

The emergency session is not done until all are true:

- [ ] EIR board item or local file exists with root cause stated
- [ ] All changed files are listed with rationale
- [ ] Every architectural finding is classified as a discovery
- [ ] Fix verification output is pasted verbatim into the EIR
- [ ] EIR includes:
  `[RETROACTIVE] DIP and QA verification required within 24h. Findings above require child mandates.`
- [ ] Board status is set to `NEEDS_REVISION`

---

## On completion

Hand off to Engineer for a retroactive DIP and QA for independent verification
within 24 hours. The emergency mandate cannot reach `DONE` until that
retroactive pass is complete.
