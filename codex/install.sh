#!/usr/bin/env bash
# harnessable - codex/install.sh
#
# Installs or syncs the Harnessable Codex adapter into a target project.
# Idempotent.
#
# Usage:
#   bash codex/install.sh /path/to/your-project           # fresh install
#   bash codex/install.sh --update /path/to/your-project  # sync update
#   bash codex/install.sh --update                        # sync current dir
#   bash codex/install.sh --help
#
# What this installs:
#   <target>/AGENTS.md
#   <target>/WORLD_MODEL.md
#   <target>/docs/incidents/.gitkeep
#   <target>/docs/harness/models.yaml
#   <target>/.agents/skills/harnessable/SKILL.md
#   <target>/.agents/skills/harnessable/HARNESSABLE_VERSION
#
# Output prefixes:
#   SYNCED  file installed or updated from framework
#   CREATED project-owned directory created
#   OK      file already current, no change
#   MERGE   customised file skipped; MANUAL_MERGE_REQUIRED
#   ERR     fatal; install halted

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MODE="fresh"
TARGET=""

AGENTS_SRC="$REPO_ROOT/AGENTS.md"
WORLD_MODEL_SRC="$REPO_ROOT/framework/templates/world-model.md"
MODELS_SRC="$REPO_ROOT/framework/templates/models.yaml"
SKILL_SRC="$REPO_ROOT/.agents/skills/harnessable/SKILL.md"
VERSION_SRC="$REPO_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION"

ACTION_ITEMS=()
SYNCED_COUNT=0
OK_COUNT=0
MERGE_COUNT=0
LAST_STATUS=""

ensure_dir() {
  mkdir -p "$1"
}

parse_args() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage:"
    echo "  bash codex/install.sh /path/to/project           # fresh install"
    echo "  bash codex/install.sh --update /path/to/project  # sync update"
    echo "  bash codex/install.sh --update                   # sync current directory"
    exit 0
  fi

  if [[ "${1:-}" == "--update" ]]; then
    MODE="update"
    TARGET="${2:-$(pwd)}"
  elif [[ -n "${1:-}" ]]; then
    MODE="fresh"
    TARGET="$1"
  else
    echo "Usage: bash codex/install.sh /path/to/project"
    echo "       bash codex/install.sh --update [/path/to/project]"
    exit 1
  fi

  TARGET="$(realpath "$TARGET")"
}

check_source() {
  if [[ ! -f "$AGENTS_SRC" || ! -f "$WORLD_MODEL_SRC" || ! -f "$MODELS_SRC" || ! -f "$SKILL_SRC" ]]; then
    echo "ERR  Source does not look like a Harnessable checkout:"
    [[ -f "$AGENTS_SRC" ]] || echo "     Missing: $AGENTS_SRC"
    [[ -f "$WORLD_MODEL_SRC" ]] || echo "     Missing: $WORLD_MODEL_SRC"
    [[ -f "$MODELS_SRC" ]] || echo "     Missing: $MODELS_SRC"
    [[ -f "$SKILL_SRC" ]] || echo "     Missing: $SKILL_SRC"
    exit 3
  fi
}

check_target() {
  if [[ ! -d "$TARGET" ]]; then
    echo "ERR  Target directory does not exist: $TARGET"
    exit 1
  fi

  if ! git -C "$TARGET" rev-parse --git-dir &>/dev/null 2>&1; then
    echo "ERR  Target is not a git repository: $TARGET"
    exit 2
  fi

  if [[ "$MODE" == "update" ]]; then
    local STATUS
    STATUS="$(git -C "$TARGET" status --porcelain 2>/dev/null)"
    if [[ -n "$STATUS" ]]; then
      echo "ERR  Target has uncommitted changes - commit or stash before updating:"
      echo "$STATUS" | head -10
      exit 2
    fi
  fi
}

count_status() {
  case "$LAST_STATUS" in
    synced) SYNCED_COUNT=$((SYNCED_COUNT + 1)) ;;
    ok)     OK_COUNT=$((OK_COUNT + 1)) ;;
    merge)  MERGE_COUNT=$((MERGE_COUNT + 1)) ;;
  esac
}

copy_if_changed() {
  local src="$1" dst="$2" label="$3"
  ensure_dir "$(dirname "$dst")"

  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    echo "  SYNCED  $label  (NEW)"
    LAST_STATUS="synced"
    return 0
  fi

  if diff -q "$src" "$dst" &>/dev/null; then
    echo "  OK      $label"
    LAST_STATUS="ok"
    return 0
  fi

  cp "$src" "$dst"
  echo "  SYNCED  $label"
  LAST_STATUS="synced"
}

write_version_file() {
  local dst="$1" label="$2" tmp_version
  ensure_dir "$(dirname "$dst")"
  tmp_version="$(mktemp /tmp/harnessable_codex_version.XXXXXX)"
  printf '%s\n' "$FRAMEWORK_VERSION" > "$tmp_version"
  copy_if_changed "$tmp_version" "$dst" "$label"
  rm -f "$tmp_version"
}

