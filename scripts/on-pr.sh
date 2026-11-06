#!/usr/bin/env bash
# Runs after Claude creates a pull request. If a PR URL shows up in the tool
# result, it tells Claude to run the recap skill for that PR.
# Turn it off with `auto: false` in .dev-knowledge-recap.yml or
# DEV_KNOWLEDGE_RECAP_AUTO=off in the environment.

set -uo pipefail

input=$(cat)

case "${DEV_KNOWLEDGE_RECAP_AUTO:-on}" in
  off|false|0|no) exit 0 ;;
esac

# Only react to PR creation. The `if` filter in hooks.json is best effort.
case "$input" in
  *"gh pr create"*|*"create_pull_request"*) ;;
  *) exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ -f "$root/.dev-knowledge-recap.yml" ] &&
   grep -Eq '^[[:space:]]*auto:[[:space:]]*(false|off|no)' "$root/.dev-knowledge-recap.yml"; then
  exit 0
fi

# No URL means the PR was not created, so do nothing.
# Any host is accepted so GitHub Enterprise URLs work too.
url=$(printf '%s' "$input" | grep -oE 'https://[A-Za-z0-9.-]+/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' | head -n 1 || true)
[ -z "$url" ] && exit 0

# Fire once per PR. Claude sometimes retries or uses both gh and the MCP tool,
# and a second nudge would write the same notes twice.
seen_dir="${TMPDIR:-/tmp}/dev-knowledge-recap"
seen="$seen_dir/$(printf '%s' "$url" | tr -c 'A-Za-z0-9' '_')"
mkdir -p "$seen_dir" 2>/dev/null || true
if ! (set -o noclobber; : > "$seen") 2>/dev/null; then
  exit 0
fi

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"A pull request was just created: %s. Before you reply to the user, run the /dev-knowledge-recap:recap skill with --auto --pr %s."}}\n' "$url" "$url"
