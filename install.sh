#!/usr/bin/env bash
# harnessable — install.sh
#
# Installs harnessable into a target project. Idempotent.
#
# Usage:
#   bash install.sh /path/to/your-project
#
# What this installs:
#   Tier 2 (vendor — never modify):
#     docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml
#     docs/harness/vendor/harnessable/references/
#     docs/harness/vendor/harnessable/templates/
#     docs/harness/vendor/harnessable/HARNESSABLE_VERSION
#
#   Tier 1 (scaffold — copy and own):
#     docs/harness/agents/{architect,engineer,coder,qa,sre,security}.md
#     docs/harness/hooks/  (all hook scripts and settings template)
#     docs/harness/tools/web_verify.py
#
#   Claude Code commands:
#     .claude/commands/{architect,engineer,coder,qa,sre,security}.md
#     (customised from AGENTS.md tracker config where detectable)
#
#   Codex adapter:
#     Use codex/install.sh for Codex AGENTS.md + skill installation.
#
#   Config:
#     .claude/settings.json  — PreCompact block wired
#     .gitignore             — .harnessable/ entry, exceptions
#     .harnessable/config.json — audit block
#
# Output prefixes:
#   NEW    — file created for the first time
#   OK     — file already current, no change
#   UPD    — file updated (was outdated)
#   SKIP   — customised file left untouched (diff logged)
#   WARN   — something needs attention but install continues
#   ACTION — operator must do something before next session
#   ERR    — fatal; install halted

set -euo pipefail

# ── Arguments ─────────────────────────────────────────────────────────────────

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: bash install.sh /path/to/your-project"
  echo ""
  echo "  Installs harnessable into the target project directory."
  exit 1
fi

FRAMEWORK_ROOT="$(dirname "$(realpath "$0")")"

KG_SRC="$FRAMEWORK_ROOT/framework/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"
if [[ ! -f "$KG_SRC" ]]; then
  echo "ERR  FRAMEWORK_ROOT does not look like harnessable:"
  echo "     Missing: $KG_SRC"
  exit 1
fi

if ! git -C "$TARGET" rev-parse --git-dir &>/dev/null 2>&1; then
  echo "ERR  Target is not a git repository: $TARGET"
  exit 2
fi

FRAMEWORK_VERSION="$(git -C "$FRAMEWORK_ROOT" rev-parse --short HEAD 2>/dev/null \
  || cat "$FRAMEWORK_ROOT/framework/vendor/harnessable/HARNESSABLE_VERSION")"

echo ""
echo "Installing harnessable $FRAMEWORK_VERSION"
echo "  Source:  $FRAMEWORK_ROOT"
echo "  Target:  $TARGET"
echo ""

# ── Counters ──────────────────────────────────────────────────────────────────

T2_NEW=0; T2_OK=0
T1_NEW=0; T1_OK=0; T1_SKIP=0
SK_NEW=0; SK_OK=0; SK_MERGE=0
REPLACE_COUNT=0
REPLACE_FILES=()
MERGE_FILES=()
ACTION_ITEMS=()
LAST_STATUS=""

CFG_SETTINGS="—"; CFG_GITIGNORE="—"; CFG_CONFIG="—"

# ── Helpers ───────────────────────────────────────────────────────────────────

ensure_dir() { mkdir -p "$1"; }

# Sets LAST_STATUS: new | upd | ok
copy_if_changed() {
  local SRC="$1" DST="$2" LABEL="$3"
  ensure_dir "$(dirname "$DST")"
  if [[ ! -f "$DST" ]]; then
    cp "$SRC" "$DST"
    echo "  NEW  $LABEL"
    LAST_STATUS="new"; return 0
  fi
  if ! diff -q "$SRC" "$DST" &>/dev/null; then
    cp "$SRC" "$DST"
    echo "  UPD  $LABEL"
    LAST_STATUS="upd"; return 0
  fi
  echo "  OK   $LABEL"
  LAST_STATUS="ok"; return 0
}

