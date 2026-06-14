# framework/packages/

Seed adapters for third-party packages.
Synced by install.sh sync_packages() to packages/
in each deployment target.

## What lives here

Each subdirectory is a harnessable package adapter.
It is NOT the package itself — it is the governance
bridge between the package and harnessable.

The package lives where installed:
  ~/.claude/skills/{name}/
  node_modules/{name}/
  pip package, etc.

The adapter lives here:
  framework/packages/{name}/

## Convention

A valid harnessable package adapter must have:

  {name}/
    PACKAGE.md            manifest (required)
    skills/               /command wrappers (optional)
      {name}.md
      {name}_{verb}.md
    adapter/              governance extensions (optional)
      {role}_ext.md       role extension
      rubric.md           Rubric additions
      {domain}_world_model.md  world model template

## Discovery

The Engineer discovers packages during roster scan:

  ls packages/*/PACKAGE.md
  ls packages/*/skills/*.md
  ls packages/*/adapter/*_ext.md

## Adding a new package adapter

1. Create framework/packages/{name}/
2. Copy framework/templates/package.md →
   framework/packages/{name}/PACKAGE.md
3. Fill all REPLACE markers
4. Add skills/ and adapter/ as needed
5. Run install.sh --update on target projects

## Current adapters

  hallmark/       design execution, slop gates,
                  DNA extraction (PLANNED)
