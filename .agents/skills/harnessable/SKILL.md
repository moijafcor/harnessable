---
name: harnessable
description: >
  Use when coordinating autonomous agent work through Harnessable roles,
  mandates, implementation plans, QA verdicts, guardrails, knowledge graph
  obligations, or audit-ready task execution.
---

# Harnessable Skill

Follow the Harnessable role chain:

Architect → Engineer → Coder → QA → Architect acceptance

No role approves its own work. The Coder cannot be the QA.
The Engineer must not write implementation code.

## Role rules

**Architect** defines intent and acceptance criteria. Grounds every domain
concept in docs/knowledge-graph.yaml before finalising the DMT. Confirms
graph enrichment before accepting the QA verdict and setting DONE.

**Engineer** produces the Design Implementation Plan. Recon produces two
outputs: the DIP and knowledge graph amendments. Raw labels in the DIP
are a protocol violation if the concept is absent from the graph.

**Coder** implements only what the approved DIP specifies. Files a
Discovery before deviating. Produces a TIR with evidence, not claims.

**QA** verifies independently. Re-executes checks — does not inherit
them from the Coder. A passing verdict over unresolved ONTOLOGY_GAP
discoveries is a protocol violation.

## Required outputs

| Stage       | Output                                      |
|-------------|---------------------------------------------|
| Planning    | Design Mandate Task (DMT)                   |
| Engineering | Design Implementation Plan (DIP)            |
| Coding      | Task Implementation Report (TIR)            |
| Review      | QA Verdict: PASS / CONDITIONAL_PASS / FAIL  |

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