# Sets LAST_STATUS: new | upd | skip
# Treats a file with REPLACE markers as uncustomised and overwrites it.
copy_scaffold() {
  local SRC="$1" DST="$2" LABEL="$3"
  ensure_dir "$(dirname "$DST")"
  if [[ ! -f "$DST" ]]; then
    cp "$SRC" "$DST"
    echo "  NEW  $LABEL"
    LAST_STATUS="new"; return 0
  fi
  if grep -q "# REPLACE:" "$DST" 2>/dev/null; then
    cp "$SRC" "$DST"
    echo "  UPD  $LABEL (uncustomised)"
    LAST_STATUS="upd"; return 0
  fi
  local DIFF_LINES
  DIFF_LINES="$(diff "$SRC" "$DST" 2>/dev/null | wc -l | tr -d '[:space:]')"
  echo "  SKIP $LABEL ($DIFF_LINES diff lines — customised, not overwritten)"
  LAST_STATUS="skip"; return 0
}

t1_count() {
  case "$LAST_STATUS" in
    new|upd) T1_NEW=$((T1_NEW + 1)) ;;
    skip)    T1_SKIP=$((T1_SKIP + 1)) ;;
    *)       T1_OK=$((T1_OK + 1)) ;;
  esac
}

# ── Tier 2 install ────────────────────────────────────────────────────────────

echo "── Tier 2 (vendor) ──────────────────────────────────────────────────────"

SRC_VENDOR="$FRAMEWORK_ROOT/framework/vendor/harnessable"
DST_VENDOR="$TARGET/docs/harness/vendor/harnessable"

# Validate KNOWLEDGE_GRAPH.yaml before proceeding
python3 - "$KG_SRC" <<'PYEOF'
import yaml, sys
try:
    yaml.safe_load(open(sys.argv[1]))
except Exception as e:
    print(f'ERR  KNOWLEDGE_GRAPH.yaml is not valid YAML: {e}', file=sys.stderr)
    sys.exit(1)
PYEOF

ensure_dir "$DST_VENDOR"

# references/ — rsync with --delete (never diverge from source)
rsync -a --delete "$SRC_VENDOR/references/" "$DST_VENDOR/references/"
REF_COUNT="$(find "$DST_VENDOR/references" -type f | wc -l | tr -d '[:space:]')"
echo "  OK   docs/harness/vendor/harnessable/references/ ($REF_COUNT files)"
T2_OK=$((T2_OK + REF_COUNT))

# templates/ — vendor copy of framework templates (skills/ excluded — those go to .claude/commands/)
SRC_TEMPLATES="$FRAMEWORK_ROOT/framework/templates"
if [[ -d "$SRC_TEMPLATES" ]]; then
  ensure_dir "$DST_VENDOR/templates"
  rsync -a --delete --exclude 'skills/' "$SRC_TEMPLATES/" "$DST_VENDOR/templates/"
  TMPL_COUNT="$(find "$DST_VENDOR/templates" -type f | wc -l | tr -d '[:space:]')"
  echo "  OK   docs/harness/vendor/harnessable/templates/ ($TMPL_COUNT files)"
  T2_OK=$((T2_OK + TMPL_COUNT))
fi

# KNOWLEDGE_GRAPH.yaml
copy_if_changed "$KG_SRC" "$DST_VENDOR/KNOWLEDGE_GRAPH.yaml" \
  "docs/harness/vendor/harnessable/KNOWLEDGE_GRAPH.yaml"
[[ "$LAST_STATUS" == "new" || "$LAST_STATUS" == "upd" ]] && T2_NEW=$((T2_NEW+1)) || T2_OK=$((T2_OK+1))

# HARNESSABLE_VERSION
copy_if_changed "$SRC_VENDOR/HARNESSABLE_VERSION" "$DST_VENDOR/HARNESSABLE_VERSION" \
  "docs/harness/vendor/harnessable/HARNESSABLE_VERSION"
[[ "$LAST_STATUS" == "new" || "$LAST_STATUS" == "upd" ]] && T2_NEW=$((T2_NEW+1)) || T2_OK=$((T2_OK+1))

echo ""

# ── Tier 1 scaffold install ───────────────────────────────────────────────────

echo "── Tier 1 (scaffold) ────────────────────────────────────────────────────"

