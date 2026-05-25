#!/usr/bin/env bash
# harnessable codex/install.sh
# Installs the harnessable AGENTS.md and skill into a target project.
#
# Usage: bash codex/install.sh /path/to/your-project

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: bash codex/install.sh /path/to/your-project"
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory does not exist: $TARGET"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Installing harnessable Codex adapter into: $TARGET"

# AGENTS.md
if [[ -f "$TARGET/AGENTS.md" ]]; then
  echo "  AGENTS.md already exists — skipping (merge manually if needed)"
else
  cp "$REPO_ROOT/AGENTS.md" "$TARGET/AGENTS.md"
  echo "  Created AGENTS.md"
fi

# Harnessable skill
SKILL_DIR="$TARGET/.agents/skills/harnessable"
mkdir -p "$SKILL_DIR"
cp "$REPO_ROOT/.agents/skills/harnessable/SKILL.md" "$SKILL_DIR/SKILL.md"
echo "  Created .agents/skills/harnessable/SKILL.md"

# HARNESSABLE_VERSION
HARNESSABLE_VERSION_SRC="$REPO_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION"
if [[ -f "$HARNESSABLE_VERSION_SRC" ]]; then
  cp "$HARNESSABLE_VERSION_SRC" "$SKILL_DIR/HARNESSABLE_VERSION"
  VERSION=$(cat "$HARNESSABLE_VERSION_SRC")
  echo "  Pinned version: $VERSION"
fi

echo ""
echo "Done. Next steps:"
echo "  1. Review $TARGET/AGENTS.md and add project-specific Blocked rules"
echo "  2. Create $TARGET/docs/knowledge-graph.yaml extending the framework graph"
echo "     See framework/vendor/harnessable/references/knowledge-graph.md"
echo "  3. Run: codex \"Use the harnessable skill. Act as Architect.\""
