# WORLD_MODEL.md

```text
Discovery index for this project's world models.

World models live in world_models/
Each file models one domain precisely.
Agents: scan the directory, read what's relevant.
Do not read everything — read what the mandate needs.
```

> **SECURITY NOTICE**
>
> `world_models/` contains operational infrastructure knowledge.
>
> If this repository is **PUBLIC**:
>
> - Add `world_models/` to `.gitignore`
> - Real IPs, node names, service names, and dependency
>   graphs must never appear in a public repository.

---

## Discovery

Find all world models for this project:

```bash
find world_models/ -name "*_world_model.md" | sort
```

Read the index entry of each. Follow pointers to
relevant domain models. Read deeply only what the
mandate requires.

## World models in this project

```text
REPLACE: list your domain world models
→ world_models/fleet_world_model.md
→ world_models/vendor_world_model.md
→ world_models/staging_world_model.md
```

## Cross-repo world models

```text
REPLACE: pointers to world models in other
private fleet repositories
→ ../your-sre-repo/world_models/infra_world_model.md
→ ../your-api-repo/world_models/api_world_model.md
```

## Incident records

`docs/incidents/` — full incident records, one file per resolved incident