SRC_FW="$FRAMEWORK_ROOT/framework"
DST_HARNESS="$TARGET/docs/harness"

# Agents
for f in "$SRC_FW/agents/"*.md; do
  [[ -f "$f" ]] || continue
  name="$(basename "$f")"
  copy_scaffold "$f" "$DST_HARNESS/agents/$name" "docs/harness/agents/$name"
  t1_count
done

# Hooks — dispatcher
copy_scaffold "$SRC_FW/hooks/run.py" "$DST_HARNESS/hooks/run.py" \
  "docs/harness/hooks/run.py"
t1_count

# Hooks — settings template
copy_scaffold "$SRC_FW/hooks/claude_code_settings_template.json" \
  "$DST_HARNESS/hooks/claude_code_settings_template.json" \
  "docs/harness/hooks/claude_code_settings_template.json"
t1_count

# Hooks — event subdirectories
for subdir in pre_tool_use post_tool_use stop pre_compact; do
  [[ -d "$SRC_FW/hooks/$subdir" ]] || continue
  for f in "$SRC_FW/hooks/$subdir/"*.py; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    copy_scaffold "$f" "$DST_HARNESS/hooks/$subdir/$name" \
      "docs/harness/hooks/$subdir/$name"
    t1_count
  done
done

# Tools
copy_scaffold "$SRC_FW/tools/web_verify.py" "$DST_HARNESS/tools/web_verify.py" \
  "docs/harness/tools/web_verify.py"
t1_count

# Templates (editable Tier 1 copies — vendor has the pristine reference)
for f in "$SRC_FW/templates/"*.md "$SRC_FW/templates/"*.yaml; do
  [[ -f "$f" ]] || continue
  name="$(basename "$f")"
  copy_scaffold "$f" "$DST_HARNESS/templates/$name" "docs/harness/templates/$name"
  t1_count
done

echo ""

# ── Skills install ────────────────────────────────────────────────────────────

echo "── Claude Code commands ─────────────────────────────────────────────────"

# Detect tracker from target project's AGENTS.md
TRACKER_TOOL=""
TRACKER_URL=""
TRACKER_INTEGRATION=""
AGENTS_FILE="$TARGET/AGENTS.md"

if [[ -f "$AGENTS_FILE" ]]; then
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
fi

if [[ -n "$TRACKER_TOOL" ]]; then
  echo "  INFO Tracker detected: $TRACKER_TOOL"
  [[ -n "$TRACKER_URL" ]] && echo "       Task URL pattern: $TRACKER_URL"
  [[ -n "$TRACKER_INTEGRATION" ]] && echo "       Integration: $TRACKER_INTEGRATION"
else
  echo "  WARN No tracker detected in AGENTS.md ## Project Tracker"
  ACTION_ITEMS+=("Add ## Project Tracker to AGENTS.md and re-run install.sh to auto-fill tracker block in skills")
fi

ensure_dir "$TARGET/.claude/commands"

SRC_SKILLS="$SRC_FW/templates/skills"
_SKILL_TMP="$(mktemp /tmp/harnessable_skill.XXXXXX)"
trap 'rm -f "$_SKILL_TMP"' EXIT

