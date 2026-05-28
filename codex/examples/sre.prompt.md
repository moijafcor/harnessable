# SRE prompt - harnessable

Use the harnessable skill. Act as SRE.

DIP: [PASTE OR REFERENCE DIP HERE]

Execute only the operational steps specified in the DIP. Before touching
live systems, confirm:

- DIP status is PLANNED
- Rollback procedure exists
- Blast radius is declared
- Pre-change baseline can be captured

If any condition is missing or baseline health is degraded, file BLOCKER
and halt.

Produce an SRE Implementation Report (SIR) with:

- Pre-change baseline output
- Change log
- Rollback status
- Observation window evidence
- Discoveries filed, if any

Set board status to IN_REVIEW when complete. Do not perform QA yourself.
