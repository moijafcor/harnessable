# AGENTS.md

## Harnessable Protocol

This is the harnessable framework repository. Work here governs the
framework itself — agent protocols, hook scripts, installer, skill
templates, and the knowledge graph. Changes here have downstream
impact on every project that has installed harnessable. Treat
framework changes as higher-stakes than application changes: a broken
hook ships to every deployment on the next back-propagation.

Full framework documentation:

- Role protocols:       `framework/agents/`
- Hook scripts:         `framework/hooks/`
- Skill templates:      `framework/templates/skills/`
- DIP template:         `framework/templates/dip.md`
- Knowledge graph:      `framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml`
- References:           `framework/vendor/harnessable/references/`
- Installer:            `install.sh`
- Deployed projects:    `~/code/your-project.d/` and `~/code/fleet-mcp`

Before non-trivial work:

1. Identify active role: Architect, Engineer, Coder, SRE, QA,
   Security, Reviewer, Inspector, Analyst, Orchestrator, Narrator,
   Spike, or Emergency Responder.
2. Do not combine Coder and QA, or SRE and QA, in the same pass.
3. For implementation work, require a DIP before editing framework
   files or running install.sh against deployed projects.
4. Any change to hook scripts or install.sh must include a
   backward compatibility assessment — do current deployments break?
5. Record deviations, blockers, discoveries, and verification
   evidence in the mandate artifact.
6. Do not claim completion without running the Completion Gate.

## Project Tracker

tool:         GitHub Projects (AdsWireIO org, project 2 — personal board)
owner:        moijafcor
owner_type:   user
project:      2
integration:  MoijafcorGithubProjects MCP (mcp.moisesjafet.com/sse)

Use the MoijafcorGithubProjects MCP tools for board operations:

- `list_project_items`    — read current board state
- `create_project_item`   — file a new mandate
- `update_project_item_field` — advance board status
- `link_issue_to_project` — link a GitHub issue to the board

Required board statuses:

`BACKLOG` · `MANDATED` · `IN_RECON` · `PLANNED` · `IN_PROGRESS` ·
`IN_REVIEW` · `BLOCKED` · `NEEDS_REVISION` · `VERIFIED` · `DONE`

Do not guess project IDs, field IDs, item IDs, or status option IDs.
If a board update cannot be made, record the attempted action and the
missing identifier as a blocker.

## Knowledge Graph

Framework graph: `framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml`

Load the framework graph at session start. Resolve harnessable
framework terms — TOM, DMT, DIP, TIR, IB, CP, CCSkill, hook types,
role names, artifact names — against the framework graph before
acting. File `ONTOLOGY_GAP` for any framework concept encountered
that is not declared in the graph.

No project-specific knowledge graph exists for this repository — the
framework graph IS the project graph.

## Risk Profile

risk_level: high

safety_constraints:

- Hook scripts run inside active Claude Code sessions on production
  codebases. A broken pre_tool_use hook can block all tool use in
  every deployed project. Validate Python syntax after every hook
  edit before committing.
- install.sh runs against deployed project directories. A bug in
  update mode can overwrite customised files or corrupt settings.
  Test both fresh install and update mode before committing.
- Any change to the KNOWLEDGE_GRAPH.yaml must maintain YAML validity.
  Run yaml.safe_load validation before committing.
- Back-propagation (install.sh --update across all deployments)
  is irreversible without a git revert. Confirm backward
  compatibility before triggering a back-propagation run.
- Do not modify agent protocol files without assessing impact on
  deployed projects that may have active sessions using the old
  protocol.
- secrets_guard.py changes are especially high-risk: a logic error
  can either block legitimate operations or fail to block credential
  exfiltration. Test all guard paths explicitly.
- The credential_ops exemption mechanism must never be loosened
  without explicit Architect sign-off in a DIP.

## Ask First

- Any change to pre_tool_use hook behaviour — especially
  secrets_guard.py, bouncer.py, or emergency_gate.py
