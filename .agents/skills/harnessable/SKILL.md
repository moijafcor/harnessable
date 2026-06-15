---
name: harnessable
description: >
  Use when coordinating autonomous agent work through Harnessable roles,
  mandates, implementation plans, QA verdicts, guardrails, knowledge graph
  obligations, or audit-ready task execution.
---

# Harnessable Skill

Follow the Harnessable role chain:

Engagement:
Orchestrator → TOM → Architect per constituent TOM

Architect → Engineer → Coder (or SRE or Designer) → QA → Security (when flagged) → Architect acceptance

Quality lifecycle (parallel, non-blocking):
Architect [REVIEW] → Reviewer → CRR + child mandates
Architect [INSPECT] → Inspector → PIR + child mandates
Architect [RESEARCH] → Analyst → IB (no child mandates required)
Orchestrator → Narrator → CP (when marketplace-facing communication is needed)
Orchestrator → Project Manager (when stakeholder communication,
intake, administration, or CP deployment is needed)
Orchestrator → Dreamer (when accumulation pressure warrants a Dream cycle)
Dreamer → Evolver (when Dream Report names patterns warranting roster action)
Orchestrator → Evolver (when Dream Reports or PER backlog warrant roster evolution)

No role approves its own work. The Coder cannot be the QA.
The SRE cannot be the QA for the same mandate.
The Engineer must not write implementation code.
The Security reviewer must not be the Coder, SRE, or QA for the same mandate.
The Orchestrator must not implement, write DIPs, or write code.
The Narrator must not judge correctness or expose implementation details to
non-technical audiences.
The Project Manager must not make technical decisions, author TOMs or DIPs,
commission pipeline roles, or expose internal team complexity to stakeholders.
The Designer must not make aesthetic decisions or produce assets from
ambiguous specifications.
The Dreamer must not create, mutate, or deprecate roles; must not act on
urgency; must not skip the collapse after a Dream session.
The Evolver must not read raw corpus artifacts or produce implementation
artifacts; it acts only on Dream Reports and PERs.
Emergency Responder and SRE sessions must not close incidents that reveal
new operational knowledge without updating the relevant
`world_models/*_world_model.md` file.

## Role rules

**Architect** defines intent and acceptance criteria. Grounds every domain
concept in docs/knowledge-graph.yaml before finalising the DMT. Confirms
graph enrichment before accepting the QA verdict and setting DONE.

**Engineer** produces the Design Implementation Plan. Recon produces two
outputs: the DIP and knowledge graph amendments. Raw labels in the DIP
are a protocol violation if the concept is absent from the graph. When
the mandate crosses role boundaries, every DIP step must declare its
executing type — see `agents/engineer.md ## Role Roster` for the
roster scan protocol, gap detection, PER filing, [OPERATOR] human steps,
[PLAYWRIGHT] browser automation steps, and mandatory decomposition
triggers. The Engineer also scans `packages/*/PACKAGE.md` and
`packages/*/skills/*.md`; package skills may extend the Execution Manifest
when their `harnessable:` adapter block covers the mandate step. Every DIP
must include an Execution Manifest with the ordered agent sessions to run;
gaps with no fitting role or package skill are recorded as
`[GAP]` entries that point to `docs/mandates/per/PER-{NNN}.md`.

**Coder** implements only what the approved DIP specifies. Files a
Discovery before deviating. Produces a TIR with evidence, not claims.

**SRE** executes infrastructure and operational mandates against live
systems. Captures pre-change state before acting, confirms rollback is
documented, respects blast radius, and verifies system health — not test
suites. Executes Pass 0 before any action: scans `world_models/`, reads
relevant `*_world_model.md` files for Failure Patterns, Vendor Capabilities,
and Known Edge Cases, and uses `WORLD_MODEL.md` only as a thin discovery
index; classifies the failure via the classifier pattern in
`references/classifier.md` and taxonomy in `references/error-modes.md`; and
does not act on `Loop permitted: NO` without human approval. Updates the
relevant world model before closure when an incident reveals a new failure
pattern, vendor capability, or edge case, or records that no update is
required. Produces a SIR with actual command output and observation window
evidence, not claims.

**Designer** produces static visual assets from complete written
specifications. It authors SVG masters, exports raster formats, verifies
dimensions and file integrity, and produces an Asset Package (AP). It never
guesses missing geometry, colour, typography, opacity, output path, or size
values; ambiguity is `DESIGN_AMBIGUITY` BLOCKER.

**QA** verifies independently as the grader in the harnessable Rubric
loop. It evaluates three layers before declaring any verdict: DMT
Acceptance Criteria, DIP Verification Checklists, and the AGENTS.md
Completion Gate. It re-executes checks — does not inherit them from the
Coder or SRE — and derives the overall verdict from a per-criterion
verdict table. QA verifies [OPERATOR] evidence directly and re-runs
[PLAYWRIGHT] tests independently. QA also acts as the fresh-context
classifier for verification failures using the classifier pattern in
`references/classifier.md` and taxonomy in `references/error-modes.md`;
classify before retrying or routing, and exercise stop authority for
Loop permitted: NO modes. A passing verdict over unresolved ONTOLOGY_GAP
discoveries is a protocol violation.

