---
name: harnessable
description: >
  Use when coordinating autonomous agent work through Harnessable roles,
  mandates, implementation plans, QA verdicts, guardrails, knowledge graph
  obligations, or audit-ready task execution.
---

# Harnessable Skill

Follow the Harnessable role chain:

Architect → Engineer → Coder (or SRE) → QA → Security (when flagged) → Architect acceptance

No role approves its own work. The Coder cannot be the QA.
The SRE cannot be the QA for the same mandate.
The Engineer must not write implementation code.
The Security reviewer must not be the Coder, SRE, or QA for the same mandate.

## Role rules

**Architect** defines intent and acceptance criteria. Grounds every domain
concept in docs/knowledge-graph.yaml before finalising the DMT. Confirms
graph enrichment before accepting the QA verdict and setting DONE.

**Engineer** produces the Design Implementation Plan. Recon produces two
outputs: the DIP and knowledge graph amendments. Raw labels in the DIP
are a protocol violation if the concept is absent from the graph.

**Coder** implements only what the approved DIP specifies. Files a
Discovery before deviating. Produces a TIR with evidence, not claims.

**SRE** executes infrastructure and operational mandates against live
systems. Captures pre-change state before acting, confirms rollback is
documented, respects blast radius, and verifies system health — not test
suites. Produces a SIR with actual command output and observation window
evidence, not claims.

**QA** verifies independently. Re-executes checks — does not inherit
them from the Coder or SRE. A passing verdict over unresolved ONTOLOGY_GAP
discoveries is a protocol violation.

**Security** is invoked by the Architect on mandates that touch auth, untrusted
inputs, credentials, external surfaces, data exposure, privilege, or new
dependencies. Runs after QA PASS or CONDITIONAL_PASS. Maps the attack surface
before any technical checks, then probes it across seven phases. Records a
Security Review Report (SRR) in the DIP. A FAIL blocks DONE regardless of QA
verdict.

## Required outputs

| Stage                  | Output                                                     |
| ---------------------- | ---------------------------------------------------------- |
| Planning               | Design Mandate Task (DMT)                                  |
| Engineering            | Design Implementation Plan (DIP)                          |
| Coding                 | Task Implementation Report (TIR)                          |
| Infrastructure / Ops   | SRE Implementation Report (SIR)                           |
| Review                 | QA Verdict: PASS / CONDITIONAL_PASS / FAIL                |
| Security (when flagged)| Security Review Report (SRR): SECURE_PASS / CONDITIONAL_PASS / FAIL |

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
