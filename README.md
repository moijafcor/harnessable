# Harnessable

**Harness Engineering** is the practice of designing the operating environment for an AI agent, including context, tools, permissions, enforcement, verification, and observability.

This repository is the operational governance layer for autonomous agents doing high-stakes production work: ten roles across four tracks, a structured artifact chain, a state machine, a deployable enforcement layer, context-continuity hooks, and a recursive self-improvement loop that governs the framework by governing itself. Runtime-agnostic — reference implementation for Claude Code, Codex adapter included.

All framework concepts — roles, artifacts, enumerations, and their relationships — are defined in [KNOWLEDGE_GRAPH.yaml](framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml).

---

## Contents

- [Problem Statement](#problem-statement)
- [What This Is Not](#what-this-is-not)
- [The Harness Engineering Manifesto](#the-harness-engineering-manifesto)
- [The Framework](#the-framework)
  - [Roles](#roles)
  - [The Artifact Chain](#the-artifact-chain)
  - [The State Machine](#the-state-machine)
  - [Harness Layers](#harness-layers)
  - [Guards in Action](#guards-in-action)
- [Repository Structure](#repository-structure)
- [Key Concepts](#key-concepts)
  - [Why outcomes, not operations](#why-outcomes-not-operations)
  - [Target Outcome Mandate (TOM)](#target-outcome-mandate-tom)
  - [Knowledge Graph](#knowledge-graph)
  - [Context Continuity](#context-continuity)
  - [Recursive Self-Improvement](#recursive-self-improvement)
  - [Quality Lifecycle](#quality-lifecycle)
  - [Analyst](#analyst)
  - [Field Discoveries](#field-discoveries)
  - [Containment Checklist](#containment-checklist)
  - [Continuous Improvement](#continuous-improvement)
  - [Governed Credential Operations](#governed-credential-operations)
  - [Spike](#spike)
- [Core Principles](#core-principles)
- [Getting Started](#getting-started)
  - [1. Set up your project tracker](#1-set-up-your-project-tracker)
  - [2. Install the framework](#2-install-the-framework)
  - [2a. After install: configure skills](#2a-after-install-configure-skills)
  - [2b. Verify the enforcement layer](#2b-verify-the-enforcement-layer)
  - [2c. Seed the project knowledge graph](#2c-seed-the-project-knowledge-graph)
  - [3. Load agent context at session start](#3-load-agent-context-at-session-start)
  - [4. Create your first DMT](#4-create-your-first-dmt)
  - [5. Run the workflow](#5-run-the-workflow)
- [Codex compatibility](#codex-compatibility)
- [Anti-Patterns](#anti-patterns)
- [Engineering Model](#engineering-model)
- [Influences & Acknowledgements](#influences--acknowledgements)
- [Licence](#licence)

---

## Problem Statement

Prompt instructions are advisory unless backed by enforcement. Models are probabilistic, and long workflows compound errors.

A 95%-accurate model running a 20-step workflow succeeds **36% of the time** (0.95²⁰ = 0.358). That figure assumes each step fails independently — which is optimistic. In practice, a wrong decision in step 3 corrupts the state that step 4 operates on, making downstream failures more likely, not equally likely. The real number is lower.

Reliability requires controls around the model, not only model selection or prompt design.

```text
Agent = Model + Context + Tools + Enforcement + Verification + Observability
```

A model without operational controls is difficult to validate, audit, and recover. A constrained, verified, observable agent can be operated as part of any high-stakes workflow.

---

## What This Is Not

- Not a framework for one-shot prompts or chat assistants
- Not a general AI application toolkit — it is specifically for teams operating autonomous agents in environments where actions have real consequences
- Not model-specific — the reference implementation uses Claude Code hooks, but the protocols and enforcement architecture apply to any autonomous agent runtime that supports lifecycle hooks or pre-execution guards

---

## The Harness Engineering Manifesto

In production environments where agent actions have real-world consequences, we treat AI agents as regulated systems rather than probabilistic experiments. We define this discipline as **Harness Engineering**.

### The Core Principle

We operate on the fundamental equation:

> **Agent = Model + Harness**

- **The Model** is the black-box engine providing raw reasoning capability.
- **The Harness** is the **operational infrastructure** — the environment that constrains, validates, and governs the model. The [Problem Statement](#problem-statement) expands the Harness into its component layers: Context, Tools, Enforcement, Verification, and Observability.

### From "Vibe Coding" to Systems Engineering

Traditional agent development often falls into the trap of "vibe coding" — repeatedly refining prompts in hopes of achieving deterministic results. **Harness Engineering** rejects this in favour of structural control:

1. **Guides (Feed-Forward):** Strict architectural constraints — capability allow-lists, rigid file-system boundaries, and context-injection protocols — define the agent's lane before it acts.
2. **Sensors (Feedback):** Post-action validation — automated testing, static analysis, and loop detection — enforces correctness after it acts. If an agent fails, we do not simply tweak the prompt; we harden the infrastructure.
3. **Observability:** Every action taken by the model must be audit-ready. The harness provides the logs and state persistence necessary to debug failures as structural gaps rather than random noise.

### Why `harnessable`?

`harnessable` is the realisation of this manifesto. It provides the toolset to build, test, and enforce these structural boundaries, moving AI projects out of the experimental phase and into professional, production-ready software architecture.

---

## The Framework

### Roles

Roles are **functional**, not personal. One human or one agent session may perform multiple roles, but the active role must be explicit and role boundaries must be preserved.

**Core Pipeline roles** — gate-based, sequential, each role blocks the next stage:

| Role | Responsibility | Produces | Track |
| --- | --- | --- | --- |
| **Architect** | Define intent. Own the mandate. Review outcomes. | Design Mandate Task (DMT) | Core |
| **Engineer** | Translate intent into an implementable plan. | Design Implementation Plan (DIP) | Core |
| **Coder** | Execute code mandates exactly as designed. | Task Implementation Report (TIR) | Core |
| **SRE** | Execute infrastructure and operational mandates against live systems. | SRE Implementation Report (SIR) | Core |
| **QA** | Verify independently. Treat implementation claims as unverified until checked. | QA Verdict | Core |
| **Security** | Adversarial review on Architect-flagged mandates. Map the attack surface; probe for exploitable paths. | Security Review Report (SRR) | Core |

**Quality Lifecycle roles** — asynchronous, investment-based, produce findings not verdicts:

| Role | Responsibility | Produces | Track |
| --- | --- | --- | --- |
| **Reviewer** | Read code for structural correctness. | Code Review Report (CRR) | Quality |
| **Inspector** | Examine traffic for protocol correctness. | Protocol Inspection Report (PIR) | Quality |
| **Analyst** | Gather intelligence from the world outside the codebase. Synthesise competitor moves, user pain, practitioner discourse, and technology shifts into patterns the Architect can act on. | Intelligence Brief (IB) | Quality |

**Lightweight Track roles** — time-boxed, branch-first, outside the full pipeline:

| Role | Responsibility | Produces | Track |
| --- | --- | --- | --- |
| **Spike** | Explore, prototype, or micro-fix within a declared scope and time box. Branch-first; exits by PR or abandonment note. | Spike Branch (PR or abandonment note) | Lightweight |

**Break-glass roles** — invoked outside the normal pipeline when a live system is failing:

| Role | Responsibility | Produces | Track |
| --- | --- | --- | --- |
| **Emergency Responder** | Fix a production incident. Create the EIR before the first change. Document concurrent. Hand off to retroactive Engineer + QA. | Emergency Investigation Report (EIR) | Break-glass |

No role approves its own work. The Coder cannot be the QA. The SRE cannot be the QA for the same mandate. The Engineer must not write code. The Security reviewer must not be the Coder, SRE, or QA for the same mandate. The Emergency Responder cannot self-QA the retroactive pass.

---

### The Artifact Chain

```text
Architect creates DMT
    │
    │  Problem statement, constraints, and acceptance criteria.
    ▼
Engineer authors DIP
    │
    │  Recon findings, architecture decisions, ordered steps,
    │  verification checklists, and containment plan.
    ├─ code mandate ──────────────────────────────────────────┐
    │  Coder implements + streams TIR                         │
    │  Completed work with evidence: verification output,     │
    │  deviations filed, and gates checked.                   │
    │                                                         │
    └─ infrastructure mandate ───────────────────────────────►┤
       SRE executes + streams SIR                             │
       Pre-change baseline, change log, observation window,   │
       rollback status.                                       │
                                                              ▼
                                               QA verifies + issues verdict
                                                   │
                                                   │  Independently executed checks and verdict:
                                                   │  PASS / CONDITIONAL_PASS / FAIL.
                                                   ▼
                                       Security review (when Architect flagged mandate)
                                                   │
                                                   │  Adversarial review: threat surface map,
                                                   │  auth/authz, injection, secrets, supply chain.
                                                   │  SECURE_PASS / CONDITIONAL_PASS / FAIL.
                                                   ▼
                                               Architect accepts → DONE
```

Artifacts are append-only after their stage closes. A closed mandate's DIP is immutable except for `## Post-Close Notes`.

The quality lifecycle produces parallel artifacts outside this chain: CRR (Code Review Report) and PIR (Protocol Inspection Report). These feed back into the pipeline as child mandates at BACKLOG.

---

### The State Machine

Core pipeline (Track 1 — gate-based):

```text
BACKLOG → MANDATED → IN_RECON → PLANNED → IN_PROGRESS → IN_REVIEW → VERIFIED → DONE
                                                              ↕
                                                           BLOCKED
                                                              ↕
                                                        NEEDS_REVISION
```

Quality lifecycle (Track 2 — asynchronous):

```text
BACKLOG → MANDATED → IN_PROGRESS → DONE
                          ↕
                       BLOCKED (Inspector only)
```

Every transition has a defined owner, a trigger condition, and invariants that must hold. Illegal jumps (e.g. `PLANNED → IN_REVIEW` with no implementation) are protocol violations that any agent must refuse.

Full transition table and invariants: [framework/vendor/harnessable/references/state-machine.md](framework/vendor/harnessable/references/state-machine.md)

---

### Harness Layers

```text
User Request
      │
      ▼
Context Layer      ← AGENTS.md: project rules, allowed/blocked actions, completion gate
      │
      ▼
Tool Layer         ← controlled tools with schemas, validation, audit logging
      │
      ▼
Enforcement Layer  ← PreToolUse: seven guards block before execution
      │                 bouncer.py          AGENTS.md ## Blocked policy
      │                 secrets_guard.py    credential reads, exfiltration, and governed exemptions
      │                 database_guard.py   DROP / TRUNCATE / WHERE-less DELETE
      │                 git_guard.py        force push / hard reset / branch destruction
      │                 communication_guard.py  email / Slack / SMS without approval
      │                 emergency_gate.py   code edits blocked until EIR exists
      │                 spike_gate.py       Write/Edit blocked until on spike/ branch
      │               PostToolUse: audit_logger.py records every tool call
      ▼
Execution
      │
      ▼
Verification Layer ← Stop: completion_gate.py (completion gate before turn completes)
      │               credential_ops_cleanup.py  removes session-scoped credential exemption
      │               emergency_cleanup.py  removes emergency_gate at session end
      │               spike_cleanup.py  removes spike_gate at session end
      │             Independent QA, automated checks, evidence required
      ▼
Approved Output
```

Prompts live in the Context Layer. They are useful but not enforceable. Enforcement lives in hooks and gates that run regardless of what the model decides. The `hooks/` directory makes the Enforcement Layer operational — copy it into your project and wire it via `.claude/settings.json`.

### Guards in Action

The pre-built guards ship ready to use. Each shows the difference between advisory and enforced:

**database_guard.py — intent detection, not keyword blocking**

```text
Agent proposes:  psql -c "DELETE FROM users"
Guard blocks:    DELETE without a WHERE clause would delete every row.
                 Add WHERE or have a human run it directly.

Agent proposes:  psql -c "DELETE FROM users WHERE last_login < '2020-01-01'"
Guard allows:    ✓
```

**git_guard.py — history protection with a safe alternative**

```text
Agent proposes:  git push origin main --force
Guard blocks:    Rewrites shared remote history; destroys others' commits.
                 Use --force-with-lease or have a human approve.

Agent proposes:  git push origin main --force-with-lease
Guard allows:    ✓
```

**communication_guard.py — the chief-of-staff case**

```text
Agent proposes:  curl -X POST https://api.sendgrid.com/v3/mail/send -d '{...}'
Guard blocks:    All outbound email must be reviewed and approved by a human
                 before sending. Draft the message and present it for review.

Agent proposes:  [presents draft to human for approval]
Human approves:  human runs the send command directly  ✓
```

In every case the agent receives a specific, actionable reason — not a generic failure — so it can propose a corrected approach immediately.

---

## Repository Structure

```text
harnessable/
│
├── framework/                     One-command install: cp -r framework/ docs/harness/
│   │
│   ├── agents/                    Tier 1 (copy and own) — role-specific agent protocols
│   │   ├── architect.md           Intent ownership, DMT authoring, mandate closure discipline
│   │   ├── engineer.md            Recon passes, DIP authoring standards, sub-agent delegation
│   │   ├── coder.md               Build discipline, pre-completion hook runner, exit gate
│   │   ├── sre.md                 Pre-change capture, blast radius, incident response, SIR
│   │   ├── qa.md                  Adversarial verification protocol, verdict criteria
│   │   ├── security.md            Threat surface mapping, adversarial security review, SRR
│   │   ├── reviewer.md            Code review protocol, CRR authoring, finding classification
│   │   ├── inspector.md           Protocol inspection, PIR authoring, traffic analysis
│   │   ├── analyst.md             External intelligence gathering, IB authoring, signal classification
│   │   ├── spike.md               Branch-first micro-mandate: time box, scope, Ship/Abandon exits
│   │   └── emergency.md           Break-glass protocol: fix first, document concurrent, EIR
│   │
│   ├── hooks/                     Tier 1 (copy and own) — Enforcement Layer
│   │   ├── run.py                 Universal dispatcher: discovers and runs *.py scripts per event
│   │   ├── pre_tool_use/          Scripts run on PreToolUse (add files here to extend)
│   │   │   ├── bouncer.py         Blocks commands matching AGENTS.md ## Blocked (policy-driven)
│   │   │   ├── secrets_guard.py   Hardcoded floor: blocks credential reads and exfiltration; allows SRE verify-only exemptions
│   │   │   ├── database_guard.py  Blocks DROP, TRUNCATE, and WHERE-less DELETE/UPDATE
│   │   │   ├── git_guard.py       Blocks force push, hard reset, branch and history destruction
│   │   │   ├── communication_guard.py  Blocks unauthorized email, Slack, SMS, and calendar writes
│   │   │   ├── emergency_gate.py  Blocks code edits until EIR exists when emergency gate is armed
│   │   │   └── spike_gate.py      Blocks Write/Edit until on a spike/ branch when spike gate is armed
│   │   ├── post_tool_use/         Scripts run on PostToolUse (add files here to extend)
│   │   │   └── audit_logger.py    Appends every tool call to .harnessable/logs/audit.YYYY-MM-DD.jsonl
│   │   ├── stop/                  Scripts run on Stop (add files here to extend)
│   │   │   ├── completion_gate.py Runs AGENTS.md ## Completion Gate commands; blocks if any fail
│   │   │   ├── credential_ops_cleanup.py  Removes .harnessable/credential_ops.json at session end
│   │   │   ├── emergency_cleanup.py  Removes .harnessable/emergency_gate at session end
│   │   │   └── spike_cleanup.py   Removes .harnessable/spike_gate at session end
│   │   └── claude_code_settings_template.json  Drop-in .claude/settings.json — all events wired through run.py
│   │
│   ├── templates/                 Tier 1 (copy and own)
│   │   └── dip.md                 Design Implementation Plan template (all required sections)
│   │
│   └── vendor/                    Tier 2 (pin and never modify)
│       └── harnessable/
│           ├── KNOWLEDGE_GRAPH.yaml    Framework concept graph — roles, artifacts, enumerations, relationships
│           ├── HARNESSABLE_VERSION     One line: the release tag or commit SHA pinned here
│           └── references/            Reference documents — do not modify
│               ├── roles.md           Full role definitions, permissions, prohibitions
│               ├── state-machine.md   Board status transitions and invariants
│               ├── error-modes.md     Classified failure patterns and expected responses
│               ├── continuous-improvement.md  Failure → RCA → harness improvement loop
│               ├── hooks.md           Hook lifecycle events, installation, and extension guide
│               └── knowledge-graph.md Knowledge graph model, vendoring instructions, and project extension guide
│
├── CHEAT_SHEET.md                 Condensed harness engineering reference
└── docs/                          Mandate history and implementation plans (not part of the install)
```

---

## Key Concepts

### Why outcomes, not operations

Operating models describe organisational structure: who reports to
whom, what processes exist, how departments are arranged. That's
irrelevant to an AI agent. Outcome mandates describe what must be
true when the work is done. That's everything an agent needs.

### Target Outcome Mandate (TOM)

The TOM is the founding document of any body of work. It is authored
by the Orchestrator in business language — no implementation details,
no technical constraints — and declares the outcomes the work must
achieve, the domain context it operates in, the constraints it must
respect (budget, timeline, compliance, third-party obligations), and
the success metrics by which completion is judged.

Every DMT in the system derives from a TOM. If a DMT cannot be
traced to a TOM outcome, it should not exist.

The full artifact hierarchy:

  TOM   Target Outcome Mandate      authored by Orchestrator
    ↓   derives
  DMT   Design Mandate Task         derived by Architect from TOM
    ↓   implements
  DIP   Design Implementation Plan  authored by Engineer
    ↓   produces
  TIR   Technical Implementation Report  produced by Coder
    ↓   informs upward
  IB    Intelligence Brief          produced by Analyst, feeds TOM authoring

**Pivoting.** A TOM can be revised. When business conditions change —
a customer pivot, a competitive move, a new constraint — the
Orchestrator revises the TOM. The Architect then reassesses the
existing DMT portfolio: some DMTs survive the revision unchanged,
some require revision, some are superseded. The TOM version history
is the business decision record. TOM v1.0 → v1.1 → v2.0 is the
log of what the business tried to achieve and why it changed.

**The TOM is not a document written once. It is the current best
synthesis of everything the loop has produced so far. Each version
is a snapshot of accumulated discovery.**

This is because the Orchestrator does not receive complete
information from the marketplace. It receives a signal — raw,
noisy, incomplete. As it processes that signal, gaps emerge.
For each gap the Orchestrator dispatches an Analyst. What the
Analyst discovers collides with what the domain Architects
surface from their own bounded work. The collision of those two
independent findings — neither sufficient alone — is what drives
a new TOM version.

The workflow is not a pipeline. It is an adaptive loop:

  Orchestrator detects gap
      ↓
  Analyst dispatched
      ↓
  IB returned
      ↓
  Architect surfaces constraint independently
      ↓
  Orchestrator synthesises both findings
      ↓
  Collision produces discovery neither held alone
      ↓
  TOM vX — new version, possibly new constituent TOM
      ↓
  Loop continues until TOM is stable

A fleet member is not designed upfront. It is discovered through
the loop. The canonical example: "how do we activate tenants?"
The Analyst found that activation must be manual. The Architect
found it could not be done reliably in the tenant application.
Neither finding alone would have produced the answer. Together
they produced a constituent that was not in the original
marketplace signal — an operator console. A new constituent TOM
was born. The fleet grew by one. The parent TOM incremented.

The loop continues until the Orchestrator judges the TOM stable:
no outstanding gaps, no pending Analyst dispatches, no unresolved
Architect feedback. At that point the TOM is not finished — it is
stable enough to execute against. The next marketplace signal will
start the loop again.

**What is novel today becomes templated tomorrow. Every completed
TOM is a pattern the Orchestrator can recognise in the next
engagement.**

Not every engagement requires research. The Orchestrator's first
decision on receiving a stakeholder signal is a classification:

  Novel      — the problem space contains genuine unknowns.
               The Orchestrator dispatches Analysts per gap
               before authoring the TOM.

  Templated  — the Orchestrator has seen this pattern before.
               A white-labelled SaaS deployment. A new traffic
               node. A known fleet extension. The Orchestrator
               goes straight to AUTHORING — no Analyst dispatch,
               no research phase.

The same logic applies inside the execution loop. When an
Architect surfaces a constraint, the Orchestrator decides:

  Known pattern  → ACT directly, no Analyst needed
  Genuine unknown → dispatch Analyst first, ACT on the IB

This is why the Orchestrator's accumulated experience matters.
Every completed TOM extends the pattern library. What required
an Analyst investigation on the first engagement is handled
from pattern on the second. The Orchestrator gets faster and
cheaper as the library grows — which is precisely what
R.A.F.A.E.L.'s memory layer is designed to enable.

### Knowledge Graph

`KNOWLEDGE_GRAPH.yaml` is the authoritative semantic layer for the framework: it declares every concept in the `harnessable` namespace — roles, artifacts, enumerations, and their relationships — as a machine-readable graph that agents and guards reason against, not merely read. The framework graph is vendored unchanged under `docs/harness/vendor/harnessable/`; project-specific concepts extend it in a separate `docs/knowledge-graph.yaml`. When two platforms use the same label for different concepts, an alignment entry marks `safe_assumption: false` — an active instruction to any agent working across those platforms to treat the concepts as distinct regardless of shared labels.

The knowledge graph is also the pipeline's second output. Every mandate produces working software and an enriched graph — both are required for DONE. Every role is a scout: the Engineer amends the graph during recon, the Coder and QA file `ONTOLOGY_GAP` when they encounter undeclared concepts, and the Architect grounds mandate intent in the graph before the DMT is finalised and confirms enrichment before closure. A concept discovered during any stage that is not in the graph halts work until declared. ONTOLOGY_GAP resolutions and graph enrichment are also prerequisites for framework improvement — when the same gap class recurs across three mandates, it triggers a MetaMandate.

Full model and extension guide: [framework/vendor/harnessable/references/knowledge-graph.md](framework/vendor/harnessable/references/knowledge-graph.md)

### Context Continuity

The PreCompact hook pair fires before every compaction event, preserving operational state before the context window is truncated. `transcript_archive.py` compresses the full session transcript and indexes it in `.harness/transcripts/` — nothing is auto-purged; operators set the retention policy. `mandate_snapshot.py` writes `.harness/compaction-handover.md`, a structured document capturing board status, open discoveries, active role, and git state across all configured codebases. The next session loads this handover document and resumes with full operational context rather than starting from the compaction summary. Codebase paths are configured in `.harness/config.json`.

### Recursive Self-Improvement

Every role performs a Framework Observation at the end of every session — unconditionally, not only when something fails. Observations are filed as `HARNESS_IMPROVEMENT` discoveries with structured fields: `gap`, `stage`, and `proposal` common to all roles, plus `upstream_opportunity` for QA and Security and `propagation` for the Architect. The SRE's observation is recorded in the SIR `## SRE Sign-Off` as Phase 5 of the Verification Protocol; Security's is recorded in the SRR as Phase 8. `PropagationDistance` — the number of pipeline stages a gap traveled before detection — determines improvement priority. When the same `gap_class` appears in three or more `ImprovementSignal` entries, the Architect creates a MetaMandate: a mandate whose codebase is the framework itself, running through the full pipeline. The framework improves itself by governing itself.

### Quality Lifecycle

The Reviewer, Inspector, and Analyst operate outside the core pipeline on a separate clock. They are invoked by Architect investment decision — via a [REVIEW], [INSPECT], or [RESEARCH] mandate — independently of any specific core mandate. They do not gate pipeline progression. They do not issue verdicts. The Reviewer and Inspector produce a Code Review Report or Protocol Inspection Report containing findings classified as MUST_FIX through NITPICK, and child mandates for findings above the Architect's declared threshold; those child mandates re-enter the core pipeline at BACKLOG. The Reviewer may run during idle compute. The Inspector requires a live system or captured traffic. All three self-close at DONE without Architect acceptance. The gap between a finding and its remediation is a mandate cycle — explicit, expected, and Architect-controlled.

### Analyst

Every other role in the framework operates on the codebase or
the running system. The Analyst operates on the world outside —
competitor moves, user pain signals, practitioner discourse,
technology shifts — and translates them into patterns the
Architect can act on. This role exists because training data
expires: every product-relevant fact about the external world
must be fetched live. The Analyst's primary instrument is
`tools/web_verify.py`. Every signal is classified by source
type (VERIFIED_USER, PRACTITIONER, ANALYST_OPINION,
COMMUNITY_SIGNAL, COMPETITOR_CLAIM) before entering the
Intelligence Brief. A pattern requires at least three
independent signals. The Analyst recommends; the Architect
decides whether to mandate work. No training knowledge may
appear as a source in an Intelligence Brief — every claim
requires a fetched URL and a date.

### External Fact Verification

An agent's training data ends at a cutoff. Any claim about a
third-party system's current state — package compatibility, API
surface, deprecation status, SDK constraints — reflects the world
as it was at training time, not as it is now. Harnessable treats
this as an engineering constraint: Engineer Pass 4 requires all
external dependencies to be verified against live-fetched sources
at the installed version, with the URL and fetch date cited in Recon
Findings. A DIP that asserts compatibility based on training knowledge
alone is incomplete. `tools/web_verify.py` provides a single entry
point for version resolution, URL fetch, and web search during recon.

### Field Discoveries

When any acting agent finds something not anticipated in the mandate, they must stop and file a discovery before proceeding. Discoveries are classified:

| Class | Meaning |
| --- | --- |
| `INFO` | Noted; no design change needed |
| `DEVIATION` | Design must be updated before proceeding |
| `BLOCKER` | Work cannot continue; Architect must review |
| `HARNESS_IMPROVEMENT` | A missing control was identified |

Silent deviations, where implementation differs from the plan without being logged, are a protocol violation.

### Containment Checklist

Every non-trivial implementation step in a DIP must answer four questions before the Coder touches it:

- **Detect** — how will a failure surface?
- **Contain** — what prevents it from cascading?
- **Recover** — what is the rollback path?
- **Prevent recurrence** — what check or policy would catch this class of failure earlier?

If a step has no answer for any of these, the DIP has a design gap.

### Continuous Improvement

Each failure should be reviewed for missing or ineffective controls. The framework treats its own protocol files as a codebase: any agent may file a `HARNESS_IMPROVEMENT` discovery, which creates a child task and eventually flows through the same pipeline as any other mandate.

Incident review should focus on the control gap, not only the model output.

### Governed Credential Operations

The `secrets_guard.py` hardcoded floor blocks all credential reads by default. For SRE mandates that legitimately need to verify credential files — checking line counts, hashes, or key presence — the SRE protocol provides a session-scoped exemption. Before any credential step, the SRE creates `.harnessable/credential_ops.json` declaring the approved file paths, the mandate that authorises access, and a 4-hour expiry. This permits verify-only operations (`wc -l`, `md5sum`, `grep -c`) on the declared files. Content-exposing commands (`cat`, `head`, `tail`) remain blocked regardless of the exemption. The `credential_ops_cleanup.py` stop hook removes the exemption file at session end — exemptions never persist across sessions.

### Spike

Not every idea needs a DIP. Not every fix needs a mandate. The Spike
protocol covers impromptu, exploratory, and micro-fix work that is too
small for the full pipeline but too consequential to run ungoverned.
Branch-first: `git checkout -b spike/{description}` is the first action,
and the branch name is the intent statement. A declared time box (default
two hours, one re-commitment permitted) bounds the scope. DISCOVERY entries
appear in commit messages — not only in conversation — so the trail survives
the session. Two valid exits: Ship (PR opened, commits clean) or Abandon
(one-sentence note, branch deleted, no retroactive DIP). If scope expands
beyond the declared intent, the Spike escalates to the full pipeline and the
branch becomes the input to a proper mandate. Spike is not Emergency —
production incidents use Emergency. Spike is for the idea that arrived
during other work, the micro-fix that is obviously right, the prototype
that needs an afternoon.

---

## Core Principles

1. **System reliability is an engineering responsibility.** Model access does not provide workflow reliability by itself.
2. **Account for model error.** Design for detection, containment, and recovery rather than assuming perfect behaviour.
3. **Pair capability with controls.** Model capability must be supported by validation, permissions, verification, and observability.
4. **Require verification.** Claims are not evidence. `"It should work"` is not acceptable. `"I verified it works because [output]"` is.
5. **Treat failures as control gaps.** Review incidents by asking what control was missing or ineffective.
6. **External facts expire.** An agent's training data is a snapshot
   fixed at its cutoff date. Any claim about a third-party system —
   package compatibility, API surface, deprecation status, rate limits,
   authentication schemes — must be verified against a live-fetched
   source at the installed version. Training knowledge tells you where
   to look; it does not tell you what is true now.

---

## Getting Started

### 1. Set up your project tracker

Create a board or workflow in your project tracker of choice (GitHub Projects, Jira, Linear, Asana, or any tool that supports custom status columns) with these statuses:

`BACKLOG` · `MANDATED` · `IN_RECON` · `PLANNED` · `IN_PROGRESS` · `IN_REVIEW` · `BLOCKED` · `NEEDS_REVISION` · `VERIFIED` · `DONE`

**If using GitHub Projects:** all ten columns can be created in one `gh` CLI command rather than through the UI. Column names must exactly match the list above — a typo causes status transitions to fail silently. First fetch the project ID and the Status field ID:

```bash
gh api graphql -f query='
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField { id name }
        }
      }
    }
  }
}' -F org=YOUR_ORG -F number=YOUR_PROJECT_NUMBER
```

Then set all ten options in one mutation (replace `PROJECT_ID` and `FIELD_ID` with the values returned above):

```bash
gh api graphql -f query='
mutation($projectId: ID!, $fieldId: ID!) {
  updateProjectV2Field(input: {
    projectId: $projectId
    fieldId: $fieldId
    singleSelectOptions: [
      {name: "BACKLOG",        color: GRAY},
      {name: "MANDATED",       color: BLUE},
      {name: "IN_RECON",       color: BLUE},
      {name: "PLANNED",        color: BLUE},
      {name: "IN_PROGRESS",    color: YELLOW},
      {name: "IN_REVIEW",      color: ORANGE},
      {name: "BLOCKED",        color: RED},
      {name: "NEEDS_REVISION", color: RED},
      {name: "VERIFIED",       color: GREEN},
      {name: "DONE",           color: GREEN}
    ]
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        options { id name color }
      }
    }
  }
}' -F projectId=PROJECT_ID -F fieldId=FIELD_ID
```

If the board already has a Status field with existing options, this mutation replaces all options; export existing item statuses first if any items are already assigned a value.

Declare the tool and integration method in your project's `AGENTS.md` under `## Project Tracker` so every agent session knows how to read and update board state.

### 2. Install the framework

Run the installer from the harnessable repository root, pointing it at your project:

```bash
bash install.sh /path/to/your-project
```

The installer is idempotent — safe to re-run at any time. It installs:

| What | Where | Tier |
| --- | --- | --- |
| `KNOWLEDGE_GRAPH.yaml`, `references/`, `templates/`, `HARNESSABLE_VERSION` | `docs/harness/vendor/harnessable/` | 2 — never modify |
| `agents/`, `hooks/`, `tools/web_verify.py`, `templates/` | `docs/harness/` | 1 — copy and own |
| Ten role skills | `.claude/commands/` | framework-owned — do not edit |
| Hook dispatcher wired | `.claude/settings.json` | config |
| Runtime output excluded | `.gitignore` | config |
| Audit defaults | `.harnessable/config.json` | config |

**Ownership tiers:**

| Tier | Examples | Sync behaviour | Can project customise? |
| --- | --- | --- | --- |
| Tier 2 — vendor | KNOWLEDGE_GRAPH, references/ | Unconditional replace | Never |
| Tier 1 — scaffold | Agent files, dip.md | Replace if not customised; MANUAL_MERGE if customised | Yes — project owns after copy |
| Framework-owned | Hooks, tools, skills | Unconditional replace | No — AGENTS.md only |

**Output prefixes** during a run:

| Prefix | Meaning |
| --- | --- |
| `SYNCED` | File installed or updated from framework |
| `OK` | File already current, no change |
| `MERGE` | Customised file skipped — MANUAL_MERGE_REQUIRED |
| `PATCHED` | Config file updated (settings, gitignore, config.json) |

**Tracker auto-fill:** if your project's `AGENTS.md` already has a `## Project Tracker` section before you run the installer, the skills are auto-filled with your tracker tool, URL pattern, and integration method. If it does not, the skills install with a `# REPLACE` marker — add the section and re-run with `--update`.

**Keeping in sync:** as the framework evolves, pull the latest harnessable and sync all installed projects:

```bash
# Sync a specific project (requires clean working tree)
bash install.sh --update /path/to/your-project

# Sync the current directory
bash install.sh --update
```

Update mode diffs each file before replacing. Framework-only additions apply automatically (`SYNCED`). Files where your project has removed or changed framework lines are flagged `MERGE` and left untouched — resolve those manually. Hooks and tools are framework-owned and always replaced unconditionally.

Commit after each project sync:

```bash
git -C /path/to/your-project add -A
git -C /path/to/your-project commit -m "chore: sync harnessable → $(git rev-parse --short HEAD)"
```

**Back-propagation:** to sync all projects in one pass, use the prompt in [back-propagation-prompt.md](back-propagation-prompt.md).

**Manual install (alternative):** Copy the framework directory, wire the settings template, add `.harnessable/` to `.gitignore`, and copy the skills — then fill in the `# REPLACE` markers in each skill file:

```bash
cp -r framework/. path/to/your-project/docs/harness/
cp docs/harness/hooks/claude_code_settings_template.json .claude/settings.json
echo '.harnessable/' >> .gitignore
mkdir -p .claude/commands
cp docs/harness/templates/skills/*.md .claude/commands/
```

### 2a. After install: configure skills

Skill files are framework-owned — do not edit them directly.
All project-specific configuration belongs in `AGENTS.md`.
`install.sh` reads `AGENTS.md ## Project Tracker` and fills
skill placeholders automatically on every sync.

The two items that always require manual configuration:

1. Add `## Project Tracker` to `AGENTS.md` if not present
2. Fill spike.md high-risk surfaces (line marked `# REPLACE`)

Invoke any role with:

```text
/project:architect "docs/mandates/auth/login_feature.md"
/project:engineer "docs/mandates/my-feature.md"
/project:engineer 190778951
/project:coder "docs/mandates/auth/login_implementation_plan.md"
/project:sre "docs/mandates/ops/deploy-vhost.md"
/project:qa 190778951
/project:security "docs/mandates/auth/login_implementation_plan.md"
/project:reviewer "src/auth/"
/project:inspector "docs/mandates/auth/login_implementation_plan.md"
/project:analyst "Google Ads automated bidding for SMBs, 90 days, competitor moves + user pain"
/project:spike "add reports menu item"
/project:emergency "login service is returning 500s on all POST requests"
```

`$ARGUMENTS` accepts a board item ID, a local file path, or an inline description. See [framework/vendor/harnessable/references/skills.md](framework/vendor/harnessable/references/skills.md) for the full pattern and customisation guide.

### 2b. Verify the enforcement layer

After install, confirm the hooks are wired and the guards are active. Pipe each payload as a **standalone command** — do not embed them in a compound shell script. Guards inspect the outer command string: a compound script containing `git push --force` will be blocked by the bouncer on the test invocation itself.

```bash
# 1. Safe command — must exit 0, no output
printf '{"tool_name":"Bash","tool_input":{"command":"echo ok"}}' \
  | python3 docs/harness/hooks/run.py pre_tool_use
echo "Exit: $?"

# 2. Force push guard — must exit 2 with a GitGuard message
printf '{"tool_name":"Bash","tool_input":{"command":"git push origin main --force"}}' \
  | python3 docs/harness/hooks/run.py pre_tool_use 2>&1
echo "Exit: $?"

# 3. WHERE-less DELETE guard — must exit 2 with a DatabaseGuard message
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DELETE FROM users\""}}' \
  | python3 docs/harness/hooks/run.py pre_tool_use 2>&1
echo "Exit: $?"
```

The dispatcher (`hooks/run.py`) discovers `*.py` files in each event subdirectory and runs them in alphabetical order. Adding a new check requires only dropping a `.py` file into the relevant subdirectory — no `settings.json` edit needed.

### 2c. Seed the project knowledge graph

This step is not handled by the installer — it requires project-specific values.

Copy the bootstrap template and fill in the two placeholders:

```bash
cp docs/harness/templates/knowledge-graph.yaml docs/knowledge-graph.yaml
```

Open `docs/knowledge-graph.yaml` and replace:

- `REPLACE_WITH_YOUR_PROJECT_NAME` — a short identifier for your project
- `REPLACE_WITH_CONTENTS_OF_HARNESSABLE_VERSION_FILE` — copy the exact string from `docs/harness/vendor/harnessable/HARNESSABLE_VERSION`

Commit the seeded file before your first mandate:

```bash
git add docs/knowledge-graph.yaml
git commit -m "chore: bootstrap docs/knowledge-graph.yaml from template"
```

Every agent protocol loads this file at session start. If it does not exist when the Architect begins the Forward Scout Obligation, the agent will bootstrap it automatically — but seeding it here, before the first mandate, is the preferred path. See [framework/vendor/harnessable/references/knowledge-graph.md](framework/vendor/harnessable/references/knowledge-graph.md) for the full extension model.

### 3. Load agent context at session start

**With CC skills installed (recommended):** invoke the role directly. The skill loads all required context automatically.

```text
/project:engineer "docs/mandates/my-feature.md"
```

**Without CC skills** (or for non-Claude Code runtimes): load context manually at session start.

```text
You are operating as the [Engineer | Coder | SRE | QA | Security].

Role definition: docs/harness/vendor/harnessable/references/roles.md
State machine: docs/harness/vendor/harnessable/references/state-machine.md
Your protocol: docs/harness/agents/[role].md
```

For Codex: use the role prompt templates in `codex/examples/`.

### 4. Create your first DMT

The Architect creates a task in the project tracker with:

- A clear problem statement
- Measurable acceptance criteria
- Explicit constraints and out-of-scope declarations

Set status to `MANDATED`. The Engineer may begin.

### 5. Run the workflow

Each role reads its protocol file before starting any work. No role begins without the preceding artifact existing and the board in the correct state. The `agents/` files are the operating instructions; the `references/` files are the rulebook.

---

## Codex compatibility

Harnessable works with Codex through:

- `AGENTS.md` at the repo root for persistent repository instructions,
  discovered automatically by Codex at session start
- `.agents/skills/harnessable/SKILL.md` for progressive, task-specific
  protocol loading — invoke with `"Use the harnessable skill."` in any prompt
- `codex/` for install scripts and role prompt examples
- Harnessable guards adapted as shell or Python checks where Codex
  lifecycle hooks are available

Install into your project:

```bash
bash codex/install.sh /path/to/your-project
```

Then invoke any role:

```bash
codex "Use the harnessable skill. Act as Engineer and produce a DIP for issue #12."
```

See `codex/examples/` for complete role prompt templates.

---

## Anti-Patterns

| Anti-pattern | Replace with |
| --- | --- |
| Unlimited shell access | Controlled tools with schemas and permission checks |
| Prompt-only safety (`"never delete data"`) | Enforced hooks via `hooks/run.py` that block regardless of model intent |
| Self-verification | Independent QA that re-executes checks themselves |
| Huge agent contexts | Sub-agents with scoped tasks, summarised findings passed to parent |
| No audit trail | Structured TIR with real output evidence |
| Silent deviations | Filed field discoveries with original vs. actual |

---

## Engineering Model

This framework borrows practices from regulated engineering disciplines where failure review, independent verification, and change control are required. Comparable practices in civil and structural engineering include:

- Work does not proceed without stamped drawings (DMT → DIP)
- Field changes require documented RFIs (DEVIATION field discoveries)
- Third-party inspection is independent of the implementing contractor (QA ≠ Coder)
- Every failure produces a root cause analysis and a control improvement

Software teams running AI agents on production work need comparable controls for authorization, verification, deviation handling, and incident review.

There is a constraint specific to AI agents that has no direct
analogue in traditional engineering: training data ends at a fixed
point in time. A human engineer reaching for the documentation of a
third-party library retrieves the current version without thinking
about it. An AI agent retrieving the same documentation may silently
fetch a prior version — the one it knew at training time — and reason
from a compatibility table that is months or years out of date. This
is not a flaw in the model; it is an epistemic property of how models
are built. The engineering response is the same one applied to any
known constraint: design for it explicitly. External facts must be
verified live, at the installed version, with the source cited. The
framework encodes this in Engineer Pass 4 and provides tooling to
make live verification the path of least resistance rather than an
extra step.

---

## Influences & Acknowledgements

This framework did not emerge from a single source. It developed through practice building real systems with LLMs, accumulated reading across several fields, and iterative refinement over many sessions.

The intellectual traditions it draws on include:

- **Regulated engineering disciplines** — civil and structural engineering practices around stamped drawings, field RFIs, third-party inspection, and mandatory root cause analysis after failure. These supplied the core analogy and much of the vocabulary.
- **Site Reliability Engineering and lean manufacturing** — particularly the focus on error budgets, failure modes, containment over perfection, and the idea that reliability is a systemic property rather than a property of individual components.
- **AI safety and alignment research** — especially work on corrigibility, human oversight, and the importance of maintaining meaningful human control over systems that can act autonomously.
- **Software engineering practice** — decades of accumulated thinking on separation of concerns, audit trails, and the value of independent review.

Parts of this framework were developed in collaboration with Claude (Anthropic) through extended brainstorming and stress-testing sessions. The ideas were challenged, refined, and sometimes reversed through that process.

If you recognise a specific source that clearly influenced something here, contributions to this section are welcome — open an issue or a pull request.

---

## Licence

[AGPL-3.0](LICENSE)
