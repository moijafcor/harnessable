# AGENTS.md

## Harnessable protocol

This repository uses Harnessable: operational governance for autonomous
agents. Full documentation: framework/vendor/harnessable/references/

Before non-trivial work:

1. Identify active role: Orchestrator, Architect, Engineer, Coder, SRE, QA,
   Security, Reviewer, Inspector, Analyst, Narrator, or Emergency Responder.
2. Do not combine Coder and QA, or SRE and QA, in the same pass.
   Security must not be the Coder, SRE, or QA for the same mandate.
3. For implementation work, require a Design Implementation Plan before
   editing code or touching live systems.
4. Record deviations, blockers, and verification evidence.
5. Do not claim completion without running the stated checks.

## Knowledge graph

Framework graph: framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml
Project graph:   docs/knowledge-graph.yaml (if present)

Load both at session start. Resolve all domain terms against the
project graph before acting. File ONTOLOGY_GAP for any concept
encountered that is not declared in the graph.

## Blocked actions

- Do not force-push
- Do not delete branches
- Do not run destructive database commands (DROP, TRUNCATE,
  WHERE-less DELETE)
- Do not read or expose secrets unless explicitly required
- Do not send external communications

## Communication Channels

# Declare communication destinations the Narrator may produce for.
# Remove this section if no Narrator communication channels are configured.
#
# docs_site:    {URL}  ({format: MDX | Markdown | HTML})
# api_docs:     {URL}  ({format: OpenAPI changelog | Markdown})
# landing_page: {URL}  ({sections: hero | features | pricing | cta})
# blog:         {URL}  ({format: MDX | long-form Markdown})
# email:        ({audiences: tenant | prospect | partner})
# social:       ({platforms: LinkedIn | X | newsletter})
# press:        ({format: press release})
# partner:      ({format: talking points | sales enablement})
# executive:    ({format: impact summary})

## Completion gate

Before final response, report:

- Files changed
- Commands run
- Verification result
- Open risks
- Next recommended role
