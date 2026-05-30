# Harnessable — Codex Integration

Harnessable works with Codex through three mechanisms:

1. **`AGENTS.md`** at the repo root — persistent repository instructions
   loaded automatically by Codex at session start. Declares role boundaries,
   blocked actions, and the completion gate.

2. **`.agents/skills/harnessable/SKILL.md`** — skill loaded on demand.
   Invoke with `"Use the harnessable skill."` to load the full role
   protocol, discovery classification table, and knowledge graph obligations
   into the active session.

3. **`codex/examples/`** — role prompt templates. Use these as your starting
   point for each pipeline, quality lifecycle, or emergency role rather than
   writing prompts from scratch.

## Install

```bash
bash codex/install.sh /path/to/your-project
```

The script installs `AGENTS.md` and the harnessable skill. It will not
overwrite a customised `AGENTS.md`; it reports an `ACTION` item so you can
merge the Harnessable blocks into the existing repo-level instructions.

To install the full enforcement layer (hooks, guards, audit logger,
completion gate), run the root installer from this checkout:

```bash
bash install.sh /path/to/your-project
```

That installer currently wires Claude Code lifecycle hooks. Codex uses the
protocol through `AGENTS.md`, the Harnessable skill, prompt templates, and
explicit verification commands in the DIP.

## Invoking roles

### Core Pipeline

### Architect

```bash
codex "$(cat codex/examples/architect.prompt.md)"
```

Or inline:

```bash
codex "Use the harnessable skill. Act as Architect.
Define a mandate for: [describe the work here]."
```

### Engineer

```bash
codex "$(cat codex/examples/engineer.prompt.md)"
```

### Coder

```bash
codex "$(cat codex/examples/coder.prompt.md)"
```

### SRE

```bash
codex "$(cat codex/examples/sre.prompt.md)"
```

If the full enforcement layer is installed, the SRE protocol is at
`docs/harness/agents/sre.md`. Key requirements before starting: the DIP must
have a `## Rollback Procedure` section and a blast radius declaration, or the
SRE must file a BLOCKER before proceeding.

### QA

```bash
codex "$(cat codex/examples/qa.prompt.md)"
```

### Security

Security review is invoked only when the Architect flagged the mandate for Security
review in the DMT. It runs after QA PASS or CONDITIONAL_PASS.

```bash
codex "$(cat codex/examples/security.prompt.md)"
```

If the full enforcement layer is installed, the Security protocol is at
`docs/harness/agents/security.md`. Before starting: confirm QA has already
issued PASS or CONDITIONAL_PASS, and confirm the Architect explicitly flagged
the mandate in the DMT.

### Quality Lifecycle

Reviewer and Inspector run outside the core pipeline. They produce findings
and child mandates, not PASS / FAIL verdicts, and they do not block pipeline
progress.

#### Reviewer

```bash
codex "$(cat codex/examples/reviewer.prompt.md)"
```

Reviewer reads source for structural correctness and files a Code Review Report
(CRR) at `docs/mandates/review/{component}_{date}_code_review_report.md`.

#### Inspector

```bash
codex "$(cat codex/examples/inspector.prompt.md)"
```

Inspector examines traffic or replayed scenarios and files a Protocol
Inspection Report (PIR) at
`docs/mandates/inspect/{surface}_{date}_inspection_report.md`.

### Lightweight Track

#### Spike

```bash
codex "$(cat codex/examples/spike.prompt.md)"
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
codex "$(cat codex/examples/emergency.prompt.md)"
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

You do not need to repeat these in your prompts.

## What the skill adds

The skill loads the full protocol when invoked. This adds:

- Detailed role rules (what each role must and must not do)
- The complete discovery classification table including `ONTOLOGY_GAP`
- Knowledge graph obligations (grounding, amendment, PLANNED and DONE gates)
- Required output format per role, including DMT, DIP, TIR, SIR, QA Verdict,
  SRR, CRR, PIR, EIR, and Spike Branch

Invoke it for any non-trivial mandate. For simple bounded tasks, `AGENTS.md`
alone may be sufficient.

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

To update the harnessable skill after a new release, rerun:

```bash
bash codex/install.sh /path/to/your-project
```

Review the changelog for changes to role obligations or discovery classes
before updating — these affect active mandates.
