# Harnessable

**Harness Engineering** is the practice of designing the operating environment for an AI agent, including context, tools, permissions, enforcement, verification, and observability.

This repository defines protocols for running AI coding agents on production software work. It includes four roles, a structured artifact chain, a state machine, enforcement protocols, and a continuous improvement loop. The process is adapted from regulated engineering practices and applied to software teams using LLMs.

All abbreviations and framework-specific terms are defined in [GLOSSARY.md](GLOSSARY.md).

---

## Problem Statement

Prompt instructions are advisory unless backed by enforcement. Models are probabilistic, and long workflows compound errors.

A 95%-accurate model running a 20-step workflow succeeds **36% of the time**.

Reliability requires controls around the model, not only model selection or prompt design.

```text
Agent = Model + Context + Tools + Enforcement + Verification + Observability
```

A model without operational controls is difficult to validate, audit, and recover. A constrained, verified, observable agent can be operated as part of an engineering workflow.

---

## What This Is Not

- Not a framework for one-shot prompts or chat assistants
- Not a library or SDK — it is a set of protocols, templates, and agent instructions
- Not model-specific — designed for Claude but applicable to any capable coding agent

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
    │  Completed work with evidence: test output, linter output,
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
Context Layer      ← project rules, session memory, governance docs
      │
      ▼
Tool Layer         ← controlled tools with schemas, validation, audit logging
      │
      ▼
Enforcement Layer  ← hooks that block unsafe actions regardless of model decisions
      │
      ▼
Execution
      │
      ▼
Verification Layer ← independent QA, automated checks, evidence required
      │
      ▼
Approved Output
```

Prompts live in the Context Layer. They are useful but not enforceable. Enforcement lives in hooks and gates that run regardless of what the model decides.

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
├── references/                    Reference documents loaded at session start
│   ├── roles.md                   Full role definitions, permissions, prohibitions
│   ├── state-machine.md           Board status transitions and invariants
│   ├── error-modes.md             Classified failure patterns and expected responses
│   └── continuous-improvement.md  Failure → RCA → harness improvement loop
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

Place `agents/`, `references/`, and `templates/` somewhere your agent sessions can read them. A `docs/harness/` directory in your project works well.

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
| Prompt-only safety (`"never delete data"`) | Enforced hooks that block regardless of model intent |
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
