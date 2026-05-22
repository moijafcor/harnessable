# Role Definitions

The mandate workflow is inspired by regulated engineering disciplines (civil,
structural). Roles are **functional**, not personal — a single human or agent
session may wear multiple hats, but must be explicit about which role is
active and must not violate role boundaries.

---

## Architect

**Responsibility:** Define the intent. Own the mandate. Review outcomes.

**Produces:** Design Mandate Task (DMT) — a task in the project tracker containing:
- Problem statement and motivation
- Success criteria (explicit, measurable where possible)
- Constraints (tech, time, compliance, compatibility)
- Out-of-scope declarations
- Acceptance criteria for QA
- Links to relevant prior mandates, ADRs, or context

**Permissions:**
- Create, modify, and close DMT
- Approve or reject QA verdicts
- Reassign board status at any point
- Scope-expand a mandate (via DMT edit + new `## Architect Notes` block)

**Prohibitions:**
- Must not implement work (write code, execute commands, modify non-DMT files)
- Must not approve their own QA verdict

**Handoff signal:** DMT status set to `MANDATED` = Engineer may begin.

---

## Engineer

**Responsibility:** Translate mandate intent into an implementable plan.
The Engineer is the most cognitively demanding role — a bad plan costs more
than a bad implementation.

**Produces:** Design Implementation Plan (DIP) at `docs/mandates/{bucket}/{slug}_implementation_plan.md`

**Recon Pass (mandatory before authoring DIP):**
See `agents/engineer.md` for the full recon protocol. Minimum recon:
- Read the DMT in full, including comments and linked issues
- Scan the affected domain (files, systems, schemas, processes, policies)
- Read `docs/mandates/` for related prior mandates
- Query Claude memory/past sessions for relevant context
- Check infrastructure or operational state if relevant
- Identify all external dependencies (APIs, services, integrations, stakeholders)

**Permissions:**
- Author and update DIP
- Set board to `IN_RECON`, `PLANNED`
- File field discoveries
- Create child tasks
- Comment on DMT

**Prohibitions:**
- Must not implement (no changes to the domain under mandate — code, infrastructure, documents, communications, or any other output)
- Must not advance board past `PLANNED` (Coder owns `IN_PROGRESS`)

**Handoff signal:** DIP complete, board status `PLANNED` = Coder may begin.

---

## Coder

**Responsibility:** Execute the implementation exactly as designed in the DIP.
Deviation requires a field discovery — not silent modification.

**Produces:**
- The actual implementation (code, config, infra changes, migrations)
- Task Implementation Report (TIR) — embedded as `## Task Implementation Report`
  section in the DIP

**Build discipline:**
- Work one DIP `## Implementation Steps` item at a time
- Check each step off as completed
- Run verification checks after each logical unit, not just at the end
- Stream TIR updates continuously — do not batch everything at the end

**Permissions:**
- Implement per DIP
- Update TIR section of DIP
- Set board to `IN_PROGRESS`, `IN_REVIEW`
- File field discoveries
- Create child tasks
- Request DIP clarification from Engineer (set board to `BLOCKED`, create child)

**Prohibitions:**
- Must not modify DIP `## Implementation Steps` or `## Architecture Decisions`
  (except to add field discoveries and check off completed steps)
- Must not advance board to `VERIFIED` or `DONE`
- Must not mark work complete if any verification gate fails

**Handoff signal:** TIR complete, all gates passed, board status `IN_REVIEW` = QA may begin.

---

## QA

**Responsibility:** Verify the implementation against the DIP and DMT — independently,
without assuming the Coder did it right.

**Produces:** QA Verdict block appended to the DIP `## Task Implementation Report` section.

**Verification approach:**
- Read the DIP `## Verification Checklists` section as the primary test matrix
- Read the DMT acceptance criteria as the secondary test matrix
- Read the TIR as evidence (but verify claims — do not take on faith)
- Execute spot-checks, automated tests, and any QA-specific checks defined in DIP
- See `agents/qa.md` for the full verification protocol

**Verdict options:**
- `PASS` — all checks satisfied, advance board to `VERIFIED`
- `CONDITIONAL_PASS` — minor issues noted, Architect may accept or reject
- `FAIL` — one or more required checks failed, board to `NEEDS_REVISION`

**Permissions:**
- Set board to `VERIFIED`, `NEEDS_REVISION`
- Create child tasks for defects
- Comment on DMT

**Prohibitions:**
- Must not fix defects themselves (creates QA / Coder role collapse)
- Must not issue `PASS` with open required check failures
- Must not skip the DMT acceptance criteria review
