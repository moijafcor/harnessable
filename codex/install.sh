#!/usr/bin/env bash
# harnessable — codex/install.sh
#
# Installs the harnessable Codex adapter into a target project.
# Copies AGENTS.md and the harnessable skill. Does not touch
# framework/ — vendor that separately if you need the full
# enforcement layer.
#
# Usage:
#   bash codex/install.sh /path/to/your-project
#
# What this installs:
#   <target>/AGENTS.md                                — repo-level instructions
#   <target>/.agents/skills/harnessable/SKILL.md     — harnessable skill
#   <target>/.agents/skills/harnessable/HARNESSABLE_VERSION — pinned version

set -euo pipefail

# ── Arguments ─────────────────────────────────────────────────────────────────

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: bash codex/install.sh /path/to/your-project"
  echo ""
  echo "  Installs AGENTS.md and .agents/skills/harnessable/SKILL.md"
  echo "  into the target project."
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory does not exist: $TARGET"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo "Installing harnessable Codex adapter"
echo "  Source:  $REPO_ROOT"
echo "  Target:  $TARGET"
echo ""

# ── AGENTS.md ─────────────────────────────────────────────────────────────────

AGENTS_TARGET="$TARGET/AGENTS.md"

if [[ -f "$AGENTS_TARGET" ]]; then
  echo "  ⚠  AGENTS.md already exists at $AGENTS_TARGET"
  echo "     Harnessable's AGENTS.md will not overwrite it."
  echo "     Merge the following into your existing file manually:"
  echo ""
  echo "     ────────────────────────────────────────"
  cat "$REPO_ROOT/AGENTS.md"
  echo "     ────────────────────────────────────────"
  echo ""
  AGENTS_STATUS="skipped (merge manually)"
else
  cp "$REPO_ROOT/AGENTS.md" "$AGENTS_TARGET"
  AGENTS_STATUS="created"
fi

echo "  AGENTS.md — $AGENTS_STATUS"

# ── Harnessable skill ──────────────────────────────────────────────────────────

SKILL_DIR="$TARGET/.agents/skills/harnessable"
mkdir -p "$SKILL_DIR"

cp "$REPO_ROOT/.agents/skills/harnessable/SKILL.md" "$SKILL_DIR/SKILL.md"
echo "  .agents/skills/harnessable/SKILL.md — created"

# ── Version pin ───────────────────────────────────────────────────────────────

VERSION_SRC="$REPO_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION"

if [[ -f "$VERSION_SRC" ]]; then
  cp "$VERSION_SRC" "$SKILL_DIR/HARNESSABLE_VERSION"
  VERSION=$(cat "$VERSION_SRC")
  echo "  .agents/skills/harnessable/HARNESSABLE_VERSION — pinned at $VERSION"
else
  # Fall back to current git SHA if HARNESSABLE_VERSION not present
  if git -C "$REPO_ROOT" rev-parse HEAD &>/dev/null 2>&1; then
    SHA=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
    echo "$SHA" > "$SKILL_DIR/HARNESSABLE_VERSION"
    echo "  .agents/skills/harnessable/HARNESSABLE_VERSION — pinned at $SHA (git SHA)"
  else
    echo "  .agents/skills/harnessable/HARNESSABLE_VERSION — skipped (no version source found)"
  fi
fi

# ── Knowledge graph reminder ───────────────────────────────────────────────────

KG_TARGET="$TARGET/docs/knowledge-graph.yaml"

if [[ ! -f "$KG_TARGET" ]]; then
  echo ""
  echo "  ℹ  No project knowledge graph found at docs/knowledge-graph.yaml"
  echo "     Create one to ground domain concepts before running mandates."
  echo "     See framework/vendor/harnessable/references/knowledge-graph.md"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "Done. Next steps:"
echo ""
echo "  1. If AGENTS.md was skipped above, merge harnessable's blocks"
echo "     into your existing file (## Knowledge Graph, ## Blocked,"
echo "     ## Completion Gate)."
echo ""
echo "  2. Create a project knowledge graph:"
echo "     docs/knowledge-graph.yaml"
echo "     extends: .agents/skills/harnessable/../../../framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"
echo ""
echo "  3. Start a mandate:"
echo "     codex \"Use the harnessable skill. Act as Architect.\""
echo "     (See codex/examples/ for full role prompt templates)"
echo ""
echo "  4. To install the full enforcement layer (hooks, guards, templates):"
echo "     cp -r framework/ path/to/your-project/docs/harness/"
echo ""
