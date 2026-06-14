#!/usr/bin/env bash
# harnessable — install.sh
#
# Installs or syncs harnessable into a target project. Idempotent.
#
# Usage:
#   bash install.sh /path/to/project           # fresh install
#   bash install.sh --update /path/to/project  # full sync update
#   bash install.sh --update                   # sync in current directory
#   bash install.sh --help
#
# Output prefixes:
#   SYNCED  — file installed or updated from framework
#   OK      — file already current, no change
#   MERGE   — customised file skipped; MANUAL_MERGE_REQUIRED
#   PATCHED — config file updated
#   ERR     — fatal; halted

set -euo pipefail

FRAMEWORK_ROOT="$(dirname "$(realpath "$0")")"
MODE="fresh"
TARGET=""
FRAMEWORK_VERSION=""
GITHUB_BOARD=""
GITHUB_BOARD_OWNER=""
GITHUB_BOARD_OWNER_TYPE=""
GITHUB_BOARD_PASSED=false

# Counters
T2_SYNCED=0; T2_OK=0
AG_SYNCED=0; AG_OK=0; AG_MERGE=0
HK_SYNCED=0; HK_OK=0
TL_SYNCED=0; TL_OK=0
TM_SYNCED=0; TM_OK=0
MM_SYNCED=0; MM_OK=0; MM_MERGE=0
SK_SYNCED=0; SK_OK=0; SK_MERGE=0
PKG_SYNCED=0; PKG_OK=0
REPLACE_COUNT=0
REPLACE_FILES=()
MERGE_FILES=()
ACTION_ITEMS=()

CFG_SETTINGS="—"; CFG_GITIGNORE="—"; CFG_CONFIG="—"
AUDIT_RESULT="—"

# Tracker (populated by detect_tracker)
TRACKER_TOOL=""
TRACKER_URL=""
TRACKER_INTEGRATION=""

# ── Helpers ───────────────────────────────────────────────────────────────────

ensure_dir() { mkdir -p "$1"; }

py_validate() {
  local file="$1" label="$2"
  if ! python3 -m py_compile "$file" 2>/dev/null; then
    echo "  ERR  $label — Python syntax error; halting"
    exit 1
  fi
}

# ── parse_args ────────────────────────────────────────────────────────────────

parse_args() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage:"
    echo "  bash install.sh /path/to/project           # fresh install"
    echo "  bash install.sh --update /path/to/project  # full sync update"
    echo "  bash install.sh --update                   # sync in current directory"
    echo "  bash install.sh --github-board=new /path/to/project"
    echo "  bash install.sh --github-board=N [--owner=user-or-org] /path/to/project"
    echo "  bash install.sh --github-board=https://github.com/orgs/ORG/projects/N[/views/VIEW] /path/to/project"
    echo "  bash install.sh --github-board=https://github.com/users/USER/projects/N /path/to/project"
    exit 0
  fi

  local POSITIONAL=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      --update)
        MODE="update"
        ;;
      --github-board=*)
        GITHUB_BOARD="${arg#--github-board=}"
        GITHUB_BOARD_PASSED=true
        ;;
      --owner=*)
        GITHUB_BOARD_OWNER="${arg#--owner=}"
        ;;
      --*)
        echo "ERR  Unknown option: $arg"
        exit 1
        ;;
      *)
        POSITIONAL+=("$arg")
        ;;
    esac
  done

  if [[ "$MODE" == "update" ]]; then
    TARGET="${POSITIONAL[0]:-$(pwd)}"
  elif [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    MODE="fresh"
    TARGET="${POSITIONAL[0]}"
  else
    echo "Usage: bash install.sh /path/to/project"
    echo "       bash install.sh --update [/path/to/project]"
    echo "       bash install.sh --github-board=new /path/to/project"
    exit 1
  fi

  TARGET="$(realpath "$TARGET")"
}

# ── check_framework ───────────────────────────────────────────────────────────

check_framework() {
  local KG_SRC="$FRAMEWORK_ROOT/framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"
  if [[ ! -f "$KG_SRC" ]]; then
    echo "ERR  FRAMEWORK_ROOT does not look like harnessable:"
    echo "     Missing: $KG_SRC"
    exit 1
  fi

  python3 - "$KG_SRC" <<'PYEOF'
import yaml, sys
try:
    yaml.safe_load(open(sys.argv[1]))
except Exception as e:
    print(f'ERR  KNOWLEDGE_GRAPH.yaml is not valid YAML: {e}', file=sys.stderr)
    sys.exit(1)
PYEOF

  FRAMEWORK_VERSION="$(git -C "$FRAMEWORK_ROOT" rev-parse --short HEAD 2>/dev/null \
    || cat "$FRAMEWORK_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION")"
}

# ── check_target ──────────────────────────────────────────────────────────────

check_target() {
  if [[ ! -d "$TARGET" ]]; then
    echo "ERR  Target directory does not exist: $TARGET"
    exit 2
  fi

  if ! git -C "$TARGET" rev-parse --git-dir &>/dev/null; then
    echo "ERR  Target is not a git repository: $TARGET"
    exit 2
  fi

  if [[ "$MODE" == "update" ]]; then
    local STATUS
    STATUS="$(git -C "$TARGET" status --porcelain 2>/dev/null)"
    if [[ -n "$STATUS" ]]; then
      echo "ERR  Target has uncommitted changes — commit or stash before updating:"
      echo "$STATUS" | head -10
      exit 2
    fi
  fi
}

# ── sync_tier2 ────────────────────────────────────────────────────────────────

sync_tier2() {
  echo "── Tier 2 (vendor) ──────────────────────────────────────────────────────"

  local SRC_VENDOR="$FRAMEWORK_ROOT/framework/vendor/harnessable"
  local DST_VENDOR="$TARGET/docs/harness/vendor/harnessable"
  ensure_dir "$DST_VENDOR"

  local REF_CHANGES REF_COUNT
  REF_CHANGES="$(rsync -a --delete --itemize-changes "$SRC_VENDOR/references/" \
    "$DST_VENDOR/references/" 2>/dev/null | grep -cE '^[>*<c]' || true)"
  REF_COUNT="$(find "$DST_VENDOR/references" -type f 2>/dev/null | wc -l | tr -d '[:space:]')"
  if [[ "$REF_CHANGES" -gt 0 ]]; then
    echo "  SYNCED  docs/harness/vendor/harnessable/references/ ($REF_COUNT files)"
    T2_SYNCED=$((T2_SYNCED + 1))
  else
    echo "  OK      docs/harness/vendor/harnessable/references/ ($REF_COUNT files)"
    T2_OK=$((T2_OK + 1))
  fi

  _sync_vendor_file "$SRC_VENDOR/KNOWLEDGE_GRAPH.yaml" \
    "$DST_VENDOR/KNOWLEDGE_GRAPH.yaml" \
    "docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"

  _sync_version_file "$DST_VENDOR/HARNESSABLE_VERSION" \
    "docs/harness/vendor/harnessable/HARNESSABLE_VERSION → $FRAMEWORK_VERSION"

  echo ""
}

_sync_vendor_file() {
  local SRC="$1" DST="$2" LABEL="$3"
  ensure_dir "$(dirname "$DST")"
  if [[ ! -f "$DST" ]] || ! diff -q "$SRC" "$DST" &>/dev/null; then
    cp "$SRC" "$DST"
    echo "  SYNCED  $LABEL"
    T2_SYNCED=$((T2_SYNCED + 1))
  else
    echo "  OK      $LABEL"
    T2_OK=$((T2_OK + 1))
  fi
}

_sync_version_file() {
  local DST="$1" LABEL="$2" TMP_VERSION
  ensure_dir "$(dirname "$DST")"
  TMP_VERSION="$(mktemp /tmp/harnessable_version.XXXXXX)"
  printf '%s\n' "$FRAMEWORK_VERSION" > "$TMP_VERSION"

  if [[ ! -f "$DST" ]] || ! diff -q "$TMP_VERSION" "$DST" &>/dev/null; then
    cp "$TMP_VERSION" "$DST"
    echo "  SYNCED  $LABEL"
    T2_SYNCED=$((T2_SYNCED + 1))
  else
    echo "  OK      $LABEL"
    T2_OK=$((T2_OK + 1))
  fi

  rm -f "$TMP_VERSION"
}

