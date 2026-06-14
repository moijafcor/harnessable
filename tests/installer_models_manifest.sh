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
if len(roles) != 17:
    raise SystemExit(f"expected 17 roles, got {len(roles)}")
if "dreamer" not in roles:
    raise SystemExit("dreamer role missing")
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

assert_per_support() {
  local target="$1"
  [[ -d "$target/docs/mandates/per" ]] || fail "docs/mandates/per missing"
  [[ -f "$target/docs/mandates/per/.gitkeep" ]] || fail "docs/mandates/per/.gitkeep missing"
  [[ -f "$target/docs/harness/templates/per.md" ]] || fail "PER template missing"
  grep -q "## Gap description" "$target/docs/harness/templates/per.md" || fail "PER template missing gap section"
  grep -q "## Roster at time of filing" "$target/docs/harness/templates/per.md" || fail "PER template missing roster section"
}

assert_evolution_support() {
  local target="$1"
  [[ -d "$target/docs/evolutions" ]] || fail "docs/evolutions missing"
  [[ -f "$target/docs/evolutions/.gitkeep" ]] || fail "docs/evolutions/.gitkeep missing"
  [[ -f "$target/docs/harness/templates/er.md" ]] || fail "ER template missing"
  grep -q "## Roster diff" "$target/docs/harness/templates/er.md" || fail "ER template missing roster diff"
  grep -q "## PER resolutions" "$target/docs/harness/templates/er.md" || fail "ER template missing PER resolutions"
}

assert_dream_support() {
  local target="$1"
  [[ -d "$target/docs/dreams" ]] || fail "docs/dreams missing"
  [[ -f "$target/docs/dreams/.gitkeep" ]] || fail "docs/dreams/.gitkeep missing"
}

assert_package_support() {
  local target="$1"
  [[ -d "$target/packages" ]] || fail "packages directory missing"
  [[ -f "$target/packages/README.md" ]] || fail "packages/README.md missing"
  [[ -f "$target/docs/harness/templates/package.md" ]] || fail "package template missing"
  grep -q "Harnessable package adapter manifest" "$target/docs/harness/templates/package.md" || fail "package template missing manifest heading"
  grep -q "REPLACE" "$target/docs/harness/templates/package.md" || fail "package template missing REPLACE markers"
}

assert_hallmark_adapter() {
  local target="$1"
  [[ -f "$target/packages/hallmark/PACKAGE.md" ]] || fail "hallmark PACKAGE.md missing"
  [[ -f "$target/packages/hallmark/README.md" ]] || fail "hallmark README missing"
  [[ -f "$target/packages/hallmark/skills/hallmark.md" ]] || fail "hallmark skill missing"
  [[ -f "$target/packages/hallmark/skills/hallmark_study.md" ]] || fail "hallmark study skill missing"
  [[ -f "$target/packages/hallmark/adapter/designer_ext.md" ]] || fail "hallmark designer extension missing"
  [[ -f "$target/packages/hallmark/adapter/rubric.md" ]] || fail "hallmark rubric missing"
  [[ -f "$target/packages/hallmark/adapter/design_world_model.md" ]] || fail "hallmark design world model missing"
  ! grep -R "claude/skills/hallmark" "$target/packages/hallmark" >/dev/null || fail "hallmark adapter contains old claude skill path"
  ! grep -R "docs/harness/packages" "$target/packages/hallmark" >/dev/null || fail "hallmark adapter contains unsynced docs/harness/packages path"
  grep -R "agents/skills/hallmark" "$target/packages/hallmark" >/dev/null || fail "hallmark adapter missing agents skill path"
  [[ "$(grep -c -- "- \\[ \\]" "$target/packages/hallmark/adapter/rubric.md")" -eq 65 ]] || fail "hallmark rubric gate count is not 65"
}

target="$(new_target)"
bash "$ROOT/install.sh" "$target" > "$TMP_ROOT/full.out"
assert_models_manifest "$target"
assert_world_model "$target"
assert_per_support "$target"
assert_dream_support "$target"
assert_evolution_support "$target"
assert_package_support "$target"
assert_hallmark_adapter "$target"
assert_version_file "$target/docs/harness/vendor/harnessable/HARNESSABLE_VERSION"
[[ ! -f "$target/docs/harness/templates/models.yaml" ]] || fail "models.yaml copied under templates"
grep -q "SYNCED  docs/harness/models.yaml  (NEW)" "$TMP_ROOT/full.out" || fail "full installer did not report models manifest sync"
grep -q "CREATED docs/dreams/" "$TMP_ROOT/full.out" || fail "full installer did not report dreams directory seed"
grep -q "CREATED packages/" "$TMP_ROOT/full.out" || fail "full installer did not report packages bootstrap"
grep -q "SYNCED  packages/hallmark/PACKAGE.md  (NEW)" "$TMP_ROOT/full.out" || fail "full installer did not report hallmark package sync"
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
assert_per_support "$target"
assert_dream_support "$target"
assert_evolution_support "$target"
assert_package_support "$target"
assert_hallmark_adapter "$target"
assert_version_file "$target/.agents/skills/harnessable/HARNESSABLE_VERSION"
grep -q "SYNCED  docs/harness/models.yaml  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report models manifest sync"
grep -q "SYNCED  WORLD_MODEL.md  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report world model sync"
grep -q "CREATED world_models/fleet_world_model.md" "$TMP_ROOT/codex.out" || fail "codex installer did not report fleet world model seed"
grep -q "CREATED world_models/vendor_world_model.md" "$TMP_ROOT/codex.out" || fail "codex installer did not report vendor world model seed"
grep -q "CREATED world_models/staging_world_model.md" "$TMP_ROOT/codex.out" || fail "codex installer did not report staging world model seed"
grep -q "CREATED docs/mandates/per/" "$TMP_ROOT/codex.out" || fail "codex installer did not report PER directory seed"
grep -q "SYNCED  docs/harness/templates/per.md  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report PER template sync"
grep -q "CREATED docs/dreams/" "$TMP_ROOT/codex.out" || fail "codex installer did not report dreams directory seed"
grep -q "CREATED docs/evolutions/" "$TMP_ROOT/codex.out" || fail "codex installer did not report evolutions directory seed"
grep -q "SYNCED  docs/harness/templates/er.md  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report ER template sync"
grep -q "CREATED packages/" "$TMP_ROOT/codex.out" || fail "codex installer did not report packages bootstrap"
grep -q "SYNCED  docs/harness/templates/package.md  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report package template sync"
grep -q "SYNCED  packages/hallmark/PACKAGE.md  (NEW)" "$TMP_ROOT/codex.out" || fail "codex installer did not report hallmark package sync"
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
