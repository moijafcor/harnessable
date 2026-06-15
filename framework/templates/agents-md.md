# AGENTS.md

## Source of Truth

# CRITICAL: world_models/ is the authoritative source
# for infrastructure topology, vendor capabilities,
# failure patterns, and operational knowledge.
#
# Claude project memory (~/.claude/projects/{hash}/memory/)
# is written by the model, lives outside the repository,
# is not version-controlled, and may be arbitrarily stale.
#
# Precedence (highest to lowest):
#   1. world_models/*.md          — authoritative
#   2. AGENTS.md declarations     — authoritative
#   3. WORLD_MODEL.md index       — authoritative
#   4. Claude project memory      — supplementary only,
#                                   treat as potentially stale
#
# When project memory conflicts with world_models/:
#   world_models/ wins.
#   Flag the conflict in your output.
#   Do not silently defer to project memory.
#
# Always read world_models/ before acting.
# Always flag stale project memory when detected.

## Harnessable {Project Name} Protocol

```text
REPLACE: Write 2-3 sentences describing what this project is and
what harnessable governs here. Example:
"This is the backend API for {project}. Work here governs the
core business logic, data layer, and external integrations.
Changes to auth/authz or the tenant isolation boundary require
Security role sign-off."
```

Full framework documentation:

- Framework references: `docs/harness/vendor/harnessable/references/`
- Framework graph:      `docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml`
- Role protocols:       `docs/harness/agents/`
- Harnessable upstream: `/home/ubuntu/code/harnessable/README.md`

Before non-trivial work:

1. Identify active role: Architect, Engineer, Coder, SRE, QA,
   Security, Reviewer, Inspector, Analyst, Orchestrator, Narrator,
   Spike, or Emergency Responder.
2. Do not combine Coder and QA, or SRE and QA, in the same pass.
   Security must not be the Coder, SRE, or QA for the same mandate.
3. For implementation work, require a DIP before editing code
   or touching live systems.
4. For infrastructure or operational work, require an SRE mandate
   unless the Emergency Responder role is explicitly invoked.
5. Record deviations, blockers, discoveries, and verification
   evidence in the mandate artifact.
6. Do not claim completion without running the Completion Gate.

## Project Tracker

```text
REPLACE: Fill tracker details for this project.
```

tool:         # GitHub Projects | Jira | Linear | Asana
owner:        # org or username
owner_type:   # org | user
project:      # project number
integration:  # MoijafcorGithubProjects MCP | gh CLI | REST API | manual

Expected GH CLI / MCP patterns:

- `list_project_items` or `gh project item-list` to read board state.
- `create_project_item` or `gh issue create` to file new mandates.
- `update_project_item_field` or `gh project item-edit` to advance status.
- `gh api graphql` to discover project IDs, field IDs, item IDs, and
  status option IDs when they are not supplied.

Required board statuses:

`BACKLOG` · `MANDATED` · `IN_RECON` · `PLANNED` · `IN_PROGRESS` ·
`IN_REVIEW` · `BLOCKED` · `NEEDS_REVISION` · `VERIFIED` · `DONE`

Do not guess project IDs, field IDs, item IDs, or status option IDs.
If a board update cannot be made, record the attempted action and the
missing identifier as a blocker.

## Knowledge Graph

Framework graph: `docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml`
Project graph:   `docs/knowledge-graph.yaml`

Load both graphs at session start. If `docs/knowledge-graph.yaml`
is absent, treat project-specific terms as ontology gaps until the
graph is bootstrapped from
`docs/harness/vendor/harnessable/templates/knowledge-graph.yaml`.

```text
REPLACE: List project-specific domain terms that must be grounded
in the knowledge graph before the agent acts. Examples:
Resolve {ProjectName} domain terms — {term1}, {term2}, {term3} —
against the project graph before acting.
File ONTOLOGY_GAP for any concept encountered that is not declared.
```

## Risk Profile

risk_level: # REPLACE: low | medium | high | critical

safety_constraints:

```text
REPLACE: List project-specific safety constraints. Be explicit.
Examples:
- Do not touch live systems without an SRE mandate or explicit
  human approval in the current session.
- Prefer read-only reconnaissance until the DIP authorises a change.
- Never expose secret values. Credential checks must be verify-only:
  existence, permissions, checksums, or line counts only.
- Database mutations require explicit mandate scope and
  rollback/restore evidence.
- External documentation and provider facts must be verified live
  before they appear in a DIP or runbook.
```

