#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_stub_gh() {
  local bin_dir="$TMP_ROOT/bin"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/gh" <<'GHEOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  exit 0
fi

if [[ "${1:-}" == "api" && "${2:-}" == "user" ]]; then
  echo "moijafcor"
  exit 0
fi

if [[ "${1:-}" == "api" && "${2:-}" == "graphql" ]]; then
  input_file=""
  args="$*"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input)
        input_file="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  if printf '%s\n' "$args" | grep -q "updateProjectV2Field" \
    || { [[ -n "$input_file" && -f "$input_file" ]] && grep -q "updateProjectV2Field" "$input_file"; }; then
    echo "updateProjectV2Field" >> "${GH_STUB_LOG:?}"
  fi
  echo '{"data":{"user":{"projectV2":{"id":"PVT_user"}},"organization":{"projectV2":{"id":"PVT_org"}},"addProjectV2Field":{"projectV2Field":{"id":"FIELD"}}}}'
  exit 0
fi

if [[ "${1:-}" == "project" && "${2:-}" == "view" ]]; then
  number="$3"
  owner=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --owner)
        owner="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  if [[ "$number" == "403" ]]; then
    echo "HTTP 403: your token has not been granted the required scopes [project]" >&2
    exit 1
  fi

  if [[ "$owner" == "Cisery-Inc" ]]; then
    echo "{\"number\":$number,\"title\":\"Cisery board\",\"url\":\"https://github.com/orgs/Cisery-Inc/projects/$number\"}"
  else
    echo "{\"number\":$number,\"title\":\"User board\",\"url\":\"https://github.com/users/$owner/projects/$number\"}"
  fi
  exit 0
fi

if [[ "${1:-}" == "project" && "${2:-}" == "field-list" ]]; then
  echo '{"fields":[{"id":"FIELD_STATUS","name":"Status","options":[{"name":"Todo"},{"name":"In Progress"},{"name":"Done"}]}]}'
  exit 0
fi

if [[ "${1:-}" == "project" && "${2:-}" == "create" ]]; then
  echo '{"number":99,"url":"https://github.com/users/moijafcor/projects/99"}'
  exit 0
fi

echo "unexpected gh invocation: $*" >&2
exit 1
GHEOF
  chmod +x "$bin_dir/gh"
  echo "$bin_dir"
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

run_install() {
  local target="$1"
  shift
  PATH="$STUB_BIN:$PATH" bash "$ROOT/install.sh" "$@" "$target"
}

assert_agents() {
  local target="$1" owner="$2" owner_type="$3" project="$4"
  grep -q "^owner:[[:space:]]*$owner$" "$target/AGENTS.md" || fail "owner $owner not written"
  grep -q "^owner_type:[[:space:]]*$owner_type$" "$target/AGENTS.md" || fail "owner_type $owner_type not written"
  grep -q "^project:[[:space:]]*$project$" "$target/AGENTS.md" || fail "project $project not written"
}

STUB_BIN="$(make_stub_gh)"
GH_STUB_LOG="$TMP_ROOT/gh.log"
export GH_STUB_LOG

target="$(new_target)"
run_install "$target" --github-board=4 --owner=Cisery-Inc >"$TMP_ROOT/numeric.out"
assert_agents "$target" "Cisery-Inc" "org" "4"
grep -q "Status field configured: 10 prescribed options" "$TMP_ROOT/numeric.out" || fail "status replacement was not reported"

target="$(new_target)"
run_install "$target" --github-board=https://github.com/orgs/Cisery-Inc/projects/4/views/1 >/dev/null
assert_agents "$target" "Cisery-Inc" "org" "4"

target="$(new_target)"
run_install "$target" --github-board=https://github.com/users/moijafcor/projects/2 >/dev/null
assert_agents "$target" "moijafcor" "user" "2"

target="$(new_target)"
if run_install "$target" --github-board=https://github.com/orgs/Cisery-Inc/projects/not-a-number >"$TMP_ROOT/bad.out" 2>&1; then
  fail "malformed URL unexpectedly succeeded"
fi
grep -q "Malformed GitHub Projects URL" "$TMP_ROOT/bad.out" || fail "malformed URL error was not clear"

target="$(new_target)"
if run_install "$target" --github-board=403 --owner=Cisery-Inc >"$TMP_ROOT/scope.out" 2>&1; then
  fail "gh project view failure unexpectedly succeeded"
fi
grep -q "gh project view error:" "$TMP_ROOT/scope.out" || fail "gh stderr heading missing"
grep -q "required scopes \\[project\\]" "$TMP_ROOT/scope.out" || fail "gh missing-scope stderr was not shown"
grep -q "gh auth refresh -s project" "$TMP_ROOT/scope.out" || fail "scope refresh command missing"

updates="$(grep -c "updateProjectV2Field" "$GH_STUB_LOG")"
[[ "$updates" -ge 3 ]] || fail "Status field replacement mutation was not called for successful board links"

echo "installer_github_board: OK"
