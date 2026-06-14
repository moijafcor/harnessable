#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
EXPECTED_VERSION="$(git -C "$ROOT" rev-parse --short HEAD)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

new_target() {
  local target
  target="$(mktemp -d "$TMP_ROOT/project.XXXXXX")"
  git -C "$target" init >/dev/null
  git -C "$target" config user.email test@example.com
  git -C "$target" config user.name "Test User"
  git -C "$target" commit --allow-empty -m init >/dev/null
  echo "$target"
}

assert_models_manifest() {
  local target="$1"
  [[ -f "$target/docs/harness/models.yaml" ]] || fail "docs/harness/models.yaml missing"
  grep -q '^roles:' "$target/docs/harness/models.yaml" || fail "models manifest missing roles root"
  python3 - "$target/docs/harness/models.yaml" <<'PYEOF' || fail "models manifest role count invalid"
import sys
import yaml

with open(sys.argv[1], encoding="utf-8") as fh:
    data = yaml.safe_load(fh)
roles = data.get("roles", {})
if len(roles) != 15:
    raise SystemExit(f"expected 15 roles, got {len(roles)}")
for name, role in roles.items():
    cost = role.get("cost_per_1k_tokens")
    if not isinstance(cost, dict):
        raise SystemExit(f"{name} missing cost_per_1k_tokens")
    if "input" not in cost or "output" not in cost:
        raise SystemExit(f"{name} missing input/output token costs")
PYEOF
}

assert_world_model() {
  local target="$1"
  [[ -f "$target/WORLD_MODEL.md" ]] || fail "WORLD_MODEL.md missing"
  [[ -d "$target/world_models" ]] || fail "world_models directory missing"
  [[ -f "$target/world_models/fleet_world_model.md" ]] || fail "fleet world model missing"
  [[ -f "$target/world_models/vendor_world_model.md" ]] || fail "vendor world model missing"
  [[ -f "$target/world_models/staging_world_model.md" ]] || fail "staging world model missing"
  [[ -f "$target/world_models/.gitkeep" ]] || fail "world_models/.gitkeep missing"
  [[ -d "$target/docs/incidents" ]] || fail "docs/incidents missing"
  [[ -f "$target/docs/incidents/.gitkeep" ]] || fail "docs/incidents/.gitkeep missing"
  grep -q "Discovery index" "$target/WORLD_MODEL.md" || fail "WORLD_MODEL.md is not a thin discovery index"
  grep -q "world_models/fleet_world_model.md" "$target/WORLD_MODEL.md" || fail "WORLD_MODEL.md missing fleet model pointer"
  grep -q "SECURITY NOTICE" "$target/WORLD_MODEL.md" || fail "WORLD_MODEL.md missing security notice"
  grep -q "SECURITY NOTICE" "$target/world_models/fleet_world_model.md" || fail "fleet world model missing security notice"
  grep -q "SECURITY NOTICE" "$target/world_models/vendor_world_model.md" || fail "vendor world model missing security notice"
  grep -q "SECURITY NOTICE" "$target/world_models/staging_world_model.md" || fail "staging world model missing security notice"
}

assert_version_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "version file missing: $path"
  [[ "$(cat "$path")" == "$EXPECTED_VERSION" ]] || \
    fail "version file $path did not contain $EXPECTED_VERSION"
}

target="$(new_target)"
bash "$ROOT/install.sh" "$target" > "$TMP_ROOT/full.out"
assert_models_manifest "$target"
assert_world_model "$target"
assert_version_file "$target/docs/harness/vendor/harnessable/HARNESSABLE_VERSION"
[[ ! -f "$target/docs/harness/templates/models.yaml" ]] || fail "models.yaml copied under templates"
grep -q "SYNCED  docs/harness/models.yaml  (NEW)" "$TMP_ROOT/full.out" || fail "full installer did not report models manifest sync"
grep -q "HARNESSABLE_VERSION → $EXPECTED_VERSION" "$TMP_ROOT/full.out" || fail "full installer did not report resolved version"

echo "# project-selected models" >> "$target/docs/harness/models.yaml"
echo "# project-owned world" >> "$target/WORLD_MODEL.md"
echo "# project-owned fleet world" >> "$target/world_models/fleet_world_model.md"
git -C "$target" add -A
git -C "$target" commit -m "customize models" >/dev/null
bash "$ROOT/install.sh" --update "$target" > "$TMP_ROOT/full-update.out"
grep -q "MERGE   docs/harness/models.yaml" "$TMP_ROOT/full-update.out" || fail "full installer did not protect customized models manifest"
grep -q "# project-selected models" "$target/docs/harness/models.yaml" || fail "full installer overwrote customized models manifest"
grep -q "# project-owned world" "$target/WORLD_MODEL.md" || fail "full installer overwrote WORLD_MODEL.md"
grep -q "# project-owned fleet world" "$target/world_models/fleet_world_model.md" || fail "full installer overwrote fleet world model"

target="$(new_target)"
bash "$ROOT/codex/install.sh" "$target" > "$TMP_ROOT/codex.out"
assert_models_manifest "$target"
assert_world_model "$target"
assert_version_file "$target/.agents/skills/harnessable/HARNESSABLE_VERSION"
grep -q "SYNCED  docs/harness/models.yaml  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report models manifest sync"
grep -q "SYNCED  WORLD_MODEL.md  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report world model sync"
grep -q "CREATED world_models/fleet_world_model.md" "$TMP_ROOT/codex.out" || fail "codex installer did not report fleet world model seed"
grep -q "CREATED world_models/vendor_world_model.md" "$TMP_ROOT/codex.out" || fail "codex installer did not report vendor world model seed"
grep -q "CREATED world_models/staging_world_model.md" "$TMP_ROOT/codex.out" || fail "codex installer did not report staging world model seed"
grep -q "harnessable Codex adapter $EXPECTED_VERSION" "$TMP_ROOT/codex.out" || fail "codex installer did not report resolved version"

echo "# codex project-selected models" >> "$target/docs/harness/models.yaml"
echo "# codex project-owned world" >> "$target/WORLD_MODEL.md"
echo "# codex project-owned fleet world" >> "$target/world_models/fleet_world_model.md"
git -C "$target" add -A
git -C "$target" commit -m "customize codex models" >/dev/null
bash "$ROOT/codex/install.sh" --update "$target" > "$TMP_ROOT/codex-update.out"
grep -q "MERGE   docs/harness/models.yaml" "$TMP_ROOT/codex-update.out" || fail "codex installer did not protect customized models manifest"
grep -q "# codex project-selected models" "$target/docs/harness/models.yaml" || fail "codex installer overwrote customized models manifest"
grep -q "# codex project-owned world" "$target/WORLD_MODEL.md" || fail "codex installer overwrote WORLD_MODEL.md"
grep -q "# codex project-owned fleet world" "$target/world_models/fleet_world_model.md" || fail "codex installer overwrote fleet world model"

echo "installer_models_manifest: OK"
