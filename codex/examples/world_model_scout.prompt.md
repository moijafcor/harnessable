# World Model Scout prompt — harnessable

Use the harnessable skill. Act as World Model Scout.

Target deployment: [path or empty for current working directory]

Populate `world_models/` from project recon. Never overwrite existing files,
never read secrets, and never commit. Operator review is required.

Recon:
- Scan `AGENTS.md`
- Scan service topology from docker-compose, `.env.example`, framework config,
  dependency manifests, and Dockerfile
- Scan infrastructure hints from Ansible inventory, hosts files, and nginx
  config
- Scan mandate corpus for `Knowledge Extracted`, `HARNESS_IMPROVEMENT`, SIR/EIR
  patterns, and `docs/incidents/`
- Scan git history for incident, hotfix, rollback, or SRE signals
- Detect staging indicators

Classify every finding:
- `FOUND` — confirmed from files
- `INFERRED` — guessed from context; prefix generated content with
  `# INFERRED:`
- `UNKNOWN` — leave as `REPLACE`

Create only missing world model files. Use templates from
`docs/harness/templates/world_models/` when available. Do not read bare .env
files.
Do not fill IPs or credentials.

Output a World Model Scout recon summary with files created, files skipped,
FOUND/INFERRED/UNKNOWN findings, recommended manual additions, and the security
reminder that the repo must be private before committing infrastructure
topology.
