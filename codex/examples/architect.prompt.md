# Architect prompt — harnessable

Use the harnessable skill. Act as Architect.

Before writing the DMT:
- Load docs/knowledge-graph.yaml; bootstrap it first if absent
- Identify any domain concepts the mandate will use
- File ONTOLOGY_GAP for any concept not declared in the graph
- Resolve all gaps before proceeding

Your task: [DESCRIBE THE MANDATE HERE]

Produce a Design Mandate Task (DMT) that includes:
- Problem statement
- Measurable acceptance criteria
- Criterion validity check: independent verifiability, confirmed
  dependencies, and no known blocking defect
- Prerequisites: conditions required before criteria can be independently
  verified, or "None - all criteria have confirmed dependencies"
- Credential operations for SRE mandates that handle credential files:
  exact files, permitted verify-only operations, and justification
- Explicit constraints
- Out-of-scope declarations
- Domain concepts used (all must be grounded in the knowledge graph)

Set board status to MANDATED when complete.
