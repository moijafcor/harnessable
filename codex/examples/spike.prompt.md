# Spike prompt - harnessable

Use the harnessable skill. Act as Spike.

Work: [DESCRIBE THE MICRO-FIX, EXPLORATION, OR PROTOTYPE HERE]

Spike is for lightweight work inside a declared scope and time box. Do not use
it for production incidents, planned significant changes, or anything that
requires bypassing the AGENTS.md Safety Floor.

Before the first code change, arm the spike gate:

```bash
mkdir -p .harnessable
date -u +"%Y-%m-%dT%H:%M:%SZ" > .harnessable/spike_gate
echo "Spike gate armed. Code edits blocked until spike/ branch exists."
```

Create or check out a descriptive branch:

```bash
git checkout -b spike/{short-description}
```

Declare:

- Time box, default 2 hours
- Scope boundary in one sentence
- What is explicitly out of scope

During the spike, record any unexpected finding as `DISCOVERY: {class} -
{one-line description}` in commit messages or the PR description.

Exit by shipping through a PR, abandoning with a one-sentence note, or
escalating to the full pipeline when scope or risk exceeds the Spike boundary.
Never merge directly to main.