## Ask First

```text
REPLACE: List surfaces where the agent must stop and ask before
acting. These feed spike.md's high-risk surface enforcement.
Examples:
- Production deployments of any kind
- Database schema changes or migrations
- External service configuration (OAuth, webhooks, DNS)
- Billing, subscription, or pricing changes
- Changes to authentication or authorisation logic
```

## Locale and Voice

locale:   # REPLACE: en-CA | en-US | en-GB | es | pt-BR | fr-CA
voice:    # REPLACE: technical | engineering | operations | product
audience: # REPLACE: who reads the output of work on this project

```text
REPLACE: Add any audience-specific communication guidance.
Example: "Use exact dates, hostnames, paths, and command evidence
when reporting operational work. Keep summaries clear enough for
non-implementing stakeholders."
```

## Blocked

The bouncer hook enforces this list where supported.

```text
REPLACE: Add project-specific blocked operations. Be specific.
Include the reason where it is not obvious.
```

- Do not force-push.
- Do not delete branches.
- Do not run destructive database commands (DROP, TRUNCATE,
  DELETE/UPDATE without a precise WHERE clause).
- Do not read, print, copy, or expose secrets outside approved
  credential operations.
- Do not send external communications without human approval.
- Do not modify .git/ internals, rewrite history, hard reset,
  or remove untracked user work.

## Completion Gate

Run the project test suite before closing any mandate.
Replace this placeholder with the actual test command for this project.

**This placeholder must be replaced. Do not execute it as written.**

```text
REPLACE THIS with the project's actual test commands, e.g.:
PHP/Laravel:  php artisan test --compact
Python:       python3 -m pytest
Node:         npm test
Ruby:         bundle exec rspec
Go:           go test ./...
General:      git diff --check
```

- echo "ERROR: Completion Gate not configured for this project. Update AGENTS.md." && exit 1

For mandate-specific work, also run the verification commands
stated in the DIP. If a check requires network, credentials, live
hosts, or other approval, record it as not run with the reason and
the exact approval needed.

## MCP Servers

```text
REPLACE: Declare MCP servers available to agent sessions,
or explicitly state none.

Example:
MoijafcorGithubProjects MCP:
  url:     mcp.moisesjafet.com/sse
  purpose: GitHub Projects board management
  tools:   list_project_items, create_project_item,
           update_project_item_field, link_issue_to_project
  scope:   mandate tracking

If none: "No project-specific MCP servers are declared."
```

## Infrastructure

```text
Declares the canonical tooling for provisioning and managing
infrastructure in this project. All agents must plan and verify
infrastructure changes through this tooling — not directly on hosts.
Direct mutations outside the canonical tool are undocumented drift.

REPLACE: Choose your provisioning tool and fill in the paths.
Common values for provisioning_tool:
  Ansible | Terraform | Pulumi | CDK | Helm | Chef | Puppet | manual
Use manual only when no IaC tooling exists — and explain why.
```

provisioning_tool: # REPLACE: Ansible | Terraform | Pulumi | CDK |
                   #          Helm | Chef | Puppet | manual (explain why)

canonical_path:    # REPLACE: path to playbooks, modules, stacks,
                   #          or charts — wherever the IaC lives
                   # Ansible example:  ~/code/ansible/playbooks/
                   # Terraform example: ~/code/infra/terraform/
                   # Helm example:      ~/code/helm/charts/

inventory:         # REPLACE: inventory file, state backend, or tfvars
                   #          (omit if not applicable to your tooling)
                   # Ansible example:  ~/code/ansible/inventory/
                   # Terraform example: backend configured in main.tf

principle: >
  Infrastructure changes must be expressed as code changes to the
  declared tooling, not executed directly on hosts. An SRE mandate
  must reference the relevant playbook, module, stack, or chart —
  not a sequence of shell commands. Direct host mutations outside
  the canonical tool are undocumented drift and must be flagged
  as ONTOLOGY_GAP or BLOCKER in the mandate artifact.

## World Model

> **⚠ SECURITY:** `world_models/` contains operational infrastructure
> data. Keep this directory **PRIVATE**. Never commit real IPs, node
> names, or service topology to a public repository.

world_models: world_models/
incidents:    docs/incidents/

