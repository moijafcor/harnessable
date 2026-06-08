# Harnessable — Codex Integration

Harnessable works with Codex through four mechanisms:

1. **`AGENTS.md`** at the repo root — persistent repository instructions
   loaded automatically by Codex at session start. Declares role boundaries,
   blocked actions, and the completion gate.

2. **`.agents/skills/harnessable/SKILL.md`** — skill loaded on demand.
   Invoke with `"Use the harnessable skill."` to load the full role
   protocol, discovery classification table, and knowledge graph obligations
   into the active session.

3. **`docs/harness/models.yaml`** — project-owned model manifest. The
   Orchestrator reads it before commissioning roles so each role can be
   assigned an explicit model/provider/cost tier.

4. **`codex/*.prompt.md` and `codex/examples/`** — role prompt templates. Use
   these as your starting point for each engagement, pipeline, quality
   lifecycle, lightweight, or emergency role rather than writing prompts from
   scratch.

## Install

```bash
bash codex/install.sh /path/to/your-project
```

The script installs `AGENTS.md`, `docs/harness/models.yaml`, and the
harnessable skill. It will not overwrite a customised `AGENTS.md` or
model manifest; it reports `MERGE` so you can merge the Harnessable
blocks without losing project-specific instructions or model choices.

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
verify-only operations and is removed by the Stop hook.

### QA

```bash
codex "$(cat codex/qa.prompt.md)"
```

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
`docs/mandates/inspect/{surface}_{date}_inspection_report.md`.

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
required within 24 hours.

## What AGENTS.md does automatically

Codex loads `AGENTS.md` at session start without being asked. This means:

- Role boundary rules are always active
- Blocked actions (force-push, destructive DB commands, etc.) are declared
  before any work starts
- The completion gate format is enforced on every response
- The model manifest location is declared for Orchestrator commissioning

You do not need to repeat these in your prompts.

## What the skill adds

The skill loads the full protocol when invoked. This adds:

- Detailed role rules (what each role must and must not do)
- The complete discovery classification table including `ONTOLOGY_GAP`
- Knowledge graph obligations (grounding, amendment, PLANNED and DONE gates)
- Required output format per role, including TOM, DMT, DIP, TIR, SIR,
  QA Verdict, SRR, CRR, PIR, IB, CP, EIR, and Spike Branch

Invoke it for any non-trivial mandate. For simple bounded tasks, `AGENTS.md`
alone may be sufficient.

## Models manifest

The Codex installer places the default manifest at
`docs/harness/models.yaml`. Fill the `# REPLACE` model fields for the
providers available to your project. The Orchestrator reads this file at
INITIALISING and should name the selected model when commissioning any role.

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
