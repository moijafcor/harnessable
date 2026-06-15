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
#   <target>/world_models/*_world_model.md
#   <target>/docs/incidents/.gitkeep
#   <target>/docs/mandates/per/.gitkeep
#   <target>/docs/harness/templates/per.md
#   <target>/docs/dreams/.gitkeep
#   <target>/docs/evolutions/.gitkeep
#   <target>/docs/harness/templates/er.md
#   <target>/packages/README.md
#   <target>/packages/{name}/PACKAGE.md
#   <target>/docs/harness/templates/package.md
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

AGENTS_SRC="$REPO_ROOT/framework/templates/agents-md.md"
WORLD_MODEL_SRC="$REPO_ROOT/framework/templates/world-model.md"
WORLD_MODELS_SRC="$REPO_ROOT/framework/templates/world_models"
PER_SRC="$REPO_ROOT/framework/templates/per.md"
ER_SRC="$REPO_ROOT/framework/templates/er.md"
PACKAGE_TEMPLATE_SRC="$REPO_ROOT/framework/templates/package.md"
PACKAGES_SRC="$REPO_ROOT/framework/packages"
MODELS_SRC="$REPO_ROOT/framework/templates/models.yaml"
SKILL_SRC="$REPO_ROOT/.agents/skills/harnessable/SKILL.md"
VERSION_SRC="$REPO_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION"

