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

# Counters
T2_SYNCED=0; T2_OK=0
AG_SYNCED=0; AG_OK=0; AG_MERGE=0
HK_SYNCED=0; HK_OK=0
TL_SYNCED=0; TL_OK=0
TM_SYNCED=0; TM_OK=0
SK_SYNCED=0; SK_OK=0; SK_MERGE=0
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
    exit 0
  fi

  if [[ "${1:-}" == "--update" ]]; then
    MODE="update"
    TARGET="${2:-$(pwd)}"
  elif [[ -n "${1:-}" ]]; then
    MODE="fresh"
    TARGET="$1"
  else
    echo "Usage: bash install.sh /path/to/project"
    echo "       bash install.sh --update [/path/to/project]"
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

  local SRC_TEMPLATES="$FRAMEWORK_ROOT/framework/templates"
  if [[ -d "$SRC_TEMPLATES" ]]; then
    ensure_dir "$DST_VENDOR/templates"
    local TMPL_CHANGES TMPL_COUNT
    TMPL_CHANGES="$(rsync -a --delete --exclude 'skills/' --itemize-changes \
      "$SRC_TEMPLATES/" "$DST_VENDOR/templates/" 2>/dev/null | grep -cE '^[>*<c]' || true)"
    TMPL_COUNT="$(find "$DST_VENDOR/templates" -type f 2>/dev/null | wc -l | tr -d '[:space:]')"
    if [[ "$TMPL_CHANGES" -gt 0 ]]; then
      echo "  SYNCED  docs/harness/vendor/harnessable/templates/ ($TMPL_COUNT files)"
      T2_SYNCED=$((T2_SYNCED + 1))
    else
      echo "  OK      docs/harness/vendor/harnessable/templates/ ($TMPL_COUNT files)"
      T2_OK=$((T2_OK + 1))
    fi
  fi

  _sync_vendor_file "$SRC_VENDOR/KNOWLEDGE_GRAPH.yaml" \
    "$DST_VENDOR/KNOWLEDGE_GRAPH.yaml" \
    "docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"

  _sync_vendor_file "$SRC_VENDOR/HARNESSABLE_VERSION" \
    "$DST_VENDOR/HARNESSABLE_VERSION" \
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

# ── detect_tracker / apply_tracker ────────────────────────────────────────────

detect_tracker() {
  local AGENTS_FILE="$TARGET/AGENTS.md"
  [[ -f "$AGENTS_FILE" ]] || return 0

  TRACKER_TOOL="$(python3 - "$AGENTS_FILE" <<'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'## Project Tracker\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
if not m: sys.exit(0)
tm = re.search(r'Tool:\s*(.+)', m.group(1))
print(tm.group(1).strip() if tm else '', end='')
PYEOF
  2>/dev/null || true)"

  TRACKER_URL="$(python3 - "$AGENTS_FILE" <<'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'## Project Tracker\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
if not m: sys.exit(0)
um = re.search(r'Task URL pattern:\s*(.+)', m.group(1))
print(um.group(1).strip() if um else '', end='')
PYEOF
  2>/dev/null || true)"

  TRACKER_INTEGRATION="$(python3 - "$AGENTS_FILE" <<'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'## Project Tracker\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
if not m: sys.exit(0)
im = re.search(r'Integration:\s*(.+)', m.group(1))
print(im.group(1).strip() if im else '', end='')
PYEOF
  2>/dev/null || true)"
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
}

# ── sync_skills ───────────────────────────────────────────────────────────────

sync_skills() {
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
    elif grep -q "# REPLACE:" "$dst" 2>/dev/null; then
      cp "$_SKILL_TMP" "$dst"
      apply_tracker "$dst"
      echo "  SYNCED  $label  (REPLACE markers refreshed)"
      SK_SYNCED=$((SK_SYNCED + 1))
    else
      echo "  MERGE   $label  ← MANUAL_MERGE_REQUIRED"
      SK_MERGE=$((SK_MERGE + 1))
      MERGE_FILES+=("$label")
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
    "Skills ($(( SK_SYNCED + SK_OK + SK_MERGE ))):" "$SK_SYNCED" "$SK_OK" "$SK_MERGE"
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

  sync_tier2
  sync_hooks
  sync_agents
  sync_tools
  sync_templates
  sync_skills
  merge_settings
  patch_gitignore
  merge_config
  migrate_audit_log

  report
  next_steps
}

main "$@"
