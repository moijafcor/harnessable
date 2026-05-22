# Harnessable

**Harness Engineering** is the practice of designing the operating environment for an AI agent, including context, tools, permissions, enforcement, verification, and observability.

This repository is the operational governance layer for autonomous agents working in high-stakes production environments — from AI coding assistants to chief-of-staff, legal review, and financial analysis agents. It provides four roles, a structured artifact chain, a state machine, and a continuous improvement loop — all backed by a deployable enforcement layer: a hooks dispatcher and scripts that make the governance protocols mechanically enforceable, not merely advisory. The process is adapted from regulated engineering disciplines and applied to any domain where an agent operates with real consequences.

All abbreviations and framework-specific terms are defined in [GLOSSARY.md](GLOSSARY.md).

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
- Not model-specific — designed for Claude Code but the protocols and hook architecture apply to any autonomous agent runtime with lifecycle hooks

---

## The Framework

### Four Roles

Roles are **functional**, not personal. One human or one agent session may perform multiple roles, but the active role must be explicit and role boundaries must be preserved.

| Role | Responsibility | Produces |
| --- | --- | --- |
| **Architect** | Define intent. Own the mandate. Review outcomes. | Design Mandate Task (DMT) |
| **Engineer** | Translate intent into an implementable plan. | Design Implementation Plan (DIP) |
| **Coder** | Execute the plan exactly as designed. | Task Implementation Report (TIR) |
| **QA** | Verify independently. Treat implementation claims as unverified until checked. | QA Verdict |

No role approves its own work. The Coder cannot be the QA. The Engineer must not write code.

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
    ▼
Coder implements + streams TIR
    │
    │  Completed work with evidence: verification output,
    │  deviations filed, and gates checked.
    ▼
QA verifies + issues verdict
    │
    │  Independently executed checks and verdict:
    │  PASS / CONDITIONAL_PASS / FAIL.
    ▼
Architect accepts → DONE
```

Artifacts are append-only after their stage closes. A closed mandate's DIP is immutable except for `## Post-Close Notes`.

---

### The State Machine

```text
BACKLOG → MANDATED → IN_RECON → PLANNED → IN_PROGRESS → IN_REVIEW → VERIFIED → DONE
                                                              ↕
                                                           BLOCKED
                                                              ↕
                                                        NEEDS_REVISION
```

Every transition has a defined owner, a trigger condition, and invariants that must hold. Illegal jumps (e.g. `PLANNED → IN_REVIEW` with no implementation) are protocol violations that any agent must refuse.

Full transition table and invariants: [references/state-machine.md](references/state-machine.md)

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
Enforcement Layer  ← PreToolUse: five guards block before execution
      │                 bouncer.py          AGENTS.md ## Blocked policy
      │                 secrets_guard.py    credential reads and exfiltration
      │                 database_guard.py   DROP / TRUNCATE / WHERE-less DELETE
      │                 git_guard.py        force push / hard reset / branch destruction
      │                 communication_guard.py  email / Slack / SMS without approval
      │               PostToolUse: audit_logger.py records every tool call
      ▼
Execution
      │
      ▼
