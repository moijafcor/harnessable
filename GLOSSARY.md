# Glossary

Definitions for all abbreviations and framework-specific terms used in this repository.

---

## Roles

**Architect**
The role responsible for defining intent, authoring the DMT, and accepting the final QA verdict. The Architect owns the mandate from creation to closure. One human or agent session may perform this role, but must not also act as QA on the same mandate.

**Engineer**
The role responsible for translating the Architect's intent into a complete, implementable plan (the DIP). The Engineer runs all recon passes and must not write implementation code.

**Coder**
The role responsible for executing the DIP exactly as written, filing deviations when the plan cannot be followed, and producing the TIR with evidence. The Coder must not approve their own work.

**QA (Quality Assurance)**
The role responsible for independently verifying the implementation against the DIP and DMT. QA re-executes checks themselves — they do not take the Coder's TIR on faith. The QA must not be the same session that set the board to `IN_REVIEW`.

---

## Artifacts

**DMT — Design Mandate Task**
The task created by the Architect in the project tracker. Defines the problem, constraints, acceptance criteria, and out-of-scope declarations. The DMT is the source of truth for what the mandate is supposed to achieve.

**DIP — Design Implementation Plan**
The document produced by the Engineer. Describes how to implement the DMT: recon findings, architecture decisions, ordered implementation steps, verification checklists, and containment plan. Lives at `docs/mandates/{bucket}/{slug}_implementation_plan.md`.

**TIR — Task Implementation Report**
The record produced by the Coder during and after implementation. Embedded as a section in the DIP. Contains what was actually built, evidence (verification output, domain-specific checks, health probes), deviation records, and the Coder's sign-off checklist.

**QA Verdict**
The outcome produced by QA after verification. Appended to the DIP. One of three outcomes: `PASS`, `CONDITIONAL_PASS`, or `FAIL`, with evidence and rationale.

**ADR — Architecture Decision Record**
A single entry in the DIP's `## Architecture Decisions` section. Documents one non-obvious design choice: what was decided, why, what alternatives were considered, and what the decision forecloses. Written for choices where a reasonable engineer might have decided differently.

---

## Field Discovery Classifications

Field discoveries are filed by any role when something unexpected is found during execution. Classified as one of:

**INFO**
Noted for awareness. No design change required; work continues.

**DEVIATION**
The implementation or plan must differ from what was written. The DIP must be updated before proceeding. Filed by the Coder when a DIP step cannot be executed as written, or by the Engineer when recon reveals a plan-invalidating finding.

**BLOCKER**
Work cannot continue. Requires Architect intervention. Sets board to `BLOCKED` and creates a child task for triage.

**HARNESS_IMPROVEMENT**
A missing or ineffective control was identified. Triggers the continuous improvement loop: a child task is created, the failure is analysed, and the appropriate framework file is updated. See `references/continuous-improvement.md`.

---

## Board Statuses

| Status | Meaning |
| --- | --- |
| `BACKLOG` | Not yet actionable; awaiting prioritisation |
| `MANDATED` | DMT is complete and approved for execution |
| `IN_RECON` | Engineer is running discovery passes |
| `PLANNED` | DIP is complete; ready for the Coder |
| `IN_PROGRESS` | Coder is actively implementing |
| `IN_REVIEW` | Implementation complete; awaiting QA |
| `BLOCKED` | Work halted; requires resolution before continuing |
| `NEEDS_REVISION` | QA verdict was FAIL; Coder must address findings |
| `VERIFIED` | QA verdict was PASS or CONDITIONAL_PASS |
| `DONE` | Architect accepted the QA verdict; mandate closed |

---

## QA Verdict Outcomes

**PASS**
All required checks executed and passed. All DMT acceptance criteria satisfied. TIR evidence complete and verified.

**CONDITIONAL_PASS**
All required checks pass, but minor issues exist that do not block the mandate's core outcome. Use sparingly — too many conditions makes this a FAIL.

**FAIL**
One or more required checks failed, or DMT acceptance criteria not met, or TIR evidence insufficient for verification.

---

## Other Terms

**Mandate**
The unit of work tracked through the pipeline. Each mandate has a DMT, a DIP, a TIR, and a QA Verdict. Mandates are classified as `new` (net-new feature or component) or `existing` (modification or fix).

**Harness**
The operating environment around the model: context, tools, permissions, enforcement, verification, and observability. The framework's central concept. See `CHEAT_SHEET.md` for the full definition.

**RCA — Root Cause Analysis**
A structured review of a failure to identify the missing or ineffective control that allowed the failure to occur (or to reach the stage it did). Required for every HARNESS_IMPROVEMENT discovery and for any mandate closed with CONDITIONAL_PASS or that passed through NEEDS_REVISION more than once.

**SRE — Site Reliability Engineering**
A discipline applying reliability engineering practices to infrastructure and operations. Referenced in the framework's engineering model context. Relevant to how the framework thinks about reliability, error budgets, and failure containment.

**MCP — Model Context Protocol**
Anthropic's open protocol for connecting AI agents to external tools and data sources via structured integrations. One possible implementation of the project tracker integration declared in `AGENTS.md`. Not required — REST API or manual updates are equally valid.

**Hook**
A shell command or script configured to run automatically in response to agent events (e.g., before a tool executes, after a session ends). Hooks implement the Enforcement Layer — they block or validate actions regardless of what the model decides. See `AGENTS.md` `## Blocked` and `## Ask First` sections.
