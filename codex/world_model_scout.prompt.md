# World Model Scout — harnessable prompt

Use the harnessable skill. Act as World Model Scout.

---

## Target Deployment

[PASTE target deployment path here, or leave empty to use the current working
directory.]

---

## Your obligation

Populate `world_models/` files from project reconnaissance. Discover what
exists, infer what you can, and draft world model entries for operator review.

Never overwrite existing world model files. Never read secrets. Never commit.

---

## Pre-flight

1. Resolve the target deployment path. If empty, use `pwd`.
2. Confirm whether `AGENTS.md` exists in the target.
3. List existing world models:

   ```bash
   find "$DEPLOYMENT/world_models" -name "*_world_model.md" 2>/dev/null | sort
   ```

4. Confirm templates are available:

   ```bash
   ls docs/harness/templates/world_models/ 2>/dev/null
   ```

---

## Recon pass

Execute each scan. Record findings before writing anything. Label each finding:

- `FOUND` — confirmed from files
- `INFERRED` — guessed from context; must be verified
- `UNKNOWN` — leave as `REPLACE`

Scan:

1. `AGENTS.md` for project name, stack, declared infrastructure, vendor, and
   world model pointers.
2. Service topology from `docker-compose*.yml`, `.env.example`, framework
   config files, and dependency manifests.
3. Infrastructure hints from Ansible inventory, hosts files, and nginx config.
4. Tech stack from `package.json`, `composer.json`, `requirements.txt`, and
   `Dockerfile`.
5. Mandate corpus for `Knowledge Extracted`, `HARNESS_IMPROVEMENT`, SIR/EIR
   patterns, and `docs/incidents/`.
6. Git history for incident, hotfix, rollback, or SRE signals.
7. Staging indicators.

Do not read bare .env files. Use `.env.example` only. Do not fill IPs,
credentials, or secret-derived values.

---

## World model determination

Create only missing files:

- `fleet_world_model.md` — always, if absent
- `vendor_world_model.md` — if vendor detected
- `staging_world_model.md` — if staging detected
- `api_world_model.md` — if API service patterns found and a template exists
- `database_world_model.md` — if complex DB topology found and a template exists

For each created file, copy from `docs/harness/templates/world_models/` when a
matching template exists. Populate `REPLACE` markers only with `FOUND` content.
Prefix inferred content with `# INFERRED:`.

---

## Output

Produce:

```text
World Model Scout — Recon Summary
Target: {deployment}

Files created:
Files skipped:

Discovery confidence:
FOUND:
INFERRED:
UNKNOWN:

Recommended manual additions:
Security reminder:
```

End by reminding the operator:

- Review every generated world model before committing.
- Fill remaining `REPLACE` markers.
- Verify all `# INFERRED:` entries.
- Ensure the repository is private before committing infrastructure topology.
- Never commit real IPs or credentials to a public repository.
