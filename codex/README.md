# Harnessable — Codex Integration

Harnessable works with Codex through five mechanisms:

1. **`AGENTS.md`** at the repo root — persistent repository instructions
   loaded automatically by Codex at session start. Declares role boundaries,
   blocked actions, and the completion gate.

2. **`.agents/skills/harnessable/SKILL.md`** — skill loaded on demand.
   Invoke with `"Use the harnessable skill."` to load the full role
   protocol, discovery classification table, and knowledge graph obligations
   into the active session.

3. **`docs/harness/models.yaml`** — project-owned model manifest. The
   Orchestrator reads it before commissioning roles so each role can be
   assigned an explicit model/provider/cost tier and `cost_per_1k_tokens`
   values for budget reporting.

4. **`WORLD_MODEL.md` and `world_models/`** — project-owned operational
   knowledge. `WORLD_MODEL.md` is a thin discovery index; real topology,
   vendor capabilities, failure patterns, and known edge cases live in
   focused `world_models/*_world_model.md` files.

5. **`codex/*.prompt.md` and `codex/examples/`** — role prompt templates. Use
   these as your starting point for each engagement, pipeline, quality
   lifecycle, lightweight, or emergency role rather than writing prompts from
   scratch.

## Install

```bash
bash codex/install.sh /path/to/your-project
```

The script installs `AGENTS.md`, `WORLD_MODEL.md`, three
`world_models/*_world_model.md` seed files, `docs/harness/models.yaml`,
`docs/harness/templates/per.md`, `docs/harness/templates/er.md`,
`docs/mandates/per/`, `docs/evolutions/`, `docs/incidents/`, and the
harnessable skill. It will not overwrite a
customised `AGENTS.md`, `WORLD_MODEL.md`, world model file, or model manifest;
it reports `MERGE` where manual review is needed so you can merge Harnessable
blocks without losing project-specific instructions, operational knowledge,
model choices, or model cost values.

To install the full enforcement layer (hooks, guards, audit logger,
completion gate), run the root installer from this checkout:

```bash
bash install.sh /path/to/your-project
```

That installer currently wires Claude Code lifecycle hooks. Codex uses the
protocol through `AGENTS.md`, the model manifest, the Harnessable skill,
prompt templates, and explicit verification commands in the DIP.

## Invoking roles

### Engagement Track

#### Orchestrator

```bash
codex "$(cat codex/orchestrator.prompt.md)"
```

Orchestrator receives marketplace signals, classifies the engagement as
templated or novel, authors or revises Target Outcome Mandates (TOMs),
commissions domain Architects per constituent TOM, and judges DONE against
the parent TOM Target Outcomes. It reads `docs/harness/models.yaml` before
commissioning roles and declares the selected model per commission. It does
not implement, write DIPs, or write code.

### Core Pipeline

### Architect

```bash
codex "$(cat codex/architect.prompt.md)"
```

Or inline:

```bash
codex "Use the harnessable skill. Act as Architect.
Define a mandate for: [describe the work here]."
```

### Engineer

```bash
codex "$(cat codex/engineer.prompt.md)"
```

Engineer starts by scanning `docs/harness/agents/*.md` and reading each
role's `## Role Scope`, then scanning `world_models/`. It maps every mandate
step to the live roster, files a Protocol Enhancement Request (PER) at
`docs/mandates/per/PER-{NNN}.md` when no role fits, and includes an Execution
Manifest in every DIP so the operator knows the exact `/role dip-path`
sequence to run.

### Coder

```bash
codex "$(cat codex/coder.prompt.md)"
```

### SRE

```bash
codex "$(cat codex/sre.prompt.md)"
```

