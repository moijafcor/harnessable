# Board State Machine

## Status Definitions

| Status | Meaning | Who sets it |
|---|---|---|
| `BACKLOG` | Not yet actionable; awaiting Architect prioritization | Architect / any (for child tasks) |
| `MANDATED` | DMT is complete and approved for execution | Architect |
| `IN_RECON` | Engineer is running discovery and recon passes | Engineer |
| `PLANNED` | DIP is complete; ready for Coder | Engineer |
| `IN_PROGRESS` | Coder is actively implementing | Coder |
| `IN_REVIEW` | Implementation complete; awaiting QA | Coder |
| `BLOCKED` | Work halted; requires Architect or external resolution | Any |
| `NEEDS_REVISION` | QA verdict was FAIL; Coder must address findings | QA |
| `VERIFIED` | QA verdict was PASS or CONDITIONAL_PASS | QA |
| `DONE` | Architect accepted QA verdict; mandate closed | Architect |

---

## Legal Transitions

```
BACKLOG         → MANDATED         (Architect prioritises)
MANDATED        → IN_RECON         (Engineer begins recon)
IN_RECON        → PLANNED          (Engineer completes DIP)
IN_RECON        → BLOCKED          (Architect input required before plan can be written)
PLANNED         → IN_PROGRESS      (Coder begins implementation)
PLANNED         → IN_RECON         (Engineer must revise DIP — e.g., scope clarification needed)
IN_PROGRESS     → IN_REVIEW        (Coder complete, all gates passed)
IN_PROGRESS     → BLOCKED          (Blocker field discovery; child task created)
IN_REVIEW       → VERIFIED         (QA: PASS or CONDITIONAL_PASS)
IN_REVIEW       → NEEDS_REVISION   (QA: FAIL)
NEEDS_REVISION  → IN_PROGRESS      (Coder resumes after addressing QA findings)
NEEDS_REVISION  → IN_RECON         (Findings require DIP revision before reimplementation)
BLOCKED         → [prior status]   (Blocker resolved; Architect unblocks)
VERIFIED        → DONE             (Architect accepts)
VERIFIED        → NEEDS_REVISION   (Architect rejects despite QA pass — rare)
```

## Illegal Transitions (invariants)

These must never occur. If an agent is tempted to make one, stop and raise a BLOCKER.

```
MANDATED        → IN_PROGRESS      (no DIP = no implementation)
MANDATED        → DONE             (skipping all execution)
PLANNED         → IN_REVIEW        (no TIR = no QA)
PLANNED         → VERIFIED         (skipping implementation and QA)
IN_PROGRESS     → DONE             (skipping QA)
IN_PROGRESS     → VERIFIED         (self-QA is prohibited)
ANY             → DONE             (only Architect closes)
```

---

## State Invariants

These conditions must hold at all times:

1. **DIP-before-code:** A DMT in `IN_PROGRESS` or later MUST have a corresponding DIP file.
2. **TIR-before-QA:** A DMT in `IN_REVIEW` MUST have a `## Task Implementation Report` section in its DIP.
3. **No self-QA:** The agent that set status to `IN_REVIEW` must not also set `VERIFIED`.
4. **BLOCKER accountability:** A DMT in `BLOCKED` must have a child task or DIP entry explaining the reason.
5. **Gate enforcement:** Transition to `IN_REVIEW` requires all DIP verification checklist items checked.
6. **Closed mandates are immutable:** A DMT in `DONE` must not have its DIP modified (append-only via `## Post-Close Notes`).

---

## State Diagram (ASCII)

```
                    ┌──────────┐
                    │ BACKLOG  │
                    └────┬─────┘
                         │ Architect
                    ┌────▼─────┐
                    │ MANDATED │
                    └────┬─────┘
                         │ Engineer
                   ┌─────▼──────┐
          ┌────────│  IN_RECON  │◄─────────────────┐
          │        └─────┬──────┘                  │
          │              │ Engineer (DIP complete)  │
          │        ┌─────▼──────┐                  │
          │        │  PLANNED   │──────────────────►│ (revision needed)
          │        └─────┬──────┘
          │              │ Coder
          │       ┌──────▼───────┐
          │  ┌────│ IN_PROGRESS  │◄─────────────────┐
          │  │    └──────┬───────┘                  │
          │  │           │ Coder (all gates pass)    │
          │  │    ┌──────▼───────┐                  │
          │  │    │  IN_REVIEW   │                  │
          │  │    └──┬──────┬────┘                  │
          │  │  PASS │      │ FAIL                  │
          │  │  ┌────▼──┐ ┌─▼────────────┐          │
          │  │  │VERIF. │ │NEEDS_REVISION│──────────┘
          │  │  └───┬───┘ └─────────────┘
          │  │      │ Architect
          │  │  ┌───▼───┐
          │  │  │ DONE  │
          │  │  └───────┘
          │  │
          └──┴──►BLOCKED◄──── (any state, any role)
                    │
                    └────────► [prior status] (Architect unblocks)
```
