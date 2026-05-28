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
   point for each pipeline stage rather than writing prompts from scratch.

## Install

```bash
bash codex/install.sh /path/to/your-project
```

The script installs `AGENTS.md` and the harnessable skill. It will not
overwrite an existing `AGENTS.md` — instead it prints the blocks to merge
manually, which is the right behaviour for projects that already have
repo-level instructions.

To install the full enforcement layer (hooks, guards, audit logger,
completion gate):

```bash
cp -r framework/ /path/to/your-project/docs/harness/
```

See the root Getting Started section for wiring hooks into Codex when
lifecycle hooks are available in your runtime.

## Invoking roles

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
codex "Use the harnessable skill. Act as SRE.
Read the DIP at docs/mandates/[path]. Execute the infrastructure mandate."
```

The SRE protocol is at `docs/harness/agents/sre.md`. Key requirements before
starting: the DIP must have a `## Rollback Procedure` section and a blast
radius declaration, or the SRE must file a BLOCKER before proceeding.

### QA

```bash
codex "$(cat codex/examples/qa.prompt.md)"
```

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
- Required output format per stage (DMT, DIP, TIR, QA Verdict)

Invoke it for any non-trivial mandate. For simple bounded tasks, `AGENTS.md`
alone may be sufficient.

## Knowledge graph

For projects with domain-specific terminology (multiple ad platforms,
regulated industries, unfamiliar codebases), create a project knowledge
graph before running mandates:

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

Agents will file `ONTOLOGY_GAP` discoveries for any concept they encounter
that is not declared in the graph.

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

To update the harnessable skill after a new release:

```bash
# Pull the new release into your vendor directory
cp path/to/harnessable/.agents/skills/harnessable/SKILL.md \
   your-project/.agents/skills/harnessable/SKILL.md

# Update the version pin
cat path/to/harnessable/framework/vendor/harnessable/HARNESSABLE_VERSION \
  > your-project/.agents/skills/harnessable/HARNESSABLE_VERSION
```

Review the changelog for changes to role obligations or discovery classes
before updating — these affect active mandates.