ACTION_ITEMS=()
SYNCED_COUNT=0
OK_COUNT=0
MERGE_COUNT=0
PKG_SYNCED=0
PKG_OK=0
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
  if [[ ! -f "$AGENTS_SRC" || ! -f "$WORLD_MODEL_SRC" || ! -d "$WORLD_MODELS_SRC" || ! -f "$PER_SRC" || ! -f "$ER_SRC" || ! -f "$PACKAGE_TEMPLATE_SRC" || ! -d "$PACKAGES_SRC" || ! -f "$MODELS_SRC" || ! -f "$SKILL_SRC" ]]; then
    echo "ERR  Source does not look like a Harnessable checkout:"
    [[ -f "$AGENTS_SRC" ]] || echo "     Missing: $AGENTS_SRC"
    [[ -f "$WORLD_MODEL_SRC" ]] || echo "     Missing: $WORLD_MODEL_SRC"
    [[ -d "$WORLD_MODELS_SRC" ]] || echo "     Missing: $WORLD_MODELS_SRC"
    [[ -f "$PER_SRC" ]] || echo "     Missing: $PER_SRC"
    [[ -f "$ER_SRC" ]] || echo "     Missing: $ER_SRC"
    [[ -f "$PACKAGE_TEMPLATE_SRC" ]] || echo "     Missing: $PACKAGE_TEMPLATE_SRC"
    [[ -d "$PACKAGES_SRC" ]] || echo "     Missing: $PACKAGES_SRC"
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
  local world_models_dir="$TARGET/world_models"
  local incidents_dir="$TARGET/docs/incidents"
  local template fname

  if [[ ! -d "$incidents_dir" ]]; then
    mkdir -p "$incidents_dir"
    touch "$incidents_dir/.gitkeep"
    echo "  CREATED docs/incidents/"
  fi

  if [[ ! -d "$world_models_dir" ]]; then
    mkdir -p "$world_models_dir"
    echo "  CREATED world_models/"
  fi

  for template in "$WORLD_MODELS_SRC"/*_world_model.md; do
    [[ -f "$template" ]] || continue
    fname="$(basename "$template")"
    if [[ ! -f "$world_models_dir/$fname" ]]; then
      cp "$template" "$world_models_dir/$fname"
      echo "  CREATED world_models/$fname"
    fi
  done

  touch "$world_models_dir/.gitkeep"

  if [[ -f "$world_model" ]]; then
    echo "  OK      WORLD_MODEL.md"
  else
    cp "$WORLD_MODEL_SRC" "$world_model"
    echo "  SYNCED  WORLD_MODEL.md  (NEW)"
    echo "          Thin discovery index for project-owned world_models/ files."
  fi

  echo "          SECURITY: add world_models/ to .gitignore before adding real"
  echo "          infrastructure data to any public repository."
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

install_per_support() {
  local per_dir="$TARGET/docs/mandates/per"
  local per_template="$TARGET/docs/harness/templates/per.md"

  if [[ ! -d "$per_dir" ]]; then
    mkdir -p "$per_dir"
    touch "$per_dir/.gitkeep"
    echo "  CREATED docs/mandates/per/"
  elif [[ ! -f "$per_dir/.gitkeep" ]]; then
    touch "$per_dir/.gitkeep"
    echo "  CREATED docs/mandates/per/.gitkeep"
  fi

  copy_if_changed "$PER_SRC" "$per_template" "docs/harness/templates/per.md"
}

install_dream_support() {
  local dreams_dir="$TARGET/docs/dreams"

  if [[ ! -d "$dreams_dir" ]]; then
    mkdir -p "$dreams_dir"
    touch "$dreams_dir/.gitkeep"
    echo "  CREATED docs/dreams/"
  elif [[ ! -f "$dreams_dir/.gitkeep" ]]; then
    touch "$dreams_dir/.gitkeep"
    echo "  CREATED docs/dreams/.gitkeep"
  fi
}

install_evolution_support() {
  local evolutions_dir="$TARGET/docs/evolutions"
  local er_template="$TARGET/docs/harness/templates/er.md"

  if [[ ! -d "$evolutions_dir" ]]; then
    mkdir -p "$evolutions_dir"
    touch "$evolutions_dir/.gitkeep"
    echo "  CREATED docs/evolutions/"
  elif [[ ! -f "$evolutions_dir/.gitkeep" ]]; then
    touch "$evolutions_dir/.gitkeep"
    echo "  CREATED docs/evolutions/.gitkeep"
  fi

  copy_if_changed "$ER_SRC" "$er_template" "docs/harness/templates/er.md"
}

bootstrap_packages() {
  local pkg_dir="$TARGET/packages"
  local readme="$pkg_dir/README.md"

  if [[ -d "$pkg_dir" ]]; then
    return 0
  fi

  mkdir -p "$pkg_dir"

  cat > "$readme" << 'EOF'
# packages/

Third-party package adapters for this project.

Each subdirectory is a governance bridge between
a third-party package and harnessable conventions.
The package lives where installed. The adapter lives here.

## Discovery

  ls packages/*/PACKAGE.md       # installed adapters
  ls packages/*/skills/*.md      # available commands

## Installing a package adapter

Run codex/install.sh --update after adding the adapter
to the harnessable framework source, or manually copy
from framework/packages/{name}/.

See framework/packages/README.md for the convention.
EOF

  echo "  CREATED packages/"
}

sync_package_file() {
  local src="$1" dst="$2" label="$3"
  copy_if_changed "$src" "$dst" "$label"
  case "$LAST_STATUS" in
    synced) PKG_SYNCED=$((PKG_SYNCED + 1)) ;;
    ok)     PKG_OK=$((PKG_OK + 1)) ;;
  esac
}

sync_packages() {
  local src_dir="$PACKAGES_SRC"
  local dst_dir="$TARGET/packages"
  local found=0
  local pkg_dir

  [[ -d "$src_dir" ]] || return 0

  for pkg_dir in "$src_dir"/*/; do
    [[ -d "$pkg_dir" ]] || continue
    [[ -f "$pkg_dir/PACKAGE.md" ]] || continue
    found=$((found + 1))
  done

  [[ "$found" -gt 0 ]] || return 0

  echo "-- Packages --------------------------------------------------------------"
  ensure_dir "$dst_dir"

  for pkg_dir in "$src_dir"/*/; do
    [[ -d "$pkg_dir" ]] || continue
    [[ -f "$pkg_dir/PACKAGE.md" ]] || continue

    local pkg_name dst_pkg f name
    pkg_name="$(basename "$pkg_dir")"
    dst_pkg="$dst_dir/$pkg_name"
    ensure_dir "$dst_pkg"

    sync_package_file \
      "$pkg_dir/PACKAGE.md" \
      "$dst_pkg/PACKAGE.md" \
      "packages/$pkg_name/PACKAGE.md"

    if [[ -f "$pkg_dir/README.md" ]]; then
      sync_package_file \
        "$pkg_dir/README.md" \
        "$dst_pkg/README.md" \
        "packages/$pkg_name/README.md"
    fi

    if [[ -d "$pkg_dir/skills" ]]; then
      ensure_dir "$dst_pkg/skills"
      for f in "$pkg_dir/skills/"*.md; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        sync_package_file \
          "$f" \
          "$dst_pkg/skills/$name" \
          "packages/$pkg_name/skills/$name"
      done
    fi

    if [[ -d "$pkg_dir/adapter" ]]; then
      ensure_dir "$dst_pkg/adapter"
      for f in "$pkg_dir/adapter/"*; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        sync_package_file \
          "$f" \
          "$dst_pkg/adapter/$name" \
          "packages/$pkg_name/adapter/$name"
      done
    fi
  done

  echo ""
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

  bootstrap_packages

  install_models_manifest
  count_status

  install_per_support
  count_status

  install_dream_support

  install_evolution_support
  count_status

  copy_if_changed "$PACKAGE_TEMPLATE_SRC" "$TARGET/docs/harness/templates/package.md" "docs/harness/templates/package.md"
  count_status

  sync_packages

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
  if [[ $((PKG_SYNCED + PKG_OK)) -gt 0 ]]; then
    printf "  %-12s %d synced / %d current\n" \
      "Packages:" "$PKG_SYNCED" "$PKG_OK"
  fi
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