for f in "$SRC_SKILLS/"*.md; do
  [[ -f "$f" ]] || continue
  name="$(basename "$f")"
  DST_SKILL="$TARGET/.claude/commands/$name"

  # Compute expected (processed) content: apply tracker block + base-path removal
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

  if [[ ! -f "$DST_SKILL" ]]; then
    ensure_dir "$(dirname "$DST_SKILL")"
    cp "$_SKILL_TMP" "$DST_SKILL"
    echo "  NEW  .claude/commands/$name"
    SK_NEW=$((SK_NEW + 1))
    LAST_STATUS="new"
  elif diff -q "$_SKILL_TMP" "$DST_SKILL" &>/dev/null; then
    echo "  OK   .claude/commands/$name"
    SK_OK=$((SK_OK + 1))
    LAST_STATUS="ok"
  elif grep -q "# REPLACE:" "$DST_SKILL" 2>/dev/null; then
    # Destination still has REPLACE markers — not yet customised; update it
    cp "$_SKILL_TMP" "$DST_SKILL"
    echo "  UPD  .claude/commands/$name (uncustomised)"
    SK_NEW=$((SK_NEW + 1))
    LAST_STATUS="upd"
  else
    # No REPLACE markers but content differs — user has customised
    DIFF_LINES="$(diff "$_SKILL_TMP" "$DST_SKILL" 2>/dev/null | wc -l | tr -d '[:space:]')"
    echo "  SKIP .claude/commands/$name ($DIFF_LINES diff lines — customised)"
    SK_MERGE=$((SK_MERGE + 1))
    MERGE_FILES+=(".claude/commands/$name")
    LAST_STATUS="skip"
  fi

  # Count remaining REPLACE markers
  if [[ -f "$DST_SKILL" ]]; then
    REMAINING="$(grep -c "# REPLACE:" "$DST_SKILL" 2>/dev/null || echo 0)"
    if [[ "$REMAINING" -gt 0 ]]; then
      REPLACE_COUNT=$((REPLACE_COUNT + REMAINING))
      REPLACE_FILES+=(".claude/commands/$name ($REMAINING marker(s))")
    fi
  fi
done

rm -f "$_SKILL_TMP"
trap - EXIT

echo ""

# ── .claude/settings.json ─────────────────────────────────────────────────────

echo "── Config: .claude/settings.json ────────────────────────────────────────"

SETTINGS_FILE="$TARGET/.claude/settings.json"
ensure_dir "$TARGET/.claude"

HAS_PRECOMPACT="false"
if [[ -d "$SRC_FW/hooks/pre_compact" ]]; then
  if find "$SRC_FW/hooks/pre_compact" -name "*.py" | grep -q .; then
    HAS_PRECOMPACT="true"
  fi
fi

SETTINGS_RESULT="$(python3 - "$SETTINGS_FILE" "$HAS_PRECOMPACT" <<'PYEOF'
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

# Validate write
json.loads(open(settings_path).read())
print('NEW' if changed else 'OK')
PYEOF
)"

echo "  $SETTINGS_RESULT  .claude/settings.json"
CFG_SETTINGS="$SETTINGS_RESULT"

echo ""

# ── .gitignore ────────────────────────────────────────────────────────────────

echo "── Config: .gitignore ───────────────────────────────────────────────────"

GITIGNORE_FILE="$TARGET/.gitignore"
GITIGNORE_STATUS=""

if [[ ! -f "$GITIGNORE_FILE" ]]; then
  # Absent — create with required entry
  {
    echo "# harnessable runtime output"
    echo ".harnessable/"
  } > "$GITIGNORE_FILE"
  echo "  NEW  .gitignore (created with .harnessable/ entry)"
  GITIGNORE_STATUS="NEW"
elif grep -qxF ".harnessable/" "$GITIGNORE_FILE" 2>/dev/null; then
  # Directory-level entry already correct
  echo "  OK   .gitignore (.harnessable/ entry present)"
  GITIGNORE_STATUS="OK"
elif grep -qxF ".harnessable/*" "$GITIGNORE_FILE" 2>/dev/null; then
  # Glob entry present — replace with directory-level entry
  python3 - "$GITIGNORE_FILE" <<'PYEOF'
import sys
path = sys.argv[1]
lines = open(path).readlines()
out = []
for line in lines:
    if line.rstrip('\n') == '.harnessable/*':
        out.append('.harnessable/\n')
    else:
        out.append(line)
open(path, 'w').writelines(out)
PYEOF
  echo "  UPD  .gitignore (replaced .harnessable/* glob with .harnessable/ directory entry)"
  GITIGNORE_STATUS="UPD"
else
  # No entry at all — append
  echo "" >> "$GITIGNORE_FILE"
  echo "# harnessable runtime output" >> "$GITIGNORE_FILE"
  echo ".harnessable/" >> "$GITIGNORE_FILE"
  echo "  UPD  .gitignore (appended .harnessable/ entry)"
  GITIGNORE_STATUS="UPD"
fi

