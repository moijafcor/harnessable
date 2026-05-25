# Harnessable

**Harness Engineering** is the practice of designing the operating environment for an AI agent, including context, tools, permissions, enforcement, verification, and observability.

This repository is the operational governance layer for autonomous agents working in high-stakes production environments — from AI coding assistants to chief-of-staff, legal review, and financial analysis agents. It provides four roles, a structured artifact chain, a state machine, and a continuous improvement loop — all backed by a deployable enforcement layer: a hooks dispatcher and scripts that make the governance protocols mechanically enforceable, not merely advisory. The process is adapted from regulated engineering disciplines and applied to any domain where an agent operates with real consequences.

All framework concepts — roles, artifacts, enumerations, and their relationships — are defined in [KNOWLEDGE_GRAPH.yaml](framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml).

---

## Contents

- [Problem Statement](#problem-statement)
- [What This Is Not](#what-this-is-not)
- [The Harness Engineering Manifesto](#the-harness-engineering-manifesto)
- [The Framework](#the-framework)
  - [Four Roles](#four-roles)
  - [The Artifact Chain](#the-artifact-chain)
  - [The State Machine](#the-state-machine)
  - [Harness Layers](#harness-layers)
  - [Guards in Action](#guards-in-action)
- [Repository Structure](#repository-structure)
- [Key Concepts](#key-concepts)
  - [Knowledge Graph](#knowledge-graph)
  - [Field Discoveries](#field-discoveries)
  - [Containment Checklist](#containment-checklist)
  - [Continuous Improvement](#continuous-improvement)
- [Core Principles](#core-principles)
- [Getting Started](#getting-started)
  - [1. Set up your project tracker](#1-set-up-your-project-tracker)
  - [2. Copy the framework directory](#2-copy-the-framework-directory)
  - [2a. Wire the enforcement hooks](#2a-wire-the-enforcement-hooks)
  - [2b. Add `.harnessable/` to `.gitignore`](#2b-add-harnessable-to-gitignore)
  - [3. Load agent context at session start](#3-load-agent-context-at-session-start)
  - [4. Create your first DMT](#4-create-your-first-dmt)
  - [5. Run the workflow](#5-run-the-workflow)
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
- Not model-specific — designed for Claude Code but the protocols and hook architecture apply to any autonomous agent runtime with lifecycle hooks

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
├── framework/                     One-command install: cp -r framework/ docs/harness/
│   │
│   ├── agents/                    Tier 1 (copy and own) — role-specific agent protocols
│   │   ├── engineer.md            Recon passes, DIP authoring standards, sub-agent delegation
│   │   ├── coder.md               Build discipline, pre-completion hook runner, exit gate
│   │   └── qa.md                  Adversarial verification protocol, verdict criteria
│   │
│   ├── hooks/                     Tier 1 (copy and own) — Enforcement Layer
│   │   ├── run.py                 Universal dispatcher: discovers and runs *.py scripts per event
│   │   ├── pre_tool_use/          Scripts run on PreToolUse (add files here to extend)
│   │   │   ├── bouncer.py         Blocks commands matching AGENTS.md ## Blocked (policy-driven)
│   │   │   ├── secrets_guard.py   Hardcoded floor: blocks credential reads and exfiltration
│   │   │   ├── database_guard.py  Blocks DROP, TRUNCATE, and WHERE-less DELETE/UPDATE
│   │   │   ├── git_guard.py       Blocks force push, hard reset, branch and history destruction
│   │   │   └── communication_guard.py  Blocks unauthorized email, Slack, SMS, and calendar writes
│   │   ├── post_tool_use/         Scripts run on PostToolUse (add files here to extend)
│   │   │   └── audit_logger.py    Appends every tool call to .harnessable/audit.log
│   │   ├── stop/                  Scripts run on Stop (add files here to extend)
│   │   │   └── completion_gate.py Runs AGENTS.md ## Completion Gate commands; blocks if any fail
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

### Knowledge Graph

`KNOWLEDGE_GRAPH.yaml` is the authoritative semantic layer for the framework: it declares every concept in the `harnessable` namespace — roles, artifacts, enumerations, and their relationships — as a machine-readable graph that agents and guards reason against, not merely read. The framework graph is vendored unchanged under `docs/harness/vendor/harnessable/`; project-specific concepts extend it in a separate `docs/knowledge-graph.yaml`. When two platforms use the same label for different concepts, an alignment entry marks `safe_assumption: false` — an active instruction to any agent working across those platforms to treat the concepts as distinct regardless of shared labels.

The knowledge graph is also the pipeline's second output. Every mandate produces working software and an enriched graph — both are required for DONE. Every role is a scout: the Engineer amends the graph during recon, the Coder and QA file `ONTOLOGY_GAP` when they encounter undeclared concepts, and the Architect grounds mandate intent in the graph before the DMT is finalised and confirms enrichment before closure. A concept discovered during any stage that is not in the graph halts work until declared.

Full model and extension guide: [framework/vendor/harnessable/references/knowledge-graph.md](framework/vendor/harnessable/references/knowledge-graph.md)

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

### 2. Copy the framework directory

All installable files are pre-structured under `framework/`. Copy the directory into your project:

```bash
cp -r framework/ path/to/your-project/docs/harness/
```

The directory is already organized. Tier 1 files (`agents/`, `hooks/`, `templates/`) are ready to customize. Tier 2 files (`vendor/harnessable/`) define the framework semantics — do not modify them.

Update `docs/harness/vendor/harnessable/HARNESSABLE_VERSION` with the release tag or commit SHA you copied from.

See [framework/vendor/harnessable/references/knowledge-graph.md](framework/vendor/harnessable/references/knowledge-graph.md) for the full extension model.

### 2a. Wire the enforcement hooks

Copy `framework/hooks/claude_code_settings_template.json` to `.claude/settings.json` at the root of your project (or merge it into an existing settings file). Update the base path if you placed `framework/` somewhere other than `docs/harness/`.

This registers `hooks/run.py` as the dispatcher for three lifecycle events:

| Event | Subdirectory | What runs |
| --- | --- | --- |
| PreToolUse | `hooks/pre_tool_use/` | `bouncer.py`, `secrets_guard.py`, `database_guard.py`, `git_guard.py`, `communication_guard.py` |
| PostToolUse | `hooks/post_tool_use/` | `audit_logger.py` |
| Stop | `hooks/stop/` | `completion_gate.py` |

Adding a new check later requires only dropping a `.py` file into the relevant subdirectory — no further changes to `settings.json`.

To verify the enforcement layer is live after wiring, run these three checks. Pipe each payload as a **standalone command** — do not embed them in a compound shell script. Guards inspect the outer command string: a compound script containing `git push --force` will be blocked by the bouncer on the test invocation itself, before the JSON payload is evaluated.

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
printf '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DELETE FROM users\""}}' \
  | python3 docs/harness/hooks/run.py pre_tool_use 2>&1
echo "Exit: $?"
```

### 2b. Add `.harnessable/` to `.gitignore`

`audit_logger.py` begins writing to `.harnessable/audit.log` on the first tool call after hooks are wired. Add the directory to `.gitignore` before your first `git add`:

```text
# .gitignore
.harnessable/
```

Ignoring the directory (not just the log file) protects all runtime output the framework may write there. If a specific artifact later needs to be versioned, add a negation entry (`!.harnessable/filename`).

### 3. Load agent context at session start

At the start of each agent session, tell the agent which role it is playing and point it to the relevant files:

```text
You are operating as the [Engineer | Coder | QA].

Role definition and permissions: docs/harness/vendor/harnessable/references/roles.md
State machine: docs/harness/vendor/harnessable/references/state-machine.md
Your protocol: docs/harness/agents/[engineer|coder|qa].md
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
