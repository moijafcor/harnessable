#!/usr/bin/env bash
# harnessable - codex/install.sh
#
# Installs the Harnessable Codex adapter into a target project. Idempotent.
#
# Usage:
#   bash codex/install.sh /path/to/your-project
#
# What this installs:
#   <target>/AGENTS.md
#   <target>/.agents/skills/harnessable/SKILL.md
#   <target>/.agents/skills/harnessable/HARNESSABLE_VERSION
#
# Output prefixes:
#   NEW    file created for the first time
#   OK     file already current, no change
#   UPD    file updated
#   SKIP   customised file left untouched
#   WARN   something needs attention but install continues
#   ACTION operator follow-up required
#   ERR    fatal; install halted

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: bash codex/install.sh /path/to/your-project"
  echo ""
  echo "  Installs AGENTS.md and .agents/skills/harnessable/SKILL.md"
  echo "  into the target project."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

AGENTS_SRC="$REPO_ROOT/AGENTS.md"
SKILL_SRC="$REPO_ROOT/.agents/skills/harnessable/SKILL.md"
VERSION_SRC="$REPO_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION"

if [[ ! -d "$TARGET" ]]; then
  echo "ERR  Target directory does not exist: $TARGET"
  exit 1
fi

if ! git -C "$TARGET" rev-parse --git-dir &>/dev/null 2>&1; then
  echo "ERR  Target is not a git repository: $TARGET"
  exit 2
fi

if [[ ! -f "$AGENTS_SRC" || ! -f "$SKILL_SRC" ]]; then
  echo "ERR  Source does not look like a Harnessable checkout:"
  [[ -f "$AGENTS_SRC" ]] || echo "     Missing: $AGENTS_SRC"
  [[ -f "$SKILL_SRC" ]] || echo "     Missing: $SKILL_SRC"
  exit 3
fi

FRAMEWORK_VERSION="$(cat "$VERSION_SRC" 2>/dev/null || git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"

echo ""
echo "Installing harnessable Codex adapter $FRAMEWORK_VERSION"
echo "  Source:  $REPO_ROOT"
echo "  Target:  $TARGET"
echo ""

ACTION_ITEMS=()
NEW_COUNT=0
OK_COUNT=0
UPD_COUNT=0
SKIP_COUNT=0
WARN_COUNT=0
LAST_STATUS=""

ensure_dir() {
  mkdir -p "$1"
}

count_status() {
  case "$LAST_STATUS" in
    new)  NEW_COUNT=$((NEW_COUNT + 1)) ;;
    ok)   OK_COUNT=$((OK_COUNT + 1)) ;;
    upd)  UPD_COUNT=$((UPD_COUNT + 1)) ;;
    skip) SKIP_COUNT=$((SKIP_COUNT + 1)) ;;
    warn) WARN_COUNT=$((WARN_COUNT + 1)) ;;
  esac
}

copy_if_changed() {
  local src="$1" dst="$2" label="$3"
  ensure_dir "$(dirname "$dst")"

  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "  NEW  $label"
    LAST_STATUS="new"
    return 0
  fi

  if diff -q "$src" "$dst" &>/dev/null; then
    echo "  OK   $label"
    LAST_STATUS="ok"
    return 0
  fi

  cp "$src" "$dst"
  echo "  UPD  $label"
  LAST_STATUS="upd"
}

install_agents_file() {
  local dst="$TARGET/AGENTS.md"

  if [[ ! -f "$dst" ]]; then
    cp "$AGENTS_SRC" "$dst"
    echo "  NEW  AGENTS.md"
    LAST_STATUS="new"
    return 0
  fi

  if diff -q "$AGENTS_SRC" "$dst" &>/dev/null; then
    echo "  OK   AGENTS.md"
    LAST_STATUS="ok"
    return 0
  fi

  echo "  SKIP AGENTS.md (customised, not overwritten)"
  ACTION_ITEMS+=("Merge Harnessable AGENTS.md requirements from $AGENTS_SRC into $dst")
  LAST_STATUS="skip"
}

echo "-- Codex adapter ---------------------------------------------------------"

install_agents_file
count_status

SKILL_DIR="$TARGET/.agents/skills/harnessable"
copy_if_changed "$SKILL_SRC" "$SKILL_DIR/SKILL.md" ".agents/skills/harnessable/SKILL.md"
count_status

if [[ -f "$VERSION_SRC" ]]; then
  copy_if_changed "$VERSION_SRC" "$SKILL_DIR/HARNESSABLE_VERSION" ".agents/skills/harnessable/HARNESSABLE_VERSION"
  count_status
elif git -C "$REPO_ROOT" rev-parse HEAD &>/dev/null 2>&1; then
  ensure_dir "$SKILL_DIR"
  TMP_VERSION="$(mktemp /tmp/harnessable_codex_version.XXXXXX)"
  trap 'rm -f "$TMP_VERSION"' EXIT
  git -C "$REPO_ROOT" rev-parse --short HEAD > "$TMP_VERSION"
  copy_if_changed "$TMP_VERSION" "$SKILL_DIR/HARNESSABLE_VERSION" ".agents/skills/harnessable/HARNESSABLE_VERSION"
  count_status
  rm -f "$TMP_VERSION"
  trap - EXIT
else
  echo "  WARN .agents/skills/harnessable/HARNESSABLE_VERSION (no version source found)"
  ACTION_ITEMS+=("Create .agents/skills/harnessable/HARNESSABLE_VERSION after choosing a release pin")
  LAST_STATUS="warn"
  count_status
fi

echo ""
echo "-- Knowledge graph ------------------------------------------------------"

KG_TARGET="$TARGET/docs/knowledge-graph.yaml"
if [[ -f "$KG_TARGET" ]]; then
  echo "  OK   docs/knowledge-graph.yaml"
else
  echo "  WARN docs/knowledge-graph.yaml missing"
  ACTION_ITEMS+=("Bootstrap docs/knowledge-graph.yaml from framework/templates/knowledge-graph.yaml before the first mandate")
  LAST_STATUS="warn"
  count_status
fi

echo ""
echo "========================================================================="
echo "  Summary"
echo "========================================================================="
echo ""
printf "  %-12s %d new / %d updated / %d current / %d skipped / %d warnings\n" \
  "Adapter:" "$NEW_COUNT" "$UPD_COUNT" "$OK_COUNT" "$SKIP_COUNT" "$WARN_COUNT"
echo ""

if [[ ${#ACTION_ITEMS[@]} -gt 0 ]]; then
  echo "  ACTION items requiring operator follow-up:"
  echo ""
  for item in "${ACTION_ITEMS[@]}"; do
    echo "  ACTION  $item"
  done
  echo ""
fi

echo "  Next steps:"
echo ""
echo "  1. Review changes:"
echo "       git -C $TARGET status"
echo ""
echo "  2. Start a role session with one of the templates in codex/examples/:"
echo "       codex \"\$(cat $REPO_ROOT/codex/examples/architect.prompt.md)\""
echo ""
echo "  3. To install the full Harnessable enforcement layer instead, run:"
echo "       bash $REPO_ROOT/install.sh $TARGET"
echo ""
