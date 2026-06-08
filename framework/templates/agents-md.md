# AGENTS.md

## Harnessable {Project Name}Protocol

# REPLACE: Write 2-3 sentences describing what this project is and
# what harnessable governs here. Example:
# "This is the api.your-project backend. Work here governs the MCP
# tool surface, Google Ads integration, multi-tenant data layer,
# and autonomy policy enforcement. Changes to MCP tools or the
# tenant isolation boundary require Security role sign-off."

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

# REPLACE: Fill tracker details for this project.
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

# REPLACE: List project-specific domain terms that must be grounded
# in the knowledge graph before the agent acts. Examples:
# Resolve {ProjectName} domain terms — {term1}, {term2}, {term3} —
# against the project graph before acting.
# File ONTOLOGY_GAP for any concept encountered that is not declared.

## Risk Profile

risk_level: # REPLACE: low | medium | high | critical

safety_constraints:

# REPLACE: List project-specific safety constraints. Be explicit.
# Examples:
# - Do not touch live systems without an SRE mandate or explicit
#   human approval in the current session.
# - Prefer read-only reconnaissance until the DIP authorises a change.
# - Never expose secret values. Credential checks must be verify-only:
#   existence, permissions, checksums, or line counts only.
# - Database mutations require explicit mandate scope and
#   rollback/restore evidence.
# - External documentation and provider facts must be verified live
#   before they appear in a DIP or runbook.

## Ask First

# REPLACE: List surfaces where the agent must stop and ask before
# acting. These feed spike.md's high-risk surface enforcement.
# Examples:
# - Production deployments of any kind
# - Database schema changes or migrations
# - External service configuration (OAuth, webhooks, DNS)
# - Billing, subscription, or pricing changes
# - Changes to authentication or authorisation logic

## Locale and Voice

locale:   # REPLACE: en-CA | en-US | en-GB | es | pt-BR | fr-CA
voice:    # REPLACE: technical | engineering | operations | product
audience: # REPLACE: who reads the output of work on this project

# REPLACE: Add any audience-specific communication guidance.
# Example: "Use exact dates, hostnames, paths, and command evidence
# when reporting operational work. Keep summaries clear enough for
# non-implementing stakeholders."

## Blocked

The bouncer hook enforces this list where supported.

# REPLACE: Add project-specific blocked operations. Be specific.
# Include the reason where it is not obvious.
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

# REPLACE: Commands that must pass before reporting work complete.
# Be specific — generic placeholders here undermine the gate.
# Examples:
#
# Python projects:
#   python3 -m pytest -x -q --tb=short
#   python3 -m py_compile {hook files}
#
# Node/TypeScript projects:
#   npx tsc --noEmit
#   npx eslint src/
#   npx jest --passWithNoTests
#
# Laravel/PHP:
#   php artisan test --stop-on-failure
#   php artisan route:list --no-ansi > /dev/null
#
# Always include:
  git diff --check

For mandate-specific work, also run the verification commands
stated in the DIP. If a check requires network, credentials, live
hosts, or other approval, record it as not run with the reason and
the exact approval needed.

## MCP Servers

# REPLACE: Declare MCP servers available to agent sessions,
# or explicitly state none.
#
# Example:
# MoijafcorGithubProjects MCP:
#   url:     mcp.moisesjafet.com/sse
#   purpose: GitHub Projects board management
#   tools:   list_project_items, create_project_item,
#            update_project_item_field, link_issue_to_project
#   scope:   mandate tracking
#
# If none: "No project-specific MCP servers are declared."

## Infrastructure

# Declares the canonical tooling for provisioning and managing
# infrastructure in this project. All agents must plan and verify
# infrastructure changes through this tooling — not directly on hosts.
# Direct mutations outside the canonical tool are undocumented drift.

# REPLACE: Choose your provisioning tool and fill in the paths.
# Common values for provisioning_tool:
#   Ansible | Terraform | Pulumi | CDK | Helm | Chef | Puppet | manual
# Use manual only when no IaC tooling exists — and explain why.

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

## Communication Channels

# The Narrator produces content for these destinations.
# REPLACE: Declare channels specific to this project.
# Each channel should note its format, audience, and approval path.
#
# Example:
# docs_site:    docs.{project}.io  (MDX, feature guides)
# api_docs:     docs.{project}.io/api  (OpenAPI changelog style)
# landing_page: www.{project}.io  (React panels — hero, features, cta)
# blog:         www.{project}.io/blog  (MDX, launch register)
# email:        (HTML — tenant blast | prospect outreach | partner)
# executive:    concise impact summaries for stakeholders
#
# All email, social, press, customer, partner, or provider
# communications must remain drafts until explicitly approved.

## High Risk Surfaces

# REPLACE: List project surfaces where mistakes have large blast radius.
# Examples:
# - Authentication or authorisation changes
# - Production deployment workflows
# - Database migration and tenant-isolation boundaries
# - Secret handling, credential rotation, and external provider tokens
# - Billing, pricing, and customer-facing communication paths