# ── sync_hooks ────────────────────────────────────────────────────────────────
# Hooks are framework-owned; replace every file unconditionally.

sync_hooks() {
  echo "── Hooks ────────────────────────────────────────────────────────────────"

  local SRC_DIR="$FRAMEWORK_ROOT/framework/hooks"
  local DST_DIR="$TARGET/docs/harness/hooks"
  ensure_dir "$DST_DIR"

  _sync_hook_file "$SRC_DIR/run.py" "$DST_DIR/run.py" \
    "docs/harness/hooks/run.py"
  _sync_hook_file "$SRC_DIR/claude_code_settings_template.json" \
    "$DST_DIR/claude_code_settings_template.json" \
    "docs/harness/hooks/claude_code_settings_template.json"

  local subdir f name
  for subdir in pre_tool_use post_tool_use stop pre_compact; do
    [[ -d "$SRC_DIR/$subdir" ]] || continue
    ensure_dir "$DST_DIR/$subdir"
    for f in "$SRC_DIR/$subdir/"*.py; do
      [[ -f "$f" ]] || continue
      name="$(basename "$f")"
      _sync_hook_file "$f" "$DST_DIR/$subdir/$name" \
        "docs/harness/hooks/$subdir/$name"
    done
  done

  echo ""
}

_sync_hook_file() {
  local SRC="$1" DST="$2" LABEL="$3"
  ensure_dir "$(dirname "$DST")"

  if [[ ! -f "$DST" ]]; then
    cp "$SRC" "$DST"
    [[ "$SRC" == *.py ]] && py_validate "$DST" "$LABEL"
    echo "  SYNCED  $LABEL  (NEW)"
    HK_SYNCED=$((HK_SYNCED + 1))
    return
  fi

  if diff -q "$SRC" "$DST" &>/dev/null; then
    echo "  OK      $LABEL"
    HK_OK=$((HK_OK + 1))
    return
  fi

  cp "$SRC" "$DST"
  [[ "$SRC" == *.py ]] && py_validate "$DST" "$LABEL"
  echo "  SYNCED  $LABEL"
  HK_SYNCED=$((HK_SYNCED + 1))
}

# ── sync_agents ───────────────────────────────────────────────────────────────
# Diff-detect customisation: additive framework updates apply automatically;
# removals from the framework baseline require a manual merge.

sync_agents() {
  echo "── Agents ───────────────────────────────────────────────────────────────"

  local SRC_DIR="$FRAMEWORK_ROOT/framework/agents"
  local DST_DIR="$TARGET/docs/harness/agents"
  ensure_dir "$DST_DIR"

  local f name dst label REMOVED ADDED
  for f in "$SRC_DIR/"*.md; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    dst="$DST_DIR/$name"
    label="docs/harness/agents/$name"

    if [[ ! -f "$dst" ]]; then
      cp "$f" "$dst"
      echo "  SYNCED  $label  (NEW)"
      AG_SYNCED=$((AG_SYNCED + 1))
      continue
    fi

    if diff -q "$f" "$dst" &>/dev/null; then
      echo "  OK      $label"
      AG_OK=$((AG_OK + 1))
      continue
    fi

    # Lines in project not in framework = potential project customisations
    REMOVED="$(diff "$dst" "$f" | grep -c "^<" || true)"
    if [[ "$REMOVED" -eq 0 ]]; then
      ADDED="$(diff "$dst" "$f" | grep -c "^>" || true)"
      cp "$f" "$dst"
      echo "  SYNCED  $label  (+$ADDED lines)"
      AG_SYNCED=$((AG_SYNCED + 1))
    else
      echo "  MERGE   $label  ← MANUAL_MERGE_REQUIRED ($REMOVED lines removed)"
      AG_MERGE=$((AG_MERGE + 1))
      MERGE_FILES+=("$label")
    fi
  done

  echo ""
}

# ── sync_tools ────────────────────────────────────────────────────────────────
# Tools are framework-owned; replace unconditionally.

sync_tools() {
  echo "── Tools ────────────────────────────────────────────────────────────────"

  local SRC_DIR="$FRAMEWORK_ROOT/framework/tools"
  local DST_DIR="$TARGET/docs/harness/tools"
  ensure_dir "$DST_DIR"

  local f name dst label existed
  for f in "$SRC_DIR/"*.py "$SRC_DIR/"*.sh; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    dst="$DST_DIR/$name"
    label="docs/harness/tools/$name"
    existed=false
    [[ -f "$dst" ]] && existed=true

    if ! $existed || ! diff -q "$f" "$dst" &>/dev/null; then
      cp "$f" "$dst"
      if $existed; then
        echo "  SYNCED  $label"
      else
        echo "  SYNCED  $label  (NEW)"
      fi
      TL_SYNCED=$((TL_SYNCED + 1))
    else
      echo "  OK      $label"
      TL_OK=$((TL_OK + 1))
    fi
  done

  echo ""
}

# ── sync_templates ────────────────────────────────────────────────────────────
# Diff-detect: additive framework updates apply; project customisations
# (lines removed from framework) require a manual merge.

sync_templates() {
  echo "── Templates ────────────────────────────────────────────────────────────"

  local SRC_DIR="$FRAMEWORK_ROOT/framework/templates"
  local DST_DIR="$TARGET/docs/harness/templates"
  ensure_dir "$DST_DIR"

  local f name dst label REMOVED ADDED
  for f in "$SRC_DIR/"*.md "$SRC_DIR/"*.yaml; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"

    # agents-md.md is install.sh internal tooling (greenfield AGENTS.md
    # bootstrap only). models.yaml is installed as docs/harness/models.yaml,
    # not under templates. Exclude both from template deployment.
    [[ "$name" == "agents-md.md" || "$name" == "models.yaml" ]] && continue

    dst="$DST_DIR/$name"
    label="docs/harness/templates/$name"

    if [[ ! -f "$dst" ]]; then
      cp "$f" "$dst"
      echo "  SYNCED  $label  (NEW)"
      TM_SYNCED=$((TM_SYNCED + 1))
      continue
    fi

    if diff -q "$f" "$dst" &>/dev/null; then
      echo "  OK      $label"
      TM_OK=$((TM_OK + 1))
      continue
    fi

    REMOVED="$(diff "$dst" "$f" | grep -c "^<" || true)"
    if [[ "$REMOVED" -eq 0 ]]; then
      ADDED="$(diff "$dst" "$f" | grep -c "^>" || true)"
      cp "$f" "$dst"
      echo "  SYNCED  $label  (+$ADDED lines)"
      TM_SYNCED=$((TM_SYNCED + 1))
    else
      echo "  MERGE   $label  ← MANUAL_MERGE_REQUIRED ($REMOVED lines removed)"
      MERGE_FILES+=("$label")
    fi
  done

  echo ""
}

# ── sync_models_manifest ──────────────────────────────────────────────────────
# Project-owned model choices. Install when absent; never overwrite customised
# manifests because projects may intentionally pin different providers/models.

sync_models_manifest() {
  echo "── Models manifest ──────────────────────────────────────────────────────"

  local SRC="$FRAMEWORK_ROOT/framework/templates/models.yaml"
  local DST="$TARGET/docs/harness/models.yaml"
  local LABEL="docs/harness/models.yaml"

  ensure_dir "$(dirname "$DST")"

  if [[ ! -f "$SRC" ]]; then
    echo "  MERGE   $LABEL  ← MANUAL_ACTION_REQUIRED (source missing)"
    MM_MERGE=$((MM_MERGE + 1))
    ACTION_ITEMS+=("Create docs/harness/models.yaml — source template missing at $SRC")
    echo ""
    return
  fi

  if [[ ! -f "$DST" ]]; then
    cp "$SRC" "$DST"
    echo "  SYNCED  $LABEL  (NEW)"
    MM_SYNCED=$((MM_SYNCED + 1))
    echo ""
    return
  fi

  if diff -q "$SRC" "$DST" &>/dev/null; then
    echo "  OK      $LABEL"
    MM_OK=$((MM_OK + 1))
    echo ""
    return
  fi

  echo "  MERGE   $LABEL  ← MANUAL_MERGE_REQUIRED"
  MM_MERGE=$((MM_MERGE + 1))
  MERGE_FILES+=("$LABEL")
  ACTION_ITEMS+=("Review framework/templates/models.yaml and merge any required role entries into $DST without losing project model choices")
  echo ""
}