```text
Domain world models in this project:
REPLACE: list your *_world_model.md files
→ world_models/fleet_world_model.md
→ world_models/vendor_world_model.md
→ world_models/staging_world_model.md

Cross-repo pointers (private fleet repos):
REPLACE: add pointers to other fleet world models
→ ../your-sre-repo/world_models/infra_world_model.md
```

## Browser Testing

```text
Declares Playwright availability for [PLAYWRIGHT] DIP steps.
If absent or declared as unavailable, [PLAYWRIGHT] steps
cannot execute and QA will issue BLOCKED on browser criteria.
REPLACE: fill in after confirming Playwright installation.
```

playwright:
  available:   # REPLACE: true | false
  runtime:     # REPLACE: node (npx playwright) | python (pytest-playwright)
  version:     # REPLACE: output of `npx playwright --version`
  browsers:    # REPLACE: chromium | firefox | webkit | all
  config:      # REPLACE: path to playwright.config.ts or pytest.ini
               # (omit if using defaults)
  screenshots: # REPLACE: test-results/ (default output directory)

## Models

```text
Declares which model runs each role in this project.
The Orchestrator reads docs/harness/models.yaml at INITIALISING.
REPLACE: fill docs/harness/models.yaml after installing harnessable.
```

manifest: docs/harness/models.yaml

## Token Budget

```text
Optional. Declares cost expectations per role so the
Orchestrator can flag sessions that exceed them.
Used by session_cost_report.py for budget comparison.
Omit if no budget constraints apply.

REPLACE: set per-role budgets or remove this section.
```

```yaml
# token_budget:
#   Architect:    max_usd_per_session: 2.00
#   Engineer:     max_usd_per_session: 1.00
#   Coder:        max_usd_per_session: 0.50
#   SRE:          max_usd_per_session: 1.50
#   QA:           max_usd_per_session: 0.30
#   Orchestrator: max_usd_per_session: 3.00
```

## Communication Channels

```text
The Narrator produces content for these destinations.
REPLACE: Declare channels specific to this project.
Each channel should note its format, audience, and approval path.

Example:
docs_site:    docs.{project}.io  (MDX, feature guides)
api_docs:     docs.{project}.io/api  (OpenAPI changelog style)
landing_page: www.{project}.io  (React panels — hero, features, cta)
blog:         www.{project}.io/blog  (MDX, launch register)
email:        (HTML — tenant blast | prospect outreach | partner)
executive:    concise impact summaries for stakeholders

All email, social, press, customer, partner, or provider
communications must remain drafts until explicitly approved.
```

## Dreamer

# Declares Dreamer thresholds for this deployment.
# debt_monitor.py reads these to calculate pressure.

# REPLACE: tune to pipeline velocity

# dreamer:
#   collapse_threshold: 50
#   nap_threshold:      15
#   debt_critical:      1.5
#   debt_emergency:     3.0

## Evolver

# Declares Evolver thresholds for this deployment.
# The Orchestrator reads these to determine when
# to dispatch the Evolver.

# REPLACE: tune to your fleet velocity and risk tolerance

# evolver:
#   dream_reports_threshold: 4    # Dream Reports before Evolution
#   consecutive_pattern_threshold: 2  # same pattern N Dreams = action
#   per_backlog_threshold: 5      # open PERs before forced Evolution
#
# conservative (low velocity):  dream_reports_threshold: 8
# standard:                     dream_reports_threshold: 4
# aggressive (high velocity):   dream_reports_threshold: 2

## Packages

# Declares installed package adapters for this project.
# Package adapters are governance bridges — the packages
# themselves live at their install paths.
# Agents discover packages via:
#   ls packages/*/PACKAGE.md

# REPLACE: list installed packages or leave empty

# packages:
#   hallmark:
#     installed:   ~/.agents/skills/hallmark/
#     adapter:     packages/hallmark/
#     extends:     Designer
#     commands:    /hallmark, /hallmark-study
#     verify:      ls ~/.agents/skills/hallmark/SKILL.md

## High Risk Surfaces

```text
REPLACE: List project surfaces where mistakes have large blast radius.
Examples:
- Authentication or authorisation changes
- Production deployment workflows
- Database migration and tenant-isolation boundaries
- Secret handling, credential rotation, and external provider tokens
- Billing, pricing, and customer-facing communication paths
```
