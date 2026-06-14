# Codex World Model Scout Index Sync Mandate

Date: 2026-06-14

## Active Roles

- Architect: operator request accepted from current session.
- Engineer: scope and verification plan recorded in this artifact.
- Coder: Codex prompt, example, README, and compatibility test updates.
- QA: not performed by this session; independent QA remains required for formal DONE.

## Target Outcome

Codex World Model Scout guidance must match the framework skill refactor in
commit `765b501`, which added a final step requiring `WORLD_MODEL.md` index
maintenance after `world_models/*_world_model.md` files are created or updated.

## Acceptance Criteria

- `codex/world_model_scout.prompt.md` instructs Codex to update
  `WORLD_MODEL.md` after the population pass.
- `codex/examples/world_model_scout.prompt.md` includes the same obligation in
  compact form.
- `codex/README.md` tells adopters that World Model Scout updates the root
  discovery index.
- `tests/codex_rubric_compatibility.sh` asserts the Codex prompt, example, and
  README contain `WORLD_MODEL.md` index guidance.

## Design Implementation Plan

1. [Coder] Add a final index-update section to the main Codex World Model Scout
   prompt, preserving safety rules: no secrets, no overwrites of world model
   files, no commit.
2. [Coder] Add compact index guidance to the example prompt.
3. [Coder] Update Codex README description.
4. [Coder] Extend compatibility assertions.
5. [Coder] Run mandate-specific tests and the AGENTS.md Completion Gate.

## Backward Compatibility Assessment

No hook scripts, installer logic, agent role protocol files, or knowledge graph
contracts are changed. Existing deployments do not break at runtime. The change
only updates Codex-facing prompt/documentation surfaces so future Codex World
Model Scout runs also maintain `WORLD_MODEL.md`.

## Project Tracker

Board update not performed: MoijafcorGithubProjects MCP tools are not available
in this Codex tool context. Missing identifier/tooling recorded as a blocker for
board-state mutation only; local implementation can proceed.

## Verification Checklist

- `bash tests/codex_rubric_compatibility.sh`
- AGENTS.md Completion Gate:
  - `bash -n install.sh`
  - `python3 -m py_compile framework/hooks/pre_tool_use/*.py framework/hooks/post_tool_use/*.py framework/hooks/stop/*.py framework/hooks/pre_compact/*.py framework/tools/*.py`
  - `python3 -c "import yaml; yaml.safe_load(open('framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml')); print('YAML valid')"`
  - greenfield install smoke test

## Task Implementation Report

Implemented:

- Updated `codex/world_model_scout.prompt.md` with a final
  `WORLD_MODEL.md` index maintenance step.
- Updated `codex/examples/world_model_scout.prompt.md` with compact index
  guidance.
- Updated `codex/README.md` to describe root discovery index maintenance.
- Updated `tests/codex_rubric_compatibility.sh` to assert index guidance.

Verification evidence:

- `bash tests/codex_rubric_compatibility.sh` -> `codex_rubric_compatibility: OK`
- `bash -n install.sh` -> exit 0
- `python3 -m py_compile framework/hooks/pre_tool_use/*.py framework/hooks/post_tool_use/*.py framework/hooks/stop/*.py framework/hooks/pre_compact/*.py framework/tools/*.py` -> exit 0
- `python3 -c "import yaml; yaml.safe_load(open('framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml')); print('YAML valid')"` -> `YAML valid`
- Greenfield install smoke test in temporary git repo -> printed installer next
  steps and exited 0

Completion Gate: PASS.
