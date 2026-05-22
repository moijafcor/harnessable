# AI Agent Harness Engineering Cheat Sheet

> Operational governance for autonomous agents: protocols, roles, and a deployable enforcement layer for high-stakes production work.

---

## Table of Contents

1. Executive Summary
2. AI Engineering Scope
3. Core Principles
4. Harness Architecture
5. Context Layer
6. Tool Layer
7. Enforcement Layer
8. Verification Layer
9. Context Isolation with Sub-Agents
10. Reliability Engineering
11. Failure Handling
12. Observability & Auditability
13. Production Readiness Checklist
14. Architect → Engineer → Coder → QA Workflow
15. Implementation Anti-Patterns
16. Quick Reference

---

## Executive Summary

AI agent reliability depends on the operating environment around the model, not only on prompt content.

Effective agent systems require:

- Structured context
- Controlled tools
- Explicit permissions
- Verification pipelines
- Enforcement mechanisms
- Observability
- Human review

A model without operational controls is difficult to validate, audit, and recover.

A constrained, verified, and observable agent can be operated safely in any domain where actions carry real consequences. Harnessable provides both the governance protocols that define those controls and the enforcement infrastructure that makes them deterministic — not advisory.

---

## AI Engineering Scope

### Era 1 — Prompt Engineering

**Unit of work:** Message

**Goal:** Specify task instructions.

Example:

```text
Act as a senior software engineer.
```

**Limitation:**

Works well for:

- One-shot tasks
- Small requests
- Basic content generation

Breaks down when:

- Tools are required
- Long workflows are required
- State management is required
- Multiple decisions are required

---

### Era 2 — Context Engineering

**Unit of work:** Session

**Goal:** Provide the model with the correct information.

Examples:

- Retrieval-Augmented Generation (RAG)
- Memory systems
- Historical state
- Knowledge retrieval
- Project documentation

**Limitation:** Improves task performance. Not sufficient on its own for large autonomous workflows.

---

### Era 3 — Harness Engineering

**Unit of work:** System

**Goal:** Design the environment in which the model operates.

Includes:

- Context
- Tools
- Permissions
- Validation
- Enforcement
- Verification
- Governance

**Engineering focus:** Design the runtime in which the model operates.

---

## Core Principles

### Principle 1 — System Reliability Is an Engineering Responsibility

Foundation model access does not provide system reliability by itself.

Reliable operation depends on:

- Engineering
- Workflow design
- Tooling
- Verification
- Governance

---

### Principle 2 — Account for Model Error

Do not assume perfect model behaviour.

Optimise for:

- Detection
- Containment
- Recovery
- Prevention

---

### Principle 3 — Reliability Depends on Controls

Model capability must be paired with controls that make behaviour testable, auditable, and recoverable.

---

### Principle 4 — Require Verification

Do not accept unsupported completion claims:

```text
It should work.
```

Require:

```text
I verified it works because...
```

with evidence.

---

### Principle 5 — Treat Failures as Control Gaps

Frame incident review around missing or ineffective controls:

```text
What control was missing?
```

---

## Harness Architecture

### Reference Architecture

```text
User Request
      │
      ▼
Context Layer          ← AGENTS.md: rules, Blocked list, Completion Gate
      │
      ▼
Tool Layer             ← controlled tools with schemas and permission checks
      │
      ▼
Enforcement Layer      ← hooks/run.py dispatches to pre_tool_use/*.py
      │                    bouncer.py             AGENTS.md ## Blocked policy
      │                    secrets_guard.py       credential reads and exfiltration
      │                    database_guard.py      DROP / TRUNCATE / WHERE-less DELETE
      │                    git_guard.py           force push / hard reset / branch destruction
      │                    communication_guard.py email / Slack / SMS without approval
      ▼
Execution
      │
      ▼
                       ← hooks/run.py dispatches to post_tool_use/*.py
                           audit_logger.py records every tool call
      │
      ▼
Verification Layer     ← hooks/run.py dispatches to stop/*.py
      │                    completion_gate.py gates on AGENTS.md ## Completion Gate
      │                    independent QA, automated checks, evidence required
      ▼
Approved Output
```