If the full enforcement layer is installed, the SRE protocol is at
`docs/harness/agents/sre.md`. Key requirements before starting: the DIP must
have a `## Rollback Procedure` section and a blast radius declaration, or the
SRE must file a BLOCKER before proceeding. If the DIP declares credential
files in `## Credential Operations`, the SRE must create the session-scoped
`.harnessable/credential_ops.json` before credential steps; it permits only
verify-only operations and is removed by the Stop hook. SRE also reads
`WORLD_MODEL.md` as the discovery index, scans `world_models/`, reads relevant
`*_world_model.md` files before operational work, classifies the failure mode
using the classifier pattern in `references/classifier.md` and taxonomy in
`references/error-modes.md`, and does not act on a `Loop permitted: NO` mode
without human approval. For below-horizon failures, SRE backs off by packaging
observable state and declaring the lower-layer access needed instead of
retrying at the wrong layer. After resolution, SRE updates the relevant
`world_models/{domain}_world_model.md` file when an incident reveals a new
failure pattern, vendor capability, or edge case, or records that no update is
required.

### Designer

```bash
codex "$(cat codex/designer.prompt.md)"
```

Designer is the asset production pipeline role. It produces pixel-precise
SVG masters, raster exports, favicons, OG images, or visual asset packages
from complete written specifications. Its output is an Asset Package (AP),
not running code. It never makes aesthetic decisions; missing geometry,
colour, typography, opacity, size, or output path values are
`DESIGN_AMBIGUITY` blockers.

### QA

```bash
codex "$(cat codex/qa.prompt.md)"
```

QA is the grader in the harnessable Rubric loop. It evaluates DMT
Acceptance Criteria, DIP Verification Checklists, and the AGENTS.md
Completion Gate, then derives PASS / CONDITIONAL_PASS / FAIL from the
Per-Criterion Verdict Table. OPERATOR criteria require direct review of
human-captured evidence; PLAYWRIGHT criteria require QA to re-run the
browser test independently. QA is also the fresh-context classifier for
verification failures and uses `references/classifier.md` plus
`references/error-modes.md` to decide whether retry, blocker, rollback,
context discard, back-off, or escalation is appropriate. The classifier holds
stop authority for `Loop permitted: NO` modes.
FAIL, or CONDITIONAL_PASS returned to
NEEDS_REVISION, must include targeted handoff blocks per failing criterion.

### Security

Security review is invoked only when the Architect flagged the mandate for Security
review in the DMT. It runs after QA PASS or CONDITIONAL_PASS.

```bash
codex "$(cat codex/security.prompt.md)"
```

If the full enforcement layer is installed, the Security protocol is at
`docs/harness/agents/security.md`. Before starting: confirm QA has already
issued PASS or CONDITIONAL_PASS, and confirm the Architect explicitly flagged
the mandate in the DMT.

### Quality Lifecycle

Reviewer, Inspector, Analyst, and Narrator run outside the core pipeline. They
do not produce PASS / FAIL verdicts and do not block pipeline progress. The
Reviewer, Inspector, and Analyst self-close at DONE without Architect
acceptance; Narrator runs when commissioned by the Orchestrator.

#### Reviewer

```bash
codex "$(cat codex/reviewer.prompt.md)"
```

Reviewer reads source for structural correctness and files a Code Review Report
(CRR) at `docs/mandates/review/{component}_{date}_code_review_report.md`.

#### Inspector

```bash
codex "$(cat codex/inspector.prompt.md)"
```

Inspector examines traffic or replayed scenarios and files a Protocol
Inspection Report (PIR) at
`docs/mandates/inspect/{surface}_{date}_inspection_report.md`. For DIP
steps declared as `[PLAYWRIGHT]`, Inspector treats Playwright as a
first-class verification instrument, executes the declared test
independently, and captures stdout, exit code, and screenshot path.

#### Analyst

```bash
codex "$(cat codex/analyst.prompt.md)"
```

Analyst gathers intelligence from outside the codebase — competitor moves,
user pain signals, practitioner discourse, technology shifts — and synthesises
it into an Intelligence Brief (IB) at
`docs/mandates/research/{domain}_{date}_intelligence_brief.md`. The primary
instrument is `docs/harness/tools/web_verify.py`. Every claim in the IB
requires a fetched URL and date — training knowledge is not a source.

#### Narrator