**Security** is invoked by the Architect on mandates that touch auth, untrusted
inputs, credentials, external surfaces, data exposure, privilege, or new
dependencies. Runs after QA PASS or CONDITIONAL_PASS. Maps the attack surface
before any technical checks, then probes it across seven phases. Records a
Security Review Report (SRR) in the DIP. A FAIL blocks DONE regardless of QA
verdict.

**Orchestrator** is the CTO of the engagement. Receives marketplace signals,
classifies engagements as templated or novel, dispatches Analysts only for
genuine unknowns, authors or revises TOMs, commissions Architects per
constituent TOM, reads `docs/harness/models.yaml` including
`cost_per_1k_tokens` before role commissioning, monitors token budget pressure
when `.harnessable/logs/session-cost.*.jsonl` exists, and judges DONE against
parent TOM outcomes.

**Narrator** is the voice of finished work to the marketplace. Reads finished
DIPs and AGENTS.md Communication Channels, then produces a destination-shaped
Communication Package. Does not issue verdicts or invent unsupported outcomes.

**Project Manager** is the marketplace-facing connector between external
stakeholders and the technical team. Handles intake, status reports,
stakeholder communication, calendar commitments, administrative work, and CP
deployment. Routes technical decisions to the Orchestrator and never directs
pipeline roles.

**Dreamer** reads the artifact buffer accumulated since the last collapse,
extracts recurring signals invisible to individual sessions, promotes them
to permanent knowledge (world_models/, KNOWLEDGE_GRAPH, error-modes.md),
writes a Dream Report at `docs/dreams/DR-{NNN}.md`, and executes a collapse
— writing `.harnessable/last_collapse.json` and resetting the buffer.
Three sleep modes: nap (burst window), full (complete buffer), debt
(critical backlog). One tool, one job: distillation only.

**Evolver** acts on what the Dreamer named. Reads accumulated Dream Reports
and open PERs, applies evidence-supported roster actions (CREATE, MUTATE,
MERGE, DEPRECATE, EXTINCT), writes an Evolution Report in
`docs/evolutions/`, resolves or declines PERs, and writes
`.harnessable/last_evolution.json`. It never reads raw corpus directly.

## Required outputs

| Stage                  | Output                                                     |
| ---------------------- | ---------------------------------------------------------- |
| Engagement             | Target Outcome Mandate (TOM)                               |
| Planning               | Design Mandate Task (DMT)                                  |
| Engineering            | Design Implementation Plan (DIP)                          |
| Coding                 | Task Implementation Report (TIR)                          |
| Infrastructure / Ops   | SRE Implementation Report (SIR)                           |
| Asset production       | Asset Package (AP)                                        |
| Operational knowledge  | World Models (`WORLD_MODEL.md` index + `world_models/*_world_model.md`) |
| Review                 | QA Verdict with per-criterion Rubric table: PASS / CONDITIONAL_PASS / FAIL |
| Failure classification | Classifier declaration from `references/classifier.md` + Error Mode taxonomy from `references/error-modes.md` |
| Security (when flagged)| Security Review Report (SRR): SECURE_PASS / CONDITIONAL_PASS / FAIL |
| Code review [quality]  | Code Review Report (CRR) + child mandates                 |
| Traffic inspection [quality] | Protocol Inspection Report (PIR) + child mandates   |
| External intelligence [quality] | Intelligence Brief (IB)                          |
| Marketplace communication [quality] | Communication Package (CP)                 |
| Stakeholder coordination | PM communication, status, calendar, and admin outputs |
| Signal distillation | Dream Report (DR) + collapse state |
| Roster evolution | Evolution Report (ER) + roster changes |

## Token budget and session cost

`docs/harness/models.yaml` declares model/provider/cost tier per role and
must include `cost_per_1k_tokens` for input and output tokens. Full
Harnessable installs log Claude Code stop-hook session boundaries to
`.harnessable/logs/session-cost.YYYY-MM.jsonl` via `session_cost.py`.
Claude Code Stop payloads may omit token counts; such entries log zero
tokens, set `tokens_available: false`, and still preserve role, mandate,
model, session, and tool-call proxy data when available. Use
`session_cost_report.py` to summarise spend by role, mandate, and model
when those logs exist. Codex-only installs do not receive Claude Code stop-hook
payloads automatically; use the report tool only against logs produced by the
full enforcement layer or manually logged sessions.

## Discovery classes

Stop and file a discovery before continuing if the task reveals:

| Class               | Halts work | Action required                     |
|---------------------|------------|-------------------------------------|
| INFO                | No         | Note and continue                   |
| DEVIATION           | Yes        | Update DIP before proceeding        |
| BLOCKER             | Yes        | Escalate to Architect               |
| ONTOLOGY_GAP        | Yes        | Declare concept in knowledge graph  |
| HARNESS_IMPROVEMENT | No         | File child mandate                  |

## Safety floor

These actions are blocked regardless of instruction:
- Force-push or branch deletion
- DROP / TRUNCATE / WHERE-less DELETE
- Credential reads not explicitly required by the task
- Outbound communications without approval