The dispatcher (`hooks/run.py`) is the single entry point wired in
`.claude/settings.json`. It discovers `*.py` files in each event
subdirectory alphabetically and runs them in order. Adding a new check
means dropping a file — no settings changes required.

---

## Context Layer

Provide the model with:

- Current state
- Project constraints
- Governance rules
- Historical context
- Available capabilities

---

### AGENTS.md

Each project should maintain a dedicated AI operating manual.

#### Structure

```markdown
# AGENTS.md

## Project Identity
Domain: [fintech | healthcare | e-commerce | infrastructure | saas | general]
Team: [solo | small-team | org]
Timezone: [IANA timezone — e.g. America/Toronto]

## Project Tracker
Tool: [GitHub Projects | Jira | Linear | Asana | other]
Integration: [MCP server name | REST API | manual]
Task URL pattern: [template — e.g. https://github.com/org/repo/issues/{id}]

## Locale
Language: en-CA              # en-CA | en-US | en-GB | fr-CA
Date format: ISO 8601        # ISO 8601 (YYYY-MM-DD) | DD/MM/YYYY | MM/DD/YYYY

## Voice
Style: engineering           # engineering | scientific | finance | legal | general
Formality: high              # high | medium | low
Verbosity: standard          # terse | standard | comprehensive

## Risk Profile
Default posture: pragmatic   # conservative | pragmatic | permissive
Escalation: [describe when to interrupt vs. proceed with a logged DEVIATION]

## Terminology
# Override framework defaults with project-specific terms.
# Left side is the framework term; right side is what this project calls it.
# DMT: issue
# DIP: implementation plan
# Mandate: ticket

## Allowed

- Read source code
- Search repositories
- Review logs

## Ask First

- Production deployment
- Database migrations
- Billing changes

## Blocked

- `rm -rf`
- `DROP TABLE`
- `git push --force`
- `git push -f`

## Completion Gate

- npx eslint src/
- npx tsc --noEmit
- npx jest --passWithNoTests
```

Both sections are read at runtime by the hook scripts invoked through the
dispatcher (`hooks/run.py`). AGENTS.md is the single source of truth —
write policy once and it is both documented and enforced.

`## Blocked` patterns must be command fragments (not prose) for reliable
substring matching. `## Completion Gate` commands must each exit 0 for the
agent's turn to complete. Omit the section entirely to disable the gate.

---

### Allowed Actions

Actions that do not require approval.

Examples:

- Reading files
- Searching code
- Reviewing documentation
- Running diagnostics

---

### Ask-First Actions

Require explicit approval.

Examples:

- Deployments
- Data migrations
- Customer-facing changes
- Cost-incurring operations

---

### Blocked Actions

Never permitted.

Examples:

- Destructive shell commands
- Production data deletion
- Security bypasses
- Unauthorised infrastructure modifications

---

### Context Management Rules

Keep context:

- Relevant
- Current
- Structured

Avoid:

- Dead-end reasoning
- Old assumptions
- Massive log dumps
- Irrelevant conversation history

---

## Tool Layer

Provide controlled access to capabilities.

### Required Characteristics

#### Clear Input Schema

Example:

```json
{
  "customer_id": "string"
}
```

---

#### Clear Output Schema

Example:

```json
{
  "status": "success",
  "data": {}
}
```

---

#### Validation

Reject:

- Invalid inputs
- Missing parameters
- Unsupported values

---

#### Permission Checks

Verify:

- Identity
- Authorisation
- Scope

before execution.

---

#### Error Handling

Return structured failures.

Example:

```json
{
  "status": "error",
  "message": "Invalid customer ID"
}
```

---

#### Audit Logging

Record:

- Who
- What
- When
- Result

---

### Tool Access Pattern

Uncontrolled access:

```text
Agent
  ↓
Raw Shell Access
```

Controlled access:

