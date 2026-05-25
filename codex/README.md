# Harnessable — Codex Integration

Harnessable works with Codex through three mechanisms:

1. **`AGENTS.md`** at the repo root — persistent repository instructions
   loaded automatically by Codex at session start.

2. **`.agents/skills/harnessable/SKILL.md`** — progressive, task-specific
   protocol loading. Invoke with `"Use the harnessable skill."` in any prompt.

3. **`codex/` scripts and examples** — install helper and role prompt
   templates for common harnessable workflows.

## Quick start

```bash
bash codex/install.sh /path/to/your-project
```

This copies AGENTS.md and the harnessable skill into your project.

## Invoking roles

```bash
codex "Use the harnessable skill. Act as Architect.
Define a mandate for adding rate limiting to the public API."

codex "Use the harnessable skill. Act as Engineer.
Produce a DIP for the mandate in docs/mandates/rate-limiting.md."

codex "Use the harnessable skill. Act as Coder.
Implement the DIP at docs/mandates/rate-limiting_implementation_plan.md."

codex "Use the harnessable skill. Act as QA.
Verify the implementation against the DIP and TIR."
```

## Role example prompts

See `codex/examples/` for complete prompt templates per role.

## Guards

Harnessable's enforcement layer is implemented as Claude Code hooks.
For Codex, equivalent guards can be implemented as shell scripts
invoked as pre-commit hooks or CI steps. See `framework/hooks/` for
the reference implementations to adapt.