```bash
codex "$(cat codex/narrator.prompt.md)"
```

Narrator reads finished DIPs and `AGENTS.md ## Communication Channels`, then
produces a destination-calibrated Communication Package (CP) at
`narrator-out/{feature-slug}/`. It creates one artifact per declared audience
without exposing implementation details to non-technical destinations.

### External-Facing Track

#### Project Manager

```bash
codex "$(cat codex/pm.prompt.md)"
```

Project Manager connects external stakeholders to the technical team. PM
handles intake, status reports, stakeholder communication, calendar
commitments, administrative work, and deployment of Narrator Communication
Packages. PM routes technical decisions to the Orchestrator and does not
author TOMs or DIPs, commission pipeline roles, verify implementations, or
commit to technical timelines without Orchestrator sign-off.

### Self-Improvement Track

#### Evolver

```bash
codex "$(cat codex/evolver.prompt.md)"
```

Evolver acts on what the Dreamer named. It reads accumulated Dream Reports
and open PERs, checks `AGENTS.md ## Evolver` thresholds, applies one of five
roster actions (`CREATE`, `MUTATE`, `MERGE`, `DEPRECATE`, `EXTINCT`) when
evidence warrants, writes an Evolution Report at
`docs/evolutions/ER-{NNN}.md`, resolves or declines PERs, and updates
`.harnessable/last_evolution.json`. Evolver does not read raw corpus
artifacts directly and does not produce implementation artifacts.

### Lightweight Track

#### Spike

```bash
codex "$(cat codex/spike.prompt.md)"
```

Spike is for micro-fixes, exploratory spikes, impromptu improvements, and
prototypes that are too small for the full pipeline but still need a trail. It
arms `.harnessable/spike_gate` when the full enforcement layer is installed,
creates or resumes a descriptive `spike/*` branch, declares a time box and
scope boundary, and exits by PR, abandonment note, or escalation to the full
pipeline.

### Break Glass

#### Emergency Responder

```bash
codex "$(cat codex/emergency.prompt.md)"
```

Emergency Responder is for production break-glass work. It does not require a
pre-existing DMT or DIP. The Emergency Investigation Report (EIR) is created
before the first change. When the full enforcement layer is installed, the
Emergency prompt arms `.harnessable/emergency_gate`, which blocks code edits
until a local EIR exists. The `AGENTS.md` Safety Floor still applies, and the
session ends at `NEEDS_REVISION` with retroactive Engineer, Coder, and QA work
required within 24 hours. Any new operational knowledge from the incident
must be encoded in the relevant `world_models/{domain}_world_model.md`, or
the EIR must state "no new pattern".
Failed emergency attempts are classified before retry; below-horizon symptoms
are packaged with last known good state, attempted actions, exhaustion
evidence, and required lower-layer access.

## What AGENTS.md does automatically

Codex loads `AGENTS.md` at session start without being asked. This means:

- Role boundary rules are always active
- Blocked actions (force-push, destructive DB commands, etc.) are declared
  before any work starts
- The completion gate format is enforced on every response
- The model manifest location is declared for Orchestrator commissioning

You do not need to repeat these in your prompts.

## World Model

The Codex installer creates a thin `WORLD_MODEL.md` discovery index,
`world_models/fleet_world_model.md`, `world_models/vendor_world_model.md`,
`world_models/staging_world_model.md`, and `docs/incidents/` when absent.
These files are project-owned and never overwritten by updates.

`world_models/` contains operational infrastructure knowledge. In a public
repository, add `world_models/` to `.gitignore` before adding real IPs, node
names, service names, or dependency graphs.

SRE and Emergency sessions scan `world_models/` before operational action and
update the relevant `*_world_model.md` before closing any incident that
reveals a new failure pattern, vendor capability, or known edge case.

## What the skill adds

The skill loads the full protocol when invoked. This adds:

- Detailed role rules (what each role must and must not do)
- The complete discovery classification table including `ONTOLOGY_GAP`
- Knowledge graph obligations (grounding, amendment, PLANNED and DONE gates)
- Dynamic roster obligations for Engineer: Role Roster scan, PER filing for
  missing capabilities, and Execution Manifest authoring