# ── cleanup_vendor_templates ──────────────────────────────────────────────────
# Removes docs/harness/vendor/harnessable/templates/ if it exists.
# This directory was incorrectly created by a prior sync_tier2() bug.
# Idempotent — silent if already absent.
cleanup_vendor_templates() {
  local STALE_DIR="$TARGET/docs/harness/vendor/harnessable/templates"
  if [[ -d "$STALE_DIR" ]]; then
    rm -rf "$STALE_DIR"
    echo "  CLEANED docs/harness/vendor/harnessable/templates/ (stale)"
  fi

  local STALE_AGENTS="$TARGET/docs/harness/templates/agents-md.md"
  if [[ -f "$STALE_AGENTS" ]]; then
    rm -f "$STALE_AGENTS"
    echo "  CLEANED docs/harness/templates/agents-md.md (install.sh internal)"
  fi
}

# ── bootstrap_agents_md ───────────────────────────────────────────────────────
# Greenfield only. Creates AGENTS.md from template if absent.
# Never overwrites an existing AGENTS.md under any circumstance.
bootstrap_agents_md() {
  local AGENTS_MD="$TARGET/AGENTS.md"
  local TEMPLATE="$FRAMEWORK_ROOT/framework/templates/agents-md.md"

  [[ -f "$AGENTS_MD" ]] && return 0

  if [[ ! -f "$TEMPLATE" ]]; then
    echo "  WARN  AGENTS.md absent but template not found:"
    echo "        $TEMPLATE"
    echo "        Create AGENTS.md manually before running agents."
    ACTION_ITEMS+=("Create AGENTS.md — template not found at $TEMPLATE")
    return 1
  fi

  cp "$TEMPLATE" "$AGENTS_MD"

  echo ""
  echo "  ┌─────────────────────────────────────────────────────┐"
  echo "  │  GREENFIELD INSTALL — AGENTS.md created             │"
  echo "  │                                                     │"
  echo "  │  Fill every # REPLACE marker before running        │"
  echo "  │  agent sessions. Critical sections:                │"
  echo "  │                                                     │"
  echo "  │  ## Project Identity  — domain and timezone        │"
  echo "  │  ## Project Tracker   — enables skill auto-fill    │"
  echo "  │  ## Blocked           — safety floor commands      │"
  echo "  │  ## Completion Gate   — gated verification         │"
  echo "  │                                                     │"
  echo "  │  Then re-run: bash install.sh --update .           │"
  echo "  │  to auto-fill skills from ## Project Tracker.      │"
  echo "  └─────────────────────────────────────────────────────┘"
  echo ""

  ACTION_ITEMS+=("Fill AGENTS.md REPLACE markers then re-run install.sh --update")
}