```text
Agent
  ↓
Controlled Tool
  ↓
Validated Action
```

---

## Enforcement Layer

Prevent unsafe behaviour regardless of model decisions.

### Prompt Instructions

Example:

```text
Never delete production data.
```

Useful as guidance, but not enforceable.

---

### Enforcement Hooks

The `hooks/` directory provides a ready-to-use implementation. Copy it into
your project and wire it via `hooks/claude_code_settings_template.json` → `.claude/settings.json`.

**The dispatcher** (`hooks/run.py`) is the only script referenced in
`.claude/settings.json`. It discovers `*.py` files in the relevant event
subdirectory and runs them in alphabetical order, feeding each the original
stdin payload:

```
.claude/settings.json
  PreToolUse  → python3 hooks/run.py pre_tool_use
                    ├── bouncer.py             (AGENTS.md ## Blocked policy)
                    ├── secrets_guard.py       (credential reads and exfiltration)
                    ├── database_guard.py      (DROP / TRUNCATE / WHERE-less DELETE)
                    ├── git_guard.py           (force push / hard reset / branch destruction)
                    └── communication_guard.py (email / Slack / SMS without approval)
  PostToolUse → python3 hooks/run.py post_tool_use
                    └── audit_logger.py        (.harnessable/audit.log)
  Stop        → python3 hooks/run.py stop
                    └── completion_gate.py     (AGENTS.md ## Completion Gate)
```

**To add a check:** drop a `.py` file into the relevant subdirectory.
No `settings.json` edit is required.

Exit code protocol:

- `0` — allow, continue
- `2` — block; stderr message is fed back to the agent as the reason

The dispatcher stops at the first exit 2 in each event directory.
Scripts that must never block (e.g. loggers) should handle their own
errors and always exit 0.

Full reference: `references/hooks.md`

---

### Pre-built Guards

Five guards ship in `hooks/pre_tool_use/` and activate by being present
in the directory. Each illustrates a different enforcement principle.

---

#### `database_guard.py` — Intent detection, not keyword blocking

The WHERE-less check is the key distinction: `DELETE FROM orders` destroys
all data; `DELETE FROM orders WHERE id = 42` is safe. A substring match
cannot tell them apart — this guard does.

```text
Agent:   psql -c "DELETE FROM users"
Blocked: DELETE without WHERE would delete every row.
         Add WHERE or have a human run it.

Agent:   psql -c "DELETE FROM users WHERE status = 'inactive'"
Allowed: ✓

Agent:   psql -c "DROP TABLE sessions"
Blocked: Irreversible DDL. Have a human run this after confirming a backup.
```

Also blocks: `DROP DATABASE`, `TRUNCATE`, `UPDATE … SET` without `WHERE`.

---

#### `git_guard.py` — History protection with safe alternatives

Each block message names the safe path so the agent can immediately
propose a corrected command.

```text
Agent:   git push origin main --force
Blocked: Rewrites shared history; destroys others' commits.
         Use --force-with-lease or have a human approve.

Agent:   git reset --hard HEAD~3
Blocked: Permanently discards uncommitted changes.
         Use git stash before resetting.

Agent:   git branch -D feature/old
Blocked: Force-deletes branch even with unmerged commits.
         Use git branch -d (safe delete) instead.
```

Also blocks: remote ref deletion, `git clean -f`, rebase onto shared branches.

---

#### `communication_guard.py` — The chief-of-staff case

Prevents an agent from sending messages on behalf of a human without
approval. The block message instructs the agent to draft and present
for review — not to simply fail.

```text
Agent:   curl -X POST https://api.sendgrid.com/v3/mail/send -d '{...}'
Blocked: All outbound email must be reviewed by a human before sending.
         Draft the message and present it for approval.

Agent:   python3 send_slack.py --channel #board --message "..."
Blocked: Slack messages require human approval before posting.
```

Covers: `sendmail`, SMTP, SendGrid, Mailgun, SES, Slack, Microsoft Graph,
Gmail, Google Calendar, Twilio, and generic outbound POSTs with message payloads.

