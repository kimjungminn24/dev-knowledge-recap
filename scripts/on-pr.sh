#!/usr/bin/env bash
# Runs after Claude creates a pull request. If a PR URL shows up in the tool
# result, it tells Claude to run the recap skill for that PR.
# Turn it off with `auto: false` in .dev-knowledge-recap.yml or
# DEV_KNOWLEDGE_RECAP_AUTO=off in the environment.

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

# No URL means the PR was not created (or the command failed), so do nothing.
url=$(printf '%s' "$input" | grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' | head -n 1)
[ -z "$url" ] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"A pull request was just created: %s. Before you reply to the user, run the /dev-knowledge-recap:recap skill with --auto --pr %s."}}\n' "$url" "$url"