# ── bootstrap_world_models ────────────────────────────────────────────────────
# Greenfield only. Creates world_models/ directory with seed templates.
# Creates docs/incidents/ directory.
# Never overwrites existing files.
bootstrap_world_models() {
  local WM_DIR="$TARGET/world_models"
  local INCIDENTS_DIR="$TARGET/docs/incidents"
  local TEMPLATES="$FRAMEWORK_ROOT/framework/templates/world_models"
  local INDEX_TEMPLATE="$FRAMEWORK_ROOT/framework/templates/world-model.md"
  local INDEX="$TARGET/WORLD_MODEL.md"

  # Create docs/incidents/ — project-owned, never harness
  if [[ ! -d "$INCIDENTS_DIR" ]]; then
    mkdir -p "$INCIDENTS_DIR"
    touch "$INCIDENTS_DIR/.gitkeep"
    echo "  CREATED docs/incidents/"
  fi

  # Create world_models/ directory
  if [[ ! -d "$WM_DIR" ]]; then
    mkdir -p "$WM_DIR"

    # Seed domain templates if available
    if [[ -d "$TEMPLATES" ]]; then
      for template in "$TEMPLATES"/*_world_model.md; do
        local fname
        fname=$(basename "$template")
        if [[ ! -f "$WM_DIR/$fname" ]]; then
          cp "$template" "$WM_DIR/$fname"
          echo "  CREATED world_models/$fname"
        fi
      done
    fi

    touch "$WM_DIR/.gitkeep"
    echo "  CREATED world_models/"
  fi

  # Create WORLD_MODEL.md thin index
  if [[ ! -f "$INDEX" ]]; then
    if [[ -f "$INDEX_TEMPLATE" ]]; then
      cp "$INDEX_TEMPLATE" "$INDEX"
      echo "  CREATED WORLD_MODEL.md (discovery index)"
    fi
  fi

  echo ""
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║  SECURITY: world_models/ created                 ║"
  echo "  ║                                                  ║"
  echo "  ║  This directory will contain infrastructure      ║"
  echo "  ║  topology and operational data.                  ║"
  echo "  ║                                                  ║"
  echo "  ║  If this repository is PUBLIC:                   ║"
  echo "  ║    Add world_models/ to .gitignore NOW           ║"
  echo "  ║    before adding any real data.                  ║"
  echo "  ║                                                  ║"
  echo "  ║  Real IPs and infrastructure topology in a       ║"
  echo "  ║  public repo are a security incident.            ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo ""
}

# ── bootstrap_packages ────────────────────────────────────────────────────────
# Greenfield only. Creates packages/ directory with README.
bootstrap_packages() {
  local PKG_DIR="$TARGET/packages"
  local README="$PKG_DIR/README.md"

  if [[ -d "$PKG_DIR" ]]; then
    return 0
  fi

  mkdir -p "$PKG_DIR"

  cat > "$README" << 'EOF'
# packages/

Third-party package adapters for this project.

Each subdirectory is a governance bridge between
a third-party package and harnessable conventions.
The package lives where installed. The adapter lives here.

## Discovery

  ls packages/*/PACKAGE.md       # installed adapters
  ls packages/*/skills/*.md      # available commands

## Installing a package adapter

Run install.sh --update after adding the adapter
to the harnessable framework source, or manually
copy from framework/packages/{name}/.

See framework/packages/README.md for the convention.
EOF

  echo "  CREATED packages/"
}

# ── bootstrap_per_directory ───────────────────────────────────────────────────
# Greenfield/update safe. Creates the project-owned PER filing directory.
bootstrap_per_directory() {
  local PER_DIR="$TARGET/docs/mandates/per"

  if [[ ! -d "$PER_DIR" ]]; then
    mkdir -p "$PER_DIR"
    touch "$PER_DIR/.gitkeep"
    echo "  CREATED docs/mandates/per/"
  elif [[ ! -f "$PER_DIR/.gitkeep" ]]; then
    touch "$PER_DIR/.gitkeep"
    echo "  CREATED docs/mandates/per/.gitkeep"
  fi
}

# ── bootstrap_dreams_directory ────────────────────────────────────────────────
# Greenfield/update safe. Creates the project-owned Dream Report directory.
bootstrap_dreams_directory() {
  local DREAMS_DIR="$TARGET/docs/dreams"

  if [[ ! -d "$DREAMS_DIR" ]]; then
    mkdir -p "$DREAMS_DIR"
    touch "$DREAMS_DIR/.gitkeep"
    echo "  CREATED docs/dreams/"
  elif [[ ! -f "$DREAMS_DIR/.gitkeep" ]]; then
    touch "$DREAMS_DIR/.gitkeep"
    echo "  CREATED docs/dreams/.gitkeep"
  fi
}

# ── bootstrap_evolutions_directory ────────────────────────────────────────────
# Greenfield/update safe. Creates the project-owned Evolution Report directory.
bootstrap_evolutions_directory() {
  local EVOLUTIONS_DIR="$TARGET/docs/evolutions"

  if [[ ! -d "$EVOLUTIONS_DIR" ]]; then
    mkdir -p "$EVOLUTIONS_DIR"
    touch "$EVOLUTIONS_DIR/.gitkeep"
    echo "  CREATED docs/evolutions/"
  elif [[ ! -f "$EVOLUTIONS_DIR/.gitkeep" ]]; then
    touch "$EVOLUTIONS_DIR/.gitkeep"
    echo "  CREATED docs/evolutions/.gitkeep"
  fi
}

# ── setup_github_board ────────────────────────────────────────────────────────
# Handles --github-board=<N|new|empty>.
# Writes result to AGENTS.md ## Project Tracker.

HARNESSABLE_STATUS_OPTIONS=(
  "BACKLOG" "MANDATED" "IN_RECON" "PLANNED" "IN_PROGRESS"
  "IN_REVIEW" "BLOCKED" "NEEDS_REVISION" "VERIFIED" "DONE"
)

check_gh_cli() {
  if ! command -v gh &>/dev/null; then
    echo ""
    echo "  ERR --github-board requires the GitHub CLI (gh)."
    echo "      Install: https://cli.github.com/"
    echo "      Then authenticate: gh auth login"
    exit 3
  fi

  if ! gh auth status &>/dev/null; then
    echo ""
    echo "  ERR gh CLI is installed but not authenticated."
    echo "      Run: gh auth login"
    exit 3
  fi

  if [[ -z "$GITHUB_BOARD_OWNER" ]]; then
    GITHUB_BOARD_OWNER="$(gh api user --jq .login 2>/dev/null)"
    if [[ -z "$GITHUB_BOARD_OWNER" ]]; then
      echo "  ERR Could not determine GitHub user. Pass --owner=<user>."
      exit 3
    fi
  fi

  echo "  INFO GitHub CLI authenticated as: $GITHUB_BOARD_OWNER"
}

setup_github_board() {
  [[ "$GITHUB_BOARD_PASSED" != true ]] && return 0

  echo "── GitHub Projects board ────────────────────────────────────────────────"

  _board_normalize_input
  check_gh_cli

  case "$GITHUB_BOARD" in
    "new")   _board_create ;;
    "")      _board_validate_from_agents ;;
    *)       _board_link "$GITHUB_BOARD" ;;
  esac

  echo ""
}

_board_normalize_input() {
  case "$GITHUB_BOARD" in
    ""|"new")
      return 0
      ;;
    http://github.com/*|https://github.com/*|github.com/*)
      local PARSED
      PARSED="$(python3 - "$GITHUB_BOARD" <<'PYEOF'
import re
import sys
from urllib.parse import urlparse

raw = sys.argv[1]
candidate = raw if re.match(r'https?://', raw) else f'https://{raw}'
parsed = urlparse(candidate)
path = parsed.path.rstrip('/')

m = re.fullmatch(r'/(orgs|users)/([^/]+)/projects/([0-9]+)(?:/views/[0-9]+)?', path)
if not m or parsed.netloc.lower() != 'github.com':
    sys.exit(1)

kind, owner, number = m.groups()
owner_type = 'org' if kind == 'orgs' else 'user'
print(f'{owner_type}\t{owner}\t{number}')
PYEOF
      )" || {
        echo "  ERR Malformed GitHub Projects URL: $GITHUB_BOARD"
        echo "      Expected: https://github.com/orgs/<org>/projects/<number>"
        echo "            or: https://github.com/users/<user>/projects/<number>"
        echo "      Optional suffix: /views/<view>"
        exit 3
      }

      local URL_OWNER
      IFS=$'\t' read -r GITHUB_BOARD_OWNER_TYPE URL_OWNER GITHUB_BOARD <<< "$PARSED"
      if [[ -z "$GITHUB_BOARD_OWNER" ]]; then
        GITHUB_BOARD_OWNER="$URL_OWNER"
      fi
      ;;
    *[!0-9]*)
      echo "  ERR Invalid --github-board value: $GITHUB_BOARD"
      echo "      Use new, an empty value, a project number, or a GitHub Projects URL."
      exit 3
      ;;
  esac
}

_board_owner_type_from_url() {
  python3 - "$1" <<'PYEOF'
import re
import sys
from urllib.parse import urlparse

url = sys.argv[1]
path = urlparse(url).path
m = re.search(r'/(orgs|users)/[^/]+/projects/[0-9]+', path)
if not m:
    sys.exit(0)
print('org' if m.group(1) == 'orgs' else 'user', end='')
PYEOF
}

_board_create() {
  local PROJECT_NAME
  PROJECT_NAME="$(basename "$TARGET") — harnessable"

  echo "  Creating GitHub Project: '$PROJECT_NAME'"
  echo "  Owner: $GITHUB_BOARD_OWNER"

  local CREATE_OUTPUT
  CREATE_OUTPUT="$(gh project create \
    --owner "$GITHUB_BOARD_OWNER" \
    --title "$PROJECT_NAME" \
    --format json 2>/dev/null)" || {
    echo "  ERR Failed to create project."
    echo "      Check that your token has 'project' scope:"
    echo "      gh auth refresh -s project"
    exit 3
  }

  local PROJECT_NUMBER PROJECT_URL
  PROJECT_NUMBER="$(echo "$CREATE_OUTPUT" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); \
    print(d.get('number',''))" 2>/dev/null)"
  PROJECT_URL="$(echo "$CREATE_OUTPUT" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); \
    print(d.get('url',''))" 2>/dev/null)"

  echo "  Created: project #$PROJECT_NUMBER"
  echo "  URL: $PROJECT_URL"

  if [[ -z "$GITHUB_BOARD_OWNER_TYPE" ]]; then
    GITHUB_BOARD_OWNER_TYPE="$(_board_owner_type_from_url "$PROJECT_URL")"
  fi

  _board_add_status_field "$PROJECT_NUMBER"
  _board_write_agents_md "$PROJECT_NUMBER" "$PROJECT_URL"
}

_board_link() {
  local BOARD_NUMBER="$1"
  echo "  Linking to GitHub Project #$BOARD_NUMBER"
  echo "  Owner: $GITHUB_BOARD_OWNER"

  local PROJECT_DATA GH_ERR
  GH_ERR="$(mktemp /tmp/harnessable_gh_project_view.XXXXXX)"
  PROJECT_DATA="$(gh project view "$BOARD_NUMBER" \
    --owner "$GITHUB_BOARD_OWNER" \
    --format json 2>"$GH_ERR")" || {
    echo "  ERR Project #$BOARD_NUMBER not found or not accessible."
    echo "      Verify owner with --owner=<org-or-user>"
    if [[ -s "$GH_ERR" ]]; then
      echo "      gh project view error:"
      sed 's/^/        /' "$GH_ERR"
    fi
    echo "      If this is a missing project scope error, run:"
    echo "      gh auth refresh -s project"
    rm -f "$GH_ERR"
    exit 3
  }
  rm -f "$GH_ERR"

  local PROJECT_URL PROJECT_TITLE
  PROJECT_URL="$(echo "$PROJECT_DATA" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); \
    print(d.get('url',''))" 2>/dev/null)"
  PROJECT_TITLE="$(echo "$PROJECT_DATA" | \
    python3 -c "import json,sys; d=json.load(sys.stdin); \
    print(d.get('title',''))" 2>/dev/null)"

  echo "  Found: '$PROJECT_TITLE'"
  echo "  URL: $PROJECT_URL"

  if [[ -z "$GITHUB_BOARD_OWNER_TYPE" ]]; then
    GITHUB_BOARD_OWNER_TYPE="$(_board_owner_type_from_url "$PROJECT_URL")"
  fi
  if [[ -z "$GITHUB_BOARD_OWNER_TYPE" ]]; then
    echo "  WARN Could not infer owner_type from project URL; AGENTS.md will omit owner_type."
  fi

  _board_check_status_field "$BOARD_NUMBER"
  _board_write_agents_md "$BOARD_NUMBER" "$PROJECT_URL"
}

_board_validate_from_agents() {
  local AGENTS_FILE="$TARGET/AGENTS.md"
  if [[ ! -f "$AGENTS_FILE" ]]; then
    echo "  ERR --github-board= (read from AGENTS.md) but AGENTS.md"
    echo "      does not exist. Run install first or pass a board number."
    exit 3
  fi

  local BOARD_NUMBER
  BOARD_NUMBER="$(python3 - "$AGENTS_FILE" <<'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'##\s+Project Tracker\s*\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
if not m: sys.exit(0)
pm = re.search(r'project[:\s]+(\d+)', m.group(1), re.I)
print(pm.group(1).strip() if pm else '', end='')
PYEOF
)"

  if [[ -z "$BOARD_NUMBER" ]]; then
    echo "  ERR No project number found in AGENTS.md ## Project Tracker."
    echo "      Add 'project: <N>' or pass --github-board=<N>."
    exit 3
  fi

  echo "  Read from AGENTS.md: project #$BOARD_NUMBER"
  _board_link "$BOARD_NUMBER"
}

_board_add_status_field() {
  local PROJECT_NUMBER="$1"
  _board_configure_status_field "$PROJECT_NUMBER"
}

_board_resolve_project_id() {
  local PROJECT_NUMBER="$1"

  local PROJECT_ID
  PROJECT_ID="$(gh api graphql \
    -f query="query { user(login: \"$GITHUB_BOARD_OWNER\") { \
      projectV2(number: $PROJECT_NUMBER) { id } } }" \
    --jq '.data.user.projectV2.id' 2>/dev/null)" || true

  if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID="$(gh api graphql \
      -f query="query { organization(login: \"$GITHUB_BOARD_OWNER\") { \
        projectV2(number: $PROJECT_NUMBER) { id } } }" \
      --jq '.data.organization.projectV2.id' 2>/dev/null)" || true
  fi

  printf '%s' "$PROJECT_ID"
}

_board_status_field_id() {
  local PROJECT_NUMBER="$1"
  gh project field-list "$PROJECT_NUMBER" \
    --owner "$GITHUB_BOARD_OWNER" \
    --format json 2>/dev/null | \
    python3 -c "
import json, sys
try:
  d = json.load(sys.stdin)
  for f in d.get('fields', []):
    if f.get('name') == 'Status':
      print(f.get('id', ''), end='')
      break
except Exception:
  pass
" 2>/dev/null || true
}

_board_create_status_field() {
  local PROJECT_ID="$1"
  gh api graphql \
    -f query="mutation {
      addProjectV2Field(input: {
        projectId: \"$PROJECT_ID\"
        dataType: SINGLE_SELECT
        name: \"Status\"
      }) { projectV2Field { ... on ProjectV2SingleSelectField { id } } }
    }" \
    --jq '.data.addProjectV2Field.projectV2Field.id' 2>/dev/null || true
}

_board_configure_status_field() {
  local PROJECT_NUMBER="$1"
  echo "  Configuring harnessable Status field..."

  local PROJECT_ID
  PROJECT_ID="$(_board_resolve_project_id "$PROJECT_NUMBER")"

  if [[ -z "$PROJECT_ID" ]]; then
    echo "  WARN Could not resolve project node ID for Status field configuration."
    echo "       Refresh GitHub CLI project scope, then rerun installer:"
    echo "       gh auth refresh -s project"
    return 0
  fi

  local FIELD_ID
  FIELD_ID="$(_board_status_field_id "$PROJECT_NUMBER")"

  if [[ -z "$FIELD_ID" ]]; then
    echo "  Status field not found; creating it..."
    FIELD_ID="$(_board_create_status_field "$PROJECT_ID")"
    if [[ -z "$FIELD_ID" ]]; then
      echo "  WARN Could not create Status field."
      echo "       Refresh GitHub CLI project scope, then rerun installer:"
      echo "       gh auth refresh -s project"
      return 0
    fi
  fi

  local GH_ERR GH_PAYLOAD
  GH_ERR="$(mktemp /tmp/harnessable_gh_status_field.XXXXXX)"
  GH_PAYLOAD="$(mktemp /tmp/harnessable_gh_status_field_payload.XXXXXX)"
  python3 - "$GH_PAYLOAD" "$FIELD_ID" <<'PYEOF'
import json
import sys

payload_path, field_id = sys.argv[1:3]
options = [
    ("BACKLOG", "GRAY"),
    ("MANDATED", "BLUE"),
    ("IN_RECON", "BLUE"),
    ("PLANNED", "BLUE"),
    ("IN_PROGRESS", "YELLOW"),
    ("IN_REVIEW", "ORANGE"),
    ("BLOCKED", "RED"),
    ("NEEDS_REVISION", "RED"),
    ("VERIFIED", "GREEN"),
    ("DONE", "GREEN"),
]
payload = {
    "query": """
mutation($fieldId: ID!, $options: [ProjectV2SingleSelectFieldOptionInput!]!) {
  updateProjectV2Field(input: {
    fieldId: $fieldId
    singleSelectOptions: $options
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
      }
    }
  }
}
""",
    "variables": {
        "fieldId": field_id,
        "options": [
            {"name": name, "color": color, "description": ""}
            for name, color in options
        ],
    },
}
with open(payload_path, "w") as f:
    json.dump(payload, f)
PYEOF

  if gh api graphql --input "$GH_PAYLOAD" >/dev/null 2>"$GH_ERR"; then
    echo "  Status field configured: ${#HARNESSABLE_STATUS_OPTIONS[@]} prescribed options"
  else
    echo "  WARN Could not replace Status field options."
    if [[ -s "$GH_ERR" ]]; then
      echo "       gh updateProjectV2Field error:"
      sed 's/^/        /' "$GH_ERR"
    fi
    echo "       Refresh GitHub CLI project scope, then rerun installer:"
    echo "       gh auth refresh -s project"
  fi

  rm -f "$GH_ERR" "$GH_PAYLOAD"
}

_board_check_status_field() {
  local PROJECT_NUMBER="$1"
  _board_configure_status_field "$PROJECT_NUMBER"
}

_board_write_agents_md() {
  local PROJECT_NUMBER="$1"
  local PROJECT_URL="$2"
  local AGENTS_FILE="$TARGET/AGENTS.md"

  [[ -f "$AGENTS_FILE" ]] || return 0

  python3 - "$AGENTS_FILE" \
    "$PROJECT_NUMBER" "$PROJECT_URL" \
    "$GITHUB_BOARD_OWNER" "$GITHUB_BOARD_OWNER_TYPE" <<'PYEOF'
import re, sys
agents_path, number, url, owner, owner_type = sys.argv[1:6]
content = open(agents_path).read()

owner_type_line = f"owner_type:   {owner_type}\n" if owner_type else ""

tracker_block = f"""## Project Tracker

tool:         GitHub Projects
owner:        {owner}
{owner_type_line}project:      {number}
integration:  gh CLI / MoijafcorGithubProjects MCP
task_url:     {url}/items

Expected GH CLI patterns:
- gh project item-list {number} --owner {owner}
- gh project item-create {number} --owner {owner} --title "..."
- gh api graphql ... for field/status mutations

Required board statuses:
BACKLOG · MANDATED · IN_RECON · PLANNED · IN_PROGRESS ·
IN_REVIEW · BLOCKED · NEEDS_REVISION · VERIFIED · DONE"""

if re.search(r'##\s+Project Tracker', content):
  content = re.sub(
    r'##\s+Project Tracker\s*\n.*?(?=\n##|\Z)',
    tracker_block + '\n',
    content, flags=re.DOTALL
  )
else:
  content = content.rstrip() + '\n\n' + tracker_block + '\n'

open(agents_path, 'w').write(content)
print(f'  PATCHED AGENTS.md ## Project Tracker → project #{number}')
PYEOF
}

# ── detect_tracker / apply_tracker ────────────────────────────────────────────

detect_tracker() {
  local AGENTS_FILE="$TARGET/AGENTS.md"
  [[ -f "$AGENTS_FILE" ]] || return 0

  local TRACKER_VALUES
  TRACKER_VALUES="$(python3 - "$AGENTS_FILE" <<'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'##\s+Project Tracker\s*\n(.*?)(?=\n##|\Z)', content, re.DOTALL | re.I)
if not m:
    sys.exit(0)
block = m.group(1)

def value(pattern):
    found = re.search(pattern, block, re.I | re.M)
    return found.group(1).strip() if found else ''

print(value(r'^\s*tool\s*:\s*(.+)$'))
print(value(r'^\s*(?:task_url|Task URL pattern)\s*:\s*(.+)$'))
print(value(r'^\s*integration\s*:\s*(.+)$'))
PYEOF
  2>/dev/null || true)"

  TRACKER_TOOL="$(printf '%s\n' "$TRACKER_VALUES" | sed -n '1p')"
  TRACKER_URL="$(printf '%s\n' "$TRACKER_VALUES" | sed -n '2p')"
  TRACKER_INTEGRATION="$(printf '%s\n' "$TRACKER_VALUES" | sed -n '3p')"
}

apply_tracker() {
  local DST="$1"
  [[ -f "$DST" ]] || return 0

  python3 - "$DST" "$TRACKER_TOOL" "$TRACKER_URL" "$TRACKER_INTEGRATION" <<'PYEOF'
import re, sys
dst, tracker_tool, tracker_url, tracker_integration = sys.argv[1:5]
content = open(dst).read()

if tracker_tool:
    block_lines = [f'# Tracker: {tracker_tool}']
    if tracker_url:
        block_lines.append(f'# Task URL pattern: {tracker_url}')
    if tracker_integration:
        block_lines.append(f'# Integration: {tracker_integration}')
    content = re.sub(
        r'# REPLACE: project tracker URL pattern and fetch command',
        '\n'.join(block_lines),
        content
    )

content = re.sub(r'# REPLACE: framework base path \(if not docs/harness/\)\n', '', content)
open(dst, 'w').write(content)
PYEOF

  # Strip base-path REPLACE comment — paths are always correct
  # for standard installs (docs/harness/ is the default)
  sed -i '/# REPLACE: update base path if not docs\/harness\//d' "$DST"

  # Fill high-risk surfaces from AGENTS.md ## Ask First
  python3 << PYEOF
import pathlib, re, sys

dst    = pathlib.Path("$DST")
agents = pathlib.Path("$TARGET/AGENTS.md")
content = dst.read_text()

if '# REPLACE: add project-specific high-risk surface areas' not in content:
    sys.exit(0)  # already filled

if not agents.exists():
    print("  REPLACE: high-risk surfaces — AGENTS.md absent, marker left")
    sys.exit(0)

ask_first = re.search(
    r'##\s+Ask First\s*\n(.*?)(?=\n##|\Z)',
    agents.read_text(), re.DOTALL
)

if not ask_first:
    print("  REPLACE: high-risk surfaces — no ## Ask First, marker left")
    sys.exit(0)

items = [
    l.strip().lstrip('-').strip()
    for l in ask_first.group(1).strip().splitlines()
    if l.strip() and not l.strip().startswith('#')
]
surfaces = '\n'.join(f'   - {i}' for i in items if i)

content = content.replace(
    '   configuration: stop and escalate to the full pipeline first.\n'
    '   # REPLACE: add project-specific high-risk surface areas here\n',
    f'   configuration: stop and escalate to the full pipeline first.\n'
    f'   Project-specific high-risk surfaces (from AGENTS.md):\n'
    f'{surfaces}\n'
)
dst.write_text(content)
print(f"  high-risk surfaces: {len(items)} item(s) from AGENTS.md")
PYEOF
}

# ── sync_skills ───────────────────────────────────────────────────────────────

sync_skills() {
  # Skills are framework-owned — same tier as hooks.
  # They are overwritten unconditionally on every sync.
  # No MANUAL_MERGE path exists for skill files.
  # All project-specific configuration flows through AGENTS.md.
  # The apply_tracker() function fills customisation points
  # automatically from AGENTS.md ## Project Tracker.
  # Rationale: June 2026 audit found zero legitimate skill
  # customisations — all were tracker config belonging in AGENTS.md.
  echo "── Claude Code commands ─────────────────────────────────────────────────"

  detect_tracker

  if [[ -n "$TRACKER_TOOL" ]]; then
    echo "  INFO  Tracker: $TRACKER_TOOL"
    [[ -n "$TRACKER_URL" ]] && echo "        URL pattern: $TRACKER_URL"
    [[ -n "$TRACKER_INTEGRATION" ]] && echo "        Integration: $TRACKER_INTEGRATION"
  else
    echo "  WARN  No tracker detected in AGENTS.md ## Project Tracker"
    ACTION_ITEMS+=("Add ## Project Tracker to AGENTS.md and re-run install to auto-fill tracker block")
  fi

  ensure_dir "$TARGET/.claude/commands"

  local SRC_SKILLS="$FRAMEWORK_ROOT/framework/templates/skills"
  local _SKILL_TMP
  _SKILL_TMP="$(mktemp /tmp/harnessable_skill.XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -f '$_SKILL_TMP'" EXIT

  local f name dst label REMAINING
  for f in "$SRC_SKILLS/"*.md; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    dst="$TARGET/.claude/commands/$name"
    label=".claude/commands/$name"

    python3 - "$f" "$TRACKER_TOOL" "$TRACKER_URL" "$TRACKER_INTEGRATION" \
      > "$_SKILL_TMP" <<'PYEOF'
import re, sys
src, tracker_tool, tracker_url, tracker_integration = sys.argv[1:5]
content = open(src).read()
if tracker_tool:
    block_lines = [f'# Tracker: {tracker_tool}']
    if tracker_url:
        block_lines.append(f'# Task URL pattern: {tracker_url}')
    if tracker_integration:
        block_lines.append(f'# Integration: {tracker_integration}')
    content = re.sub(
        r'# REPLACE: project tracker URL pattern and fetch command',
        '\n'.join(block_lines),
        content
    )
content = re.sub(r'# REPLACE: framework base path \(if not docs/harness/\)\n', '', content)
sys.stdout.write(content)
PYEOF

    if [[ ! -f "$dst" ]]; then
      cp "$_SKILL_TMP" "$dst"
      apply_tracker "$dst"
      echo "  SYNCED  $label  (NEW)"
      SK_SYNCED=$((SK_SYNCED + 1))
    elif diff -q "$_SKILL_TMP" "$dst" &>/dev/null; then
      echo "  OK      $label"
      SK_OK=$((SK_OK + 1))
    else
      # Skills are framework-owned: always sync. Project customisation belongs
      # in AGENTS.md, not in skill files. Overwrite unconditionally and report
      # how much project-local content was discarded so the operator can verify.
      local SK_REMOVED SK_ADDED
      SK_REMOVED="$(diff "$dst" "$_SKILL_TMP" | grep -c "^<" || true)"
      SK_ADDED="$(diff  "$dst" "$_SKILL_TMP" | grep -c "^>" || true)"
      cp "$_SKILL_TMP" "$dst"
      apply_tracker "$dst"
      if [[ "$SK_REMOVED" -gt 0 ]]; then
        echo "  SYNCED  $label  ($SK_REMOVED project lines replaced, +$SK_ADDED framework lines)"
      else
        echo "  SYNCED  $label  (+$SK_ADDED lines)"
      fi
      SK_SYNCED=$((SK_SYNCED + 1))
    fi

    if [[ -f "$dst" ]]; then
      REMAINING="$(grep -c "# REPLACE:" "$dst" 2>/dev/null || true)"
      if [[ "$REMAINING" -gt 0 ]]; then
        REPLACE_COUNT=$((REPLACE_COUNT + REMAINING))
        REPLACE_FILES+=("$label ($REMAINING marker(s))")
      fi
    fi
  done

  rm -f "$_SKILL_TMP"
  trap - EXIT

  echo ""
}

# ── sync_packages ─────────────────────────────────────────────────────────────
# Syncs framework package adapters to target packages/ directory.
# Package adapters are governance bridges — not the packages themselves.
# Skips packages that have been locally customised (MANUAL_MERGE).

sync_packages() {
  local SRC_DIR="$FRAMEWORK_ROOT/framework/packages"
  local DST_DIR="$TARGET/packages"

  # No framework packages to sync — skip silently
  [[ -d "$SRC_DIR" ]] || return 0

  local found=0
  for pkg_dir in "$SRC_DIR"/*/; do
    [[ -d "$pkg_dir" ]] || continue
    [[ -f "$pkg_dir/PACKAGE.md" ]] || continue
    found=$((found + 1))
  done

  [[ "$found" -gt 0 ]] || return 0

  echo "── Packages ─────────────────────────────────────────────────────────────"
  ensure_dir "$DST_DIR"

  for pkg_dir in "$SRC_DIR"/*/; do
    [[ -d "$pkg_dir" ]] || continue
    local pkg_name
    pkg_name="$(basename "$pkg_dir")"
    local dst_pkg="$DST_DIR/$pkg_name"
    [[ -f "$pkg_dir/PACKAGE.md" ]] || continue

    ensure_dir "$dst_pkg"

    # Sync PACKAGE.md unconditionally
    _sync_package_file \
      "$pkg_dir/PACKAGE.md" \
      "$dst_pkg/PACKAGE.md" \
      "packages/$pkg_name/PACKAGE.md"

    if [[ -f "$pkg_dir/README.md" ]]; then
      _sync_package_file \
        "$pkg_dir/README.md" \
        "$dst_pkg/README.md" \
        "packages/$pkg_name/README.md"
    fi

    # Sync skills/ — framework-owned, replace unconditionally
    if [[ -d "$pkg_dir/skills" ]]; then
      ensure_dir "$dst_pkg/skills"
      local f name
      for f in "$pkg_dir/skills/"*.md; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        _sync_package_file \
          "$f" \
          "$dst_pkg/skills/$name" \
          "packages/$pkg_name/skills/$name"
      done
    fi

    # Sync adapter/ — framework-owned, replace unconditionally
    if [[ -d "$pkg_dir/adapter" ]]; then
      ensure_dir "$dst_pkg/adapter"
      for f in "$pkg_dir/adapter/"*; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        _sync_package_file \
          "$f" \
          "$dst_pkg/adapter/$name" \
          "packages/$pkg_name/adapter/$name"
      done
    fi
  done

  echo ""
}

_sync_package_file() {
  local SRC="$1" DST="$2" LABEL="$3"
  ensure_dir "$(dirname "$DST")"

  if [[ ! -f "$DST" ]]; then
    cp "$SRC" "$DST"
    echo "  SYNCED  $LABEL  (NEW)"
    PKG_SYNCED=$((PKG_SYNCED + 1))
    return
  fi

  if diff -q "$SRC" "$DST" &>/dev/null; then
    echo "  OK      $LABEL"
    PKG_OK=$((PKG_OK + 1))
    return
  fi

  cp "$SRC" "$DST"
  echo "  SYNCED  $LABEL"
  PKG_SYNCED=$((PKG_SYNCED + 1))
}

# ── merge_settings ────────────────────────────────────────────────────────────

merge_settings() {
  echo "── Config: .claude/settings.json ────────────────────────────────────────"

  local SETTINGS_FILE="$TARGET/.claude/settings.json"
  ensure_dir "$TARGET/.claude"

  local HAS_PRECOMPACT="false"
  if [[ -d "$FRAMEWORK_ROOT/framework/hooks/pre_compact" ]]; then
    if find "$FRAMEWORK_ROOT/framework/hooks/pre_compact" -name "*.py" | grep -q .; then
      HAS_PRECOMPACT="true"
    fi
  fi

  CFG_SETTINGS="$(python3 - "$SETTINGS_FILE" "$HAS_PRECOMPACT" <<'PYEOF'
import json, sys, os

settings_path = sys.argv[1]
has_precompact = sys.argv[2] == 'true'

if os.path.exists(settings_path):
    try:
        settings = json.loads(open(settings_path).read())
    except json.JSONDecodeError:
        settings = {}
else:
    settings = {}

hooks = settings.setdefault('hooks', {})

def ensure_hook(hooks, event, matcher, command):
    entries = hooks.setdefault(event, [])
    for entry in entries:
        for h in entry.get('hooks', []):
            if h.get('command') == command:
                return False
    new_entry = {'hooks': [{'type': 'command', 'command': command}]}
    if matcher is not None:
        new_entry['matcher'] = matcher
    entries.append(new_entry)
    return True

changed = False
changed |= ensure_hook(hooks, 'PreToolUse', 'Bash',
                        'python3 docs/harness/hooks/run.py pre_tool_use')
changed |= ensure_hook(hooks, 'PostToolUse', '',
                        'python3 docs/harness/hooks/run.py post_tool_use')
changed |= ensure_hook(hooks, 'Stop', None,
                        'python3 docs/harness/hooks/run.py stop')
if has_precompact:
    changed |= ensure_hook(hooks, 'PreCompact', None,
                            'python3 docs/harness/hooks/run.py pre_compact')

settings.pop('_readme', None)

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

json.loads(open(settings_path).read())
print('PATCHED' if changed else 'OK')
PYEOF
)"

  echo "  $CFG_SETTINGS  .claude/settings.json"

  git -C "$TARGET" add -f "$TARGET/.claude/settings.json" 2>/dev/null || true
  git -C "$TARGET" add -f "$TARGET/.claude/commands/" 2>/dev/null || true

  echo ""
}

# ── patch_gitignore ───────────────────────────────────────────────────────────

patch_gitignore() {
  echo "── Config: .gitignore ───────────────────────────────────────────────────"

  local GITIGNORE_FILE="$TARGET/.gitignore"
  [[ -f "$GITIGNORE_FILE" ]] || touch "$GITIGNORE_FILE"

  local PATCHED=false

  if _ensure_gitignore_pattern "$GITIGNORE_FILE" ".harness/";            then PATCHED=true; fi
  if _ensure_gitignore_pattern "$GITIGNORE_FILE" ".claude/*";            then PATCHED=true; fi
  if _ensure_gitignore_pattern "$GITIGNORE_FILE" "!.claude/settings.json"; then PATCHED=true; fi
  if _ensure_gitignore_pattern "$GITIGNORE_FILE" "!.claude/commands/";   then PATCHED=true; fi
  if _ensure_gitignore_pattern "$GITIGNORE_FILE" ".harnessable/logs/";   then PATCHED=true; fi

  if $PATCHED; then
    echo "  PATCHED  .gitignore"
    CFG_GITIGNORE="PATCHED"
  else
    echo "  OK       .gitignore"
    CFG_GITIGNORE="OK"
  fi

  if git -C "$TARGET" check-ignore -q ".harnessable/test" 2>/dev/null; then
    echo "  OK       git check-ignore verified: .harnessable/ is ignored"
  else
    echo "  WARN     git check-ignore did not confirm .harnessable/ — check .gitignore"
    ACTION_ITEMS+=("Verify .harnessable/ is properly ignored by git in $TARGET")
  fi

  echo ""
}

_ensure_gitignore_pattern() {
  local FILE="$1" PATTERN="$2"
  if ! grep -qF "$PATTERN" "$FILE" 2>/dev/null; then
    echo "$PATTERN" >> "$FILE"
    return 0
  fi
  return 1
}

# ── audit_ignored_installed_paths ──────────────────────────────────────────────

audit_ignored_installed_paths() {
  echo "── Git ignore audit ─────────────────────────────────────────────────────"

  local paths=(
    "AGENTS.md"
    "docs/harness"
    "docs/harness/vendor/harnessable"
    ".claude/settings.json"
    ".claude/commands"
    ".harnessable/config.json"
  )

  local ignored=0
  local path
  for path in "${paths[@]}"; do
    if git -C "$TARGET" check-ignore -q "$path" 2>/dev/null; then
      echo "  WARN  installed path is ignored by git: $path"
      echo "        Remove or narrow the ignore rule, or run:"
      echo "        git -C $TARGET add -f $path"
      ACTION_ITEMS+=("Review .gitignore: installed harnessable path ignored: $path")
      ignored=$((ignored + 1))
    fi
  done

  if [[ "$ignored" -eq 0 ]]; then
    echo "  OK    installed harnessable paths are not ignored by git"
  fi

  echo ""
}

# ── merge_config ──────────────────────────────────────────────────────────────

merge_config() {
  echo "── Config: .harnessable/config.json ─────────────────────────────────────"

  local CONFIG_FILE="$TARGET/.harnessable/config.json"
  ensure_dir "$TARGET/.harnessable"

  CFG_CONFIG="$(python3 - "$CONFIG_FILE" <<'PYEOF'
import json, sys, os

config_path = sys.argv[1]

if os.path.exists(config_path):
    try:
        config = json.loads(open(config_path).read())
    except json.JSONDecodeError:
        config = {}
else:
    config = {}

changed = False

audit = config.setdefault('audit', {})
for key, val in {'log_dir': '.harnessable/logs', 'max_field_bytes': 512, 'rotate': True}.items():
    if key not in audit:
        audit[key] = val
        changed = True

if 'codebases' not in config:
    config['codebases'] = []
    changed = True

if 'sibling_projects' not in config:
    config['sibling_projects'] = []
    changed = True

config['_readme_sibling_projects'] = (
    "List sibling project paths for mandate_snapshot.py inclusion. "
    "Example: ['../my-other-repo', '../another-repo']"
)

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

json.loads(open(config_path).read())
print('PATCHED' if changed else 'OK')
PYEOF
)"

  echo "  $CFG_CONFIG  .harnessable/config.json"
  echo ""
}

# ── migrate_audit_log ─────────────────────────────────────────────────────────

migrate_audit_log() {
  echo "── Audit ────────────────────────────────────────────────────────────────"

  local AUDIT_LOG="$TARGET/.harnessable/audit.log"
  local MIGRATE_SCRIPT="$FRAMEWORK_ROOT/framework/tools/migrate_audit_log.py"

  if [[ ! -f "$AUDIT_LOG" ]]; then
    echo "  OK   no legacy audit.log to migrate"
    AUDIT_RESULT="OK (no legacy log)"
    echo ""
    return
  fi

  local TMP_SCRIPT="$TARGET/.harnessable/_migrate_tmp.py"
  cp "$MIGRATE_SCRIPT" "$TMP_SCRIPT"

  local OUTPUT EXIT_CODE=0
  OUTPUT="$(python3 "$TMP_SCRIPT" 2>&1)" || EXIT_CODE=$?
  rm -f "$TMP_SCRIPT"

  if [[ "$EXIT_CODE" -eq 0 ]]; then
    local ARCHIVES
    ARCHIVES="$(echo "$OUTPUT" | grep -oP 'Archives created:\s*\K\d+' || echo '?')"
    echo "  MIGRATED  .harnessable/audit.log → $ARCHIVES archives"
    AUDIT_RESULT="MIGRATED ($ARCHIVES archives)"
  else
    echo "  WARN  audit.log migration failed:"
    echo "$OUTPUT" | while IFS= read -r line; do echo "    $line"; done
    AUDIT_RESULT="FAILED"
  fi

  echo ""
}

# ── report ────────────────────────────────────────────────────────────────────

report() {
  local PROJECT_NAME
  PROJECT_NAME="$(basename "$TARGET")"

  echo "═══ harnessable sync: $PROJECT_NAME → $FRAMEWORK_VERSION ═══"
  echo ""
  printf "  %-24s %d synced / %d current\n" \
    "Tier 2 (vendor):" "$T2_SYNCED" "$T2_OK"
  printf "  %-24s %d synced / %d current / %d manual merge\n" \
    "Agents ($(( AG_SYNCED + AG_OK + AG_MERGE ))):" "$AG_SYNCED" "$AG_OK" "$AG_MERGE"
  printf "  %-24s %d synced / %d current\n" \
    "Hooks ($(( HK_SYNCED + HK_OK )) files):" "$HK_SYNCED" "$HK_OK"
  printf "  %-24s %d synced / %d current\n" \
    "Tools ($(( TL_SYNCED + TL_OK ))):" "$TL_SYNCED" "$TL_OK"
  printf "  %-24s %d synced / %d current\n" \
    "Templates ($(( TM_SYNCED + TM_OK ))):" "$TM_SYNCED" "$TM_OK"
  printf "  %-24s %d synced / %d current / %d manual merge\n" \
    "Models manifest:" "$MM_SYNCED" "$MM_OK" "$MM_MERGE"
  printf "  %-24s %d synced / %d current\n" \
    "Skills ($(( SK_SYNCED + SK_OK ))):" "$SK_SYNCED" "$SK_OK"
  if [[ $((PKG_SYNCED + PKG_OK)) -gt 0 ]]; then
    printf "  %-24s %d synced / %d current\n" \
      "Packages ($(( PKG_SYNCED + PKG_OK ))):" "$PKG_SYNCED" "$PKG_OK"
  fi
  printf "  %-24s settings=%s  .gitignore=%s  config=%s\n" \
    "Config:" "$CFG_SETTINGS" "$CFG_GITIGNORE" "$CFG_CONFIG"
  printf "  %-24s %s\n" "Audit:" "$AUDIT_RESULT"

  if [[ "$REPLACE_COUNT" -gt 0 ]]; then
    printf "  %-24s %d remaining\n" "REPLACE markers:" "$REPLACE_COUNT"
    for f in "${REPLACE_FILES[@]}"; do echo "    • $f"; done
  else
    printf "  %-24s none\n" "REPLACE markers:"
  fi

  if [[ ${#MERGE_FILES[@]} -gt 0 || ${#ACTION_ITEMS[@]} -gt 0 || "$REPLACE_COUNT" -gt 0 ]]; then
    echo ""
    echo "  ─── Action required ──────────────────────────────────────────────"
    if [[ ${#MERGE_FILES[@]} -gt 0 ]]; then
      echo "  MANUAL_MERGE_REQUIRED (${#MERGE_FILES[@]}):"
      for f in "${MERGE_FILES[@]}"; do echo "    $f"; done
    fi
    if [[ "$REPLACE_COUNT" -gt 0 ]]; then
      echo "  REPLACE markers remaining ($REPLACE_COUNT):"
      for f in "${REPLACE_FILES[@]}"; do echo "    $f"; done
    fi
    for item in "${ACTION_ITEMS[@]}"; do
      echo "  ACTION: $item"
    done
  fi

  echo ""
}

# ── next_steps ────────────────────────────────────────────────────────────────

next_steps() {
  echo "  Next steps:"
  local step=1
  if [[ ${#MERGE_FILES[@]} -gt 0 ]]; then
    echo "  $step. Resolve MANUAL_MERGE files listed above"
    step=$((step + 1))
  fi
  if [[ "$REPLACE_COUNT" -gt 0 ]]; then
    echo "  $step. Fill remaining REPLACE markers in .claude/commands/*.md"
    step=$((step + 1))
  fi
  echo "  $step. git -C $TARGET add -A"
  step=$((step + 1))
  echo "  $step. git -C $TARGET commit -m \"chore: sync harnessable → $FRAMEWORK_VERSION\""
  echo ""
}

# ── main ──────────────────────────────────────────────────────────────────────

main() {
  parse_args "$@"
  check_framework
  check_target

  local PROJECT_NAME
  PROJECT_NAME="$(basename "$TARGET")"

  echo ""
  echo "harnessable $FRAMEWORK_VERSION  [mode: $MODE]"
  echo "  Source:  $FRAMEWORK_ROOT"
  echo "  Target:  $TARGET"
  echo ""

  bootstrap_agents_md
  bootstrap_world_models
  bootstrap_packages
  bootstrap_per_directory
  bootstrap_dreams_directory
  bootstrap_evolutions_directory
  cleanup_vendor_templates
  setup_github_board
  sync_tier2
  sync_hooks
  sync_agents
  sync_tools
  sync_templates
  sync_models_manifest
  sync_skills
  sync_packages
  merge_settings
  patch_gitignore
  merge_config
  audit_ignored_installed_paths
  migrate_audit_log

  report
  next_steps
}

main "$@"