# Verify with git check-ignore
if git -C "$TARGET" check-ignore -q ".harnessable/test" 2>/dev/null; then
  echo "  OK   git check-ignore verified: .harnessable/ is ignored"
else
  echo "  WARN git check-ignore did not confirm .harnessable/ — check .gitignore manually"
  ACTION_ITEMS+=("Verify .harnessable/ is properly ignored by git in $TARGET")
fi

CFG_GITIGNORE="$GITIGNORE_STATUS"
echo ""

# ── .harnessable/config.json ──────────────────────────────────────────────────

echo "── Config: .harnessable/config.json ─────────────────────────────────────"

CONFIG_FILE="$TARGET/.harnessable/config.json"
ensure_dir "$TARGET/.harnessable"

CONFIG_RESULT="$(python3 - "$CONFIG_FILE" <<'PYEOF'
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

# Ensure audit block
audit = config.setdefault('audit', {})
defaults = {'log_dir': '.harnessable/logs', 'max_field_bytes': 512, 'rotate': True}
for key, val in defaults.items():
    if key not in audit:
        audit[key] = val
        changed = True

# Ensure codebases list
if 'codebases' not in config:
    config['codebases'] = []
    changed = True

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

json.loads(open(config_path).read())
print('NEW' if changed else 'OK')
PYEOF
)"

echo "  $CONFIG_RESULT  .harnessable/config.json"
CFG_CONFIG="$CONFIG_RESULT"
echo ""

# ── Final report ──────────────────────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Summary"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
printf "  %-22s %d installed / %d current\n" "Tier 2 (vendor):" "$T2_NEW" "$T2_OK"
printf "  %-22s %d installed / %d current / %d skipped\n" "Tier 1 (scaffold):" "$T1_NEW" "$T1_OK" "$T1_SKIP"
printf "  %-22s %d installed / %d current / %d manual merge\n" "Skills:" "$SK_NEW" "$SK_OK" "$SK_MERGE"
printf "  %-22s settings.json=%s  .gitignore=%s  config.json=%s\n" \
  "Config:" "$CFG_SETTINGS" "$CFG_GITIGNORE" "$CFG_CONFIG"
printf "  %-22s %d remaining" "REPLACE markers:" "$REPLACE_COUNT"
if [[ ${#REPLACE_FILES[@]} -gt 0 ]]; then
  echo ""
  for f in "${REPLACE_FILES[@]}"; do
    echo "    • $f"
  done
else
  echo " (none)"
fi
echo ""

# ACTION items
if [[ ${#ACTION_ITEMS[@]} -gt 0 || ${#REPLACE_FILES[@]} -gt 0 || ${#MERGE_FILES[@]} -gt 0 ]]; then
  echo "  ACTION items requiring operator follow-up:"
  echo ""
  for item in "${ACTION_ITEMS[@]}"; do
    echo "  ACTION  $item"
  done
  for f in "${REPLACE_FILES[@]}"; do
    echo "  ACTION  Edit remaining REPLACE markers in $f"
  done
  for f in "${MERGE_FILES[@]}"; do
    echo "  ACTION  MANUAL_MERGE_REQUIRED: $f (customised — diff and merge upstream changes)"
  done
  echo ""
fi

echo "  Next steps:"
echo ""
echo "  1. Review changes:"
echo "       git -C $TARGET status"
echo ""
echo "  2. Customise any flagged REPLACE markers in .claude/commands/*.md"
echo ""
echo "  3. Commit:"
echo "       git -C $TARGET add -A"
echo "       git -C $TARGET commit -m \"chore: install harnessable $FRAMEWORK_VERSION\""
echo ""
echo "  4. Seed the project knowledge graph:"
echo "       cp $TARGET/docs/harness/templates/knowledge-graph.yaml \\"
echo "          $TARGET/docs/knowledge-graph.yaml"
echo "       # Then fill in REPLACE_WITH_YOUR_PROJECT_NAME"
echo "       # and REPLACE_WITH_CONTENTS_OF_HARNESSABLE_VERSION_FILE"
echo ""
echo "  5. For Codex, install the adapter as well:"
echo "       bash $FRAMEWORK_ROOT/codex/install.sh $TARGET"
echo ""