install_agents_file() {
  local dst="$TARGET/AGENTS.md"

  if [[ ! -f "$dst" ]]; then
    cp "$AGENTS_SRC" "$dst"
    echo "  SYNCED  AGENTS.md  (NEW)"
    LAST_STATUS="synced"
    return 0
  fi

  if diff -q "$AGENTS_SRC" "$dst" &>/dev/null; then
    echo "  OK      AGENTS.md"
    LAST_STATUS="ok"
    return 0
  fi

  echo "  MERGE   AGENTS.md  <- MANUAL_MERGE_REQUIRED"
  ACTION_ITEMS+=("Merge Harnessable AGENTS.md requirements from $AGENTS_SRC into $dst")
  LAST_STATUS="merge"
}

install_world_model() {
  local world_model="$TARGET/WORLD_MODEL.md"
  local incidents_dir="$TARGET/docs/incidents"

  if [[ ! -d "$incidents_dir" ]]; then
    mkdir -p "$incidents_dir"
    touch "$incidents_dir/.gitkeep"
    echo "  CREATED docs/incidents/"
  fi

  if [[ -f "$world_model" ]]; then
    echo "  OK      WORLD_MODEL.md"
    return 0
  fi

  cp "$WORLD_MODEL_SRC" "$world_model"
  echo "  SYNCED  WORLD_MODEL.md  (NEW)"
  echo "          Fill this project-owned file with topology, vendor capabilities,"
  echo "          failure patterns, and known operational edge cases."
}

install_models_manifest() {
  local dst="$TARGET/docs/harness/models.yaml"
  ensure_dir "$(dirname "$dst")"

  if [[ ! -f "$dst" ]]; then
    cp "$MODELS_SRC" "$dst"
    echo "  SYNCED  docs/harness/models.yaml  (NEW)"
    LAST_STATUS="synced"
    return 0
  fi

  if diff -q "$MODELS_SRC" "$dst" &>/dev/null; then
    echo "  OK      docs/harness/models.yaml"
    LAST_STATUS="ok"
    return 0
  fi

  echo "  MERGE   docs/harness/models.yaml  <- MANUAL_MERGE_REQUIRED"
  ACTION_ITEMS+=("Merge Harnessable model manifest requirements from $MODELS_SRC into $dst without losing project model choices")
  LAST_STATUS="merge"
}

main() {
  parse_args "$@"
  check_source
  check_target

  FRAMEWORK_VERSION="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null \
    || cat "$VERSION_SRC" 2>/dev/null \
    || echo unknown)"

  echo ""
  echo "harnessable Codex adapter $FRAMEWORK_VERSION  [mode: $MODE]"
  echo "  Source:  $REPO_ROOT"
  echo "  Target:  $TARGET"
  echo ""

  echo "-- Codex adapter ---------------------------------------------------------"

  install_agents_file
  count_status

  install_world_model

  install_models_manifest
  count_status

  SKILL_DIR="$TARGET/.agents/skills/harnessable"
  copy_if_changed "$SKILL_SRC" "$SKILL_DIR/SKILL.md" ".agents/skills/harnessable/SKILL.md"
  count_status

  if [[ -n "$FRAMEWORK_VERSION" && "$FRAMEWORK_VERSION" != "unknown" ]]; then
    write_version_file "$SKILL_DIR/HARNESSABLE_VERSION" ".agents/skills/harnessable/HARNESSABLE_VERSION"
    count_status
  else
    echo "  MERGE   .agents/skills/harnessable/HARNESSABLE_VERSION  <- MANUAL_ACTION_REQUIRED"
    ACTION_ITEMS+=("Create .agents/skills/harnessable/HARNESSABLE_VERSION after choosing a release pin")
    LAST_STATUS="merge"
    count_status
  fi

  echo ""

  echo "-- Knowledge graph ------------------------------------------------------"

  KG_TARGET="$TARGET/docs/knowledge-graph.yaml"
  if [[ -f "$KG_TARGET" ]]; then
    echo "  OK      docs/knowledge-graph.yaml"
  else
    echo "  MERGE   docs/knowledge-graph.yaml  <- MANUAL_ACTION_REQUIRED"
    ACTION_ITEMS+=("Bootstrap docs/knowledge-graph.yaml from framework/templates/knowledge-graph.yaml before the first mandate")
  fi

  echo ""
  echo "========================================================================="
  echo "  Summary"
  echo "========================================================================="
  echo ""
  printf "  %-12s %d synced / %d current / %d manual merge\n" \
    "Adapter:" "$SYNCED_COUNT" "$OK_COUNT" "$MERGE_COUNT"
  echo ""

  if [[ ${#ACTION_ITEMS[@]} -gt 0 ]]; then
    echo "  Action required:"
    echo ""
    for item in "${ACTION_ITEMS[@]}"; do
      echo "  ACTION: $item"
    done
    echo ""
  fi

  echo "  Next steps:"
  echo ""
  echo "  1. Review changes:"
  echo "       git -C $TARGET status"
  echo ""
  echo "  2. Start a role session with one of the templates in codex/:"
  echo "       codex \"\$(cat $REPO_ROOT/codex/architect.prompt.md)\""
  echo ""
  echo "  3. To install the full Harnessable enforcement layer instead, run:"
  echo "       bash $REPO_ROOT/install.sh $TARGET"
  echo ""
}

main "$@"
