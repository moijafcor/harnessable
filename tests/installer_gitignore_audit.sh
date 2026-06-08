#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

target="$(mktemp -d "$TMP_ROOT/project.XXXXXX")"
git -C "$target" init >/dev/null
git -C "$target" config user.email test@example.com
git -C "$target" config user.name "Test User"
{
  echo "AGENTS.md"
  echo "docs/"
} > "$target/.gitignore"
git -C "$target" add .gitignore
git -C "$target" commit -m init >/dev/null

bash "$ROOT/install.sh" "$target" > "$TMP_ROOT/install.out"

grep -q "Git ignore audit" "$TMP_ROOT/install.out" || fail "audit section missing"
grep -q "installed path is ignored by git: AGENTS.md" "$TMP_ROOT/install.out" || fail "AGENTS.md warning missing"
grep -q "installed path is ignored by git: docs/harness" "$TMP_ROOT/install.out" || fail "docs/harness warning missing"
grep -q "Review .gitignore: installed harnessable path ignored: AGENTS.md" "$TMP_ROOT/install.out" || fail "AGENTS.md action item missing"
grep -q "git -C $target add -f AGENTS.md" "$TMP_ROOT/install.out" || fail "force-add remediation missing"

echo "installer_gitignore_audit: OK"