- Token Budget guidance: model cost fields in `docs/harness/models.yaml`,
  session cost logs, and `session_cost_report.py` when logs are available
- Classifier obligations: use `references/classifier.md` for separation,
  stop authority, observability layers, visibility horizon, and back-off
  strategy; use `references/error-modes.md` for the taxonomy
- Rubric obligations for QA: three layers, per-criterion verdict table, and
  NEEDS_REVISION handoff
- Evolution obligations for Evolver: Dream Report and PER intake, five roster
  actions, Evolution Report, and `last_evolution.json`
- Required output format per role, including TOM, DMT, DIP, TIR, SIR,
  AP, QA Verdict, SRR, CRR, PIR, IB, CP, ER, EIR, and Spike Branch

Invoke it for any non-trivial mandate. For simple bounded tasks, `AGENTS.md`
alone may be sufficient.

## Models manifest

The Codex installer places the default manifest at
`docs/harness/models.yaml`. Fill the `# REPLACE` model fields for the
providers available to your project, including `cost_per_1k_tokens.input` and
`cost_per_1k_tokens.output` for every role. The Orchestrator reads this file
at INITIALISING and should name the selected model when commissioning any
role. Cost values are used by session cost reporting; leave them explicit so
budget reviews can compare spend by role, mandate, and model.

## Token Budget

Full Harnessable installs include Claude Code stop-hook token logging:
`hooks/stop/session_cost.py` delegates to
`docs/harness/tools/session_cost.py` and appends
`.harnessable/logs/session-cost.YYYY-MM.jsonl`. The reporting tool
`docs/harness/tools/session_cost_report.py` summarises logs by role, mandate,
and model.

Codex-only installs do not receive Claude Code stop-hook payloads
automatically. They still install the model manifest with cost fields, and can
read reports from logs produced by the full enforcement layer or by manual
calls to `session_cost.py` when token counts are available.

## Knowledge graph

For projects with domain-specific terminology (multiple ad platforms,
regulated industries, unfamiliar codebases), create a project knowledge
graph before running mandates. The Codex installer warns when this file is
missing.

```yaml
# docs/knowledge-graph.yaml
meta:
  version: "0.1.0"
  layer: project
  extends: docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml
  project: your-project-name

namespaces:
  your_domain:
    description: Concepts specific to this project.
    source: internal
```

Reference it in each prompt:

```text
Project knowledge graph: docs/knowledge-graph.yaml
```

If the full enforcement layer is not installed, set `extends` to the location
where your project vendors the Harnessable framework graph, or to the graph in
this checkout. Agents will file `ONTOLOGY_GAP` discoveries for any concept
they encounter that is not declared in the graph.

## Guards for Codex

Harnessable's enforcement layer is implemented as Python hooks for Claude Code.
For Codex, equivalent checks can be run as:

- **Pre-commit hooks** — run `hooks/pre_tool_use/*.py` as shell guards
- **CI steps** — validate TIR evidence before merging
- **Explicit checks in prompts** — include verification commands in the DIP
  and require the Coder to run them and paste output

The guards themselves (`database_guard.py`, `git_guard.py`, etc.) are
standalone Python scripts that read a JSON payload from stdin. They can be
adapted for any runtime that supports pre-execution interception.

## Updating

To update the harnessable skill after a new release, start with a clean
working tree in the target project, then run:

```bash
bash codex/install.sh --update /path/to/your-project
```

`--update` refuses to run over uncommitted target changes. It syncs the
Harnessable skill and version pin, reports `OK` for current files, and
reports `MERGE` if `AGENTS.md` has project customisations that need manual
review.

After updating:

```bash
git -C /path/to/your-project status
git -C /path/to/your-project add -A
git -C /path/to/your-project commit -m "chore: sync harnessable Codex adapter"
```

Review release notes for changes to role obligations or discovery classes
before updating active mandates.
