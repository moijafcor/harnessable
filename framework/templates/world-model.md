# WORLD_MODEL.md

```text
Operational knowledge base for this project.
Encodes what the world looks like from here —
vendor capabilities, infrastructure topology,
failure patterns, known edge cases.
```

> **SECURITY NOTICE**
>
> This file contains infrastructure topology and operational data
> specific to your project.
>
> If your repository is **PUBLIC**:
>
> - Add `WORLD_MODEL.md` to `.gitignore`
> - Never commit real IPs, node names, service names, or client topology
> - Keep this file in a **private** repo alongside your codebase
>
> Real infrastructure data in a public repo is a security incident.

---

## Infrastructure Topology

```text
REPLACE: declare your nodes, roles, and connections.
Keep real IPs and hostnames in a private repository.

nodes:
  your-primary-node:
    role:    REPLACE (e.g. primary application host)
    vendor:  REPLACE (e.g. your hosting provider)
    ip:      REPLACE — private repo only, never public
    os:      REPLACE

  your-database-node:
    role:    REPLACE
    vendor:  REPLACE
    ip:      REPLACE — private repo only, never public
    os:      REPLACE

network:
  vpn:     REPLACE (e.g. Tinc, Tailscale, WireGuard)
  colo:    REPLACE (e.g. your-colo.example.com)
```

---

## Vendor Capabilities

```text
REPLACE: declare what each vendor can do that
agents should know about — especially non-obvious
recovery tools and access methods.

your-vendor:
  console:    REPLACE (URL to vendor management console)
  rescue:     REPLACE (how to access rescue/KVM mode)
  support:    REPLACE (support URL or contact)
  note: >
    REPLACE: any non-obvious vendor behaviour
    that agents need to know before acting.
    e.g. "hot-swap leaves boot stack broken"
```

---

## Failure Patterns

```text
Structured knowledge extracted from resolved incidents.
Add entries after every incident that reveals a new pattern.

### Pattern: {short descriptive name}

  Vendor:      {vendor name or 'any'}
  Layer:       {Hardware | Boot | OS | Network |
                Service | Application | Auth}
  Symptoms:    {observable signals at agent layer}
  Cause:       {what actually caused it}
  Diagnosis:   {how to confirm the cause}
  Tool:        {what accessed the correct layer}
  Procedure:
    1. {step}
    2. {step}
  Prevention:  {optional}
  Discovered:  {YYYY-MM-DD}
  Incident:    {docs/incidents/filename.md}
  Verified:    {YYYY-MM-DD}
```

---

## Service Dependencies

```text
REPLACE: declare what depends on what.
The blast radius map — what breaks when X goes down.
Use generic service names, not client-specific names.

your-app → your-database
your-app → your-cache
your-console → your-api (internal)
```

---

## Known Edge Cases

```text
REPLACE: things that behave unexpectedly and why.
Non-obvious operational facts agents need before acting.

Example (generic):
- fail2ban bans source IP after MaxAuthTries exhaustion.
  GSSAPI burns 2 slots per attempt.
  Unban: fail2ban-client set sshd unbanip {ip}

- Vendor hot-swap may leave boot stack broken.
  Requires console/KVM access to diagnose.
  See Failure Patterns for vendor-specific procedure.
```

---

## Incident Index

```text
One line per resolved incident.
Full records in docs/incidents/
Format: YYYY-MM-DD | node | pattern | file
```