- Any change to the KNOWLEDGE_GRAPH contract (removing or renaming
  existing concepts)
- Any change to agent protocol that alters a role's artifact format
  (DIP, TIR, IB, CP, SIR, CRR, PIR, EIR, IB)
- Any change to install.sh that could overwrite or delete project
  files during --update mode
- Running install.sh --update against any deployed project

## Locale and Voice

locale: en-CA
voice: framework development, specification-precise, engineering-register
audience: framework adopters, contributors, and the agent sessions
operating under framework governance

Use exact file paths, function names, and command evidence when
reporting framework work. Keep KNOWLEDGE_GRAPH entries terse and
precise. Agent protocol language must be unambiguous — agents follow
it literally.

## Blocked

The bouncer hook enforces this list where supported.

- Do not force-push to main.
- Do not delete or rewrite git history.
- Do not run install.sh --update against deployed projects without
  an Architect mandate authorising the back-propagation.
- Do not commit framework changes without running the Completion Gate.
- Do not commit hook scripts with Python syntax errors.
- Do not commit KNOWLEDGE_GRAPH.yaml without yaml.safe_load validation.
- Do not remove or rename existing KNOWLEDGE_GRAPH concepts without
  a DIP that assesses downstream impact on deployed projects.
- Do not weaken secrets_guard.py blocking logic without a DIP and
  explicit Security role sign-off.

## Completion Gate

Commands that must pass before reporting framework work as complete:

  # Installer syntax
  bash -n install.sh

  # All hook and tool Python syntax
  python3 -m py_compile \
    framework/hooks/pre_tool_use/*.py \
    framework/hooks/post_tool_use/*.py \
    framework/hooks/stop/*.py \
    framework/hooks/pre_compact/*.py \
    framework/tools/*.py

  # KNOWLEDGE_GRAPH YAML validity
  python3 -c "
import yaml
yaml.safe_load(open('framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml'))
print('YAML valid')
"

  # Greenfield install smoke test
  TGF=$(mktemp -d)
  git -C $TGF init && git -C $TGF commit --allow-empty -m "init"
  bash install.sh $TGF 2>&1 | tail -5
  rm -rf $TGF

For mandate-specific work, also run the verification commands
stated in the DIP. If a check requires deployed project access,
record it with the reason and the exact approval needed.

## MCP Servers

MoijafcorGithubProjects MCP:
  url:     mcp.moisesjafet.com/sse
  purpose: GitHub Projects board management (personal board)
  tools:   list_project_items, create_project_item,
           update_project_item_field, link_issue_to_project,
           link_pr_to_project, archive_project_item
  scope:   mandate tracking for harnessable framework development

## Infrastructure

provisioning_tool: Ansible

canonical_path:    # REPLACE: ~/code/ansible/playbooks/
                   # Path to the Ansible playbooks that govern
                   # YOUR-NODE, colo nodes, and your-vendor fleet.

inventory:         # REPLACE: ~/code/ansible/inventory/

principle: >
  Infrastructure changes must be expressed as Ansible playbook
  changes, not executed directly on hosts. An SRE mandate working
  on YOUR-NODE, colo, or your-vendor nodes must reference the relevant
  playbook and role — not a sequence of shell commands. Direct
  host mutations outside Ansible are undocumented drift.

## Communication Channels

The Narrator may draft content for these destinations only when
a mandate declares the audience and approval path:

- docs:       README.md, CHEAT_SHEET.md, references/ Markdown
- changelog:  CHANGELOG.md entries for adopters
- release:    GitHub release notes (plain language, adopter-facing)
- community:  GitHub Discussions, issue responses

All external communications (social, press, email) must remain
drafts until explicitly approved.

## High Risk Surfaces

- pre_tool_use hook modifications (run in every active session)
- secrets_guard.py logic changes
- install.sh --update mode changes
- KNOWLEDGE_GRAPH concept removal or rename
- DIP or TIR artifact format changes (breaks deployed validation)