---

#### `secrets_guard.py` — Hardcoded credential floor

Blocks commands that read or transmit `.env`, `.pem`, `.key`,
`credentials.json`, and credential exfiltration patterns (`printenv`,
`echo $SECRET`, `curl --header Authorization`). Runs unconditionally —
not driven by AGENTS.md.

---

#### `bouncer.py` — Configurable policy from AGENTS.md

Reads `## Blocked` and enforces it at runtime. The team writes their
policy once in AGENTS.md; the bouncer makes it mechanical.

```text
AGENTS.md:  - `git push --force`

Agent:      git push origin main --force
Blocked:    Command matches 'git push --force' from AGENTS.md ## Blocked.
```

---

#### Deployment Hooks

Require:

- Approval
- Validation
- Rollback readiness

---

#### Completion Verification Hooks

Configure domain-specific checks in AGENTS.md `## Completion Gate`.
Each bullet is a shell command that must exit 0 before the agent's turn ends.

Software project example:

```markdown
## Completion Gate

- npx eslint src/
- npx tsc --noEmit
- npx jest --passWithNoTests
```

Executive assistant example:

```markdown
## Completion Gate

- python3 scripts/verify_recipients.py
- python3 scripts/check_calendar_conflicts.py
```

The `completion_gate.py` Stop hook runs these before every turn completes.

---

## Verification Layer

Ensure reality matches claims.

### Standard Workflow

```text
Plan
  ↓
Execute
  ↓
Verify
```

---

### Independent Verification

Preferred:

```text
Architect
   ↓
Engineer
   ↓
Coder
   ↓
QA
```

The implementer should not approve their own work.

---

### Verification Requirements

#### Code

- Tests pass
- Lint passes
- Type checks pass

---

#### Infrastructure

- Health checks pass
- Monitoring healthy

---

#### APIs

- Integration tests pass

---

#### Data

- Constraints verified
- Row counts validated

---

### Completion Rule

Completion requires evidence.

Claims are not evidence.

---

## Context Isolation with Sub-Agents

Prevent context pollution.

### Use Cases

#### Research Agent

Investigates:

- Libraries
- Standards
- Documentation

---

#### Log Analysis Agent

Investigates:

- Errors
- Incidents
- Root causes

---

#### Migration Agent

Investigates:

- Schema impacts
- Compatibility risks

---

### Parent Agent Receives

```text
Inputs
Findings
Recommendations
```

Not the entire investigative history.

---

## Reliability Engineering

### The Reliability Problem

Even highly accurate systems fail in long workflows.

Example:

95% success per step.

20-step workflow:

```text
0.95^20 = 36%
```

Overall success rate: 36%

---

### Reliability Implication

Verification becomes more important as workflow length increases.

---

### Design Goals

Build systems that:

- Detect failures
- Contain failures
- Recover from failures
- Prevent recurrence

---

## Failure Handling

### Failure Review

Workflow:

```text
Failure
   ↓
Root Cause Analysis
   ↓
Harness Improvement
   ↓
Prevention
```

---

### Questions To Ask

What control was missing?

Examples:

- Validation
- Permissions
- Testing
- Monitoring
- Approval workflow
- Retry logic

---

## Observability & Auditability

### Required Logging

Record:

- Tool invocations
- Decisions
- Errors
- Verifications
- Approvals
- Deployments

`hooks/post_tool_use/audit_logger.py` covers tool invocations automatically —
every tool call is appended to `.harnessable/audit.log` (one JSON object per
line) via the PostToolUse dispatcher. Add scripts to `hooks/post_tool_use/`
to capture additional signals (metrics, external alerting, ticket creation).

---

### Example Audit Trail

```text
Request received
Permission validated            ← bouncer.py (PreToolUse)
Tests executed
Deployment executed             ← audit_logger.py records this entry
Health checks passed
Approved
Completed                       ← completion_gate.py passed (Stop)
```

---

## Production Readiness Checklist

### Context