Verification Layer ← Stop: completion_gate.py (completion gate before turn completes)
      │               Independent QA, automated checks, evidence required
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
├── agents/                        Role-specific agent protocols
│   ├── engineer.md                Recon passes, DIP authoring standards, sub-agent delegation
│   ├── coder.md                   Build discipline, pre-completion hook runner, exit gate
│   └── qa.md                      Adversarial verification protocol, verdict criteria
│
├── hooks/                         Enforcement Layer — drop into your project to activate
│   ├── run.py                     Universal dispatcher: discovers and runs *.py scripts per event
│   ├── pre_tool_use/              Scripts run on PreToolUse (add files here to extend)
│   │   ├── bouncer.py             Blocks commands matching AGENTS.md ## Blocked (policy-driven)
│   │   ├── secrets_guard.py       Hardcoded floor: blocks credential reads and exfiltration
│   │   ├── database_guard.py      Blocks DROP, TRUNCATE, and WHERE-less DELETE/UPDATE
│   │   ├── git_guard.py           Blocks force push, hard reset, branch and history destruction
│   │   └── communication_guard.py Blocks unauthorized email, Slack, SMS, and calendar writes
│   ├── post_tool_use/             Scripts run on PostToolUse (add files here to extend)
│   │   └── audit_logger.py        Appends every tool call to .harnessable/audit.log
│   ├── stop/                      Scripts run on Stop (add files here to extend)
│   │   └── completion_gate.py     Runs AGENTS.md ## Completion Gate commands; blocks if any fail
│   └── claude_code_settings_template.json     Drop-in .claude/settings.json — all events wired through run.py
│
├── references/                    Reference documents loaded at session start
│   ├── roles.md                   Full role definitions, permissions, prohibitions
│   ├── state-machine.md           Board status transitions and invariants
│   ├── error-modes.md             Classified failure patterns and expected responses
│   ├── continuous-improvement.md  Failure → RCA → harness improvement loop
│   └── hooks.md                   Hook lifecycle events, installation, and extension guide
│
├── templates/
│   └── dip.md                     Design Implementation Plan template (all required sections)
│
├── CHEAT_SHEET.md                 Condensed harness engineering reference
└── GLOSSARY.md                    Definitions for all abbreviations and framework terms
```

---

## Key Concepts

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

Each failure should be reviewed for missing or ineffective controls. The framework treats its own protocol files as a codebase: any agent may file a `HARNESS_IMPROVEMENT` discovery, which creates a child task and eventually flows through the same four-role pipeline as any other mandate.

Incident review should focus on the control gap, not only the model output.

---

## Core Principles

1. **System reliability is an engineering responsibility.** Model access does not provide workflow reliability by itself.
2. **Account for model error.** Design for detection, containment, and recovery rather than assuming perfect behaviour.
3. **Pair capability with controls.** Model capability must be supported by validation, permissions, verification, and observability.
4. **Require verification.** Claims are not evidence. `"It should work"` is not acceptable. `"I verified it works because [output]"` is.
5. **Treat failures as control gaps.** Review incidents by asking what control was missing or ineffective.

---

## Getting Started

### 1. Set up your project tracker

Create a board or workflow in your project tracker of choice (GitHub Projects, Jira, Linear, Asana, or any tool that supports custom status columns) with these statuses:

`BACKLOG` · `MANDATED` · `IN_RECON` · `PLANNED` · `IN_PROGRESS` · `IN_REVIEW` · `BLOCKED` · `NEEDS_REVISION` · `VERIFIED` · `DONE`

Declare the tool and integration method in your project's `AGENTS.md` under `## Project Tracker` so every agent session knows how to read and update board state.

### 2. Copy the framework files

Place `agents/`, `references/`, `templates/`, and `hooks/` somewhere your agent sessions can read them. A `docs/harness/` directory in your project works well.

### 2a. Wire the enforcement hooks

Copy `hooks/claude_code_settings_template.json` to `.claude/settings.json` at the root of your project (or merge it into an existing settings file). Update the base path if you placed `hooks/` somewhere other than `docs/harness/hooks/`.

This registers `hooks/run.py` as the dispatcher for three lifecycle events:

| Event | Subdirectory | What runs |
| --- | --- | --- |
| PreToolUse | `hooks/pre_tool_use/` | `bouncer.py`, `secrets_guard.py`, `database_guard.py`, `git_guard.py`, `communication_guard.py` |
| PostToolUse | `hooks/post_tool_use/` | `audit_logger.py` |
| Stop | `hooks/stop/` | `completion_gate.py` |

Adding a new check later requires only dropping a `.py` file into the relevant subdirectory — no further changes to `settings.json`.

### 3. Load agent context at session start

At the start of each agent session, tell the agent which role it is playing and point it to the relevant files:

```text
You are operating as the [Engineer | Coder | QA].

Role definition and permissions: references/roles.md
State machine: references/state-machine.md
Your protocol: agents/[engineer|coder|qa].md
```

### 4. Create your first DMT

The Architect creates a task in the project tracker with:

- A clear problem statement
- Measurable acceptance criteria
- Explicit constraints and out-of-scope declarations

Set status to `MANDATED`. The Engineer may begin.

### 5. Run the workflow

Each role reads its protocol file before starting any work. No role begins without the preceding artifact existing and the board in the correct state. The `agents/` files are the operating instructions; the `references/` files are the rulebook.

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