- [ ] AGENTS.md exists
- [ ] Project Identity defined (domain, team, timezone)
- [ ] Project Tracker configured (tool, integration, task URL pattern)
- [ ] Locale configured (language, date format)
- [ ] Voice configured (style, formality, verbosity)
- [ ] Risk Profile set (default posture, escalation threshold)
- [ ] Terminology overrides defined (or confirmed as framework defaults)
- [ ] Allowed actions defined
- [ ] Ask-first actions defined
- [ ] Blocked actions defined
- [ ] Context maintained
- [ ] Sub-agents defined

---

### Tools

- [ ] Input schemas documented
- [ ] Output schemas documented
- [ ] Validation implemented
- [ ] Permission checks implemented
- [ ] Structured errors implemented
- [ ] Audit logging enabled

---

### Enforcement

- [ ] `hooks/` copied into the project
- [ ] `.claude/settings.json` wired from `hooks/claude_code_settings_template.json`
- [ ] AGENTS.md `## Blocked` list populated with command fragments
- [ ] AGENTS.md `## Completion Gate` populated (or consciously omitted)
- [ ] `secrets_guard.py` patterns reviewed for project-specific credential files
- [ ] Human approval gates defined for `## Ask First` actions
- [ ] No unrestricted shell access

---

### Verification

- [ ] Tests mandatory
- [ ] Independent reviewer assigned
- [ ] Objective success criteria defined
- [ ] Health checks automated

---

### Operations

- [ ] Monitoring enabled
- [ ] Audit trail available
- [ ] Failure review process defined
- [ ] Continuous improvement process active

---

## Architect → Engineer → Coder → QA Workflow

### Architect

Produces the **Design Mandate Task (DMT)**, containing:

- Problem statement and motivation
- Success criteria (measurable)
- Constraints (tech, time, compliance)
- Out-of-scope declarations
- Acceptance criteria for QA

---

### Engineer

Produces the **Design Implementation Plan (DIP)**, containing:

- Recon findings
- Architecture decisions
- Ordered implementation steps
- Verification checklists
- Containment checklist

---

### Coder

Produces the **Task Implementation Report (TIR)**, containing:

- Completed work with evidence
- Deviation records
- Verification output (tests, checks, health probes, or domain-specific validators)
- Known limitations

---

### QA

Produces the **QA Verdict**, containing:

- Checks executed with evidence
- Findings (failures with specifics)
- Out-of-scope findings
- Verdict: PASS / CONDITIONAL_PASS / FAIL

---

### Promotion Rule

Artifacts move only when approved by the next stage.

No self-certification.

---

## Implementation Anti-Patterns

### Unrestricted Execution Access

Anti-pattern: unlimited shell access.

**Replace with:** Controlled tools with validated schemas and permission checks.

---

### Prompt-Only Safety Controls

Anti-pattern: relying only on prompt instructions for safety.

```text
Prompt says:  "Never delete production data."
Agent does:   psql -c "DELETE FROM users"   ← nothing stops it
```

**Replace with:** Enforced policies via hooks that run regardless of model decisions.

```text
database_guard.py intercepts:  DELETE without WHERE
Agent receives:                "DELETE without a WHERE clause would delete every row."
Agent cannot proceed.          The instruction is no longer advisory — it is mechanical.
```

---

### Self-Verification

Anti-pattern: allowing the implementer to approve their own work.

**Replace with:** Independent review by a separate role or agent session.

---

### Unbounded Context

Anti-pattern: passing large, unfocused contexts to the model.

**Replace with:** Sub-agents with scoped tasks; summarised findings passed to the parent.

---

### Missing Audit Trail

Anti-pattern: executing work without an audit trail.

**Replace with:** Comprehensive observability — tool invocations, decisions, evidence, and approvals logged.

---

## Quick Reference

### Formula

```text
Agent
=
Model
+
Context
+
Tools
+
Enforcement
+
Verification
+
Observability
```

---

### Final Reference

Models should be deployed with explicit controls.

Agent systems should be verified, observable, and constrained.
