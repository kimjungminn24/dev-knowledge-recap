#!/usr/bin/env bash
# Checks scripts/on-pr.sh against sample hook inputs.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
hook="$here/scripts/on-pr.sh"
export TMPDIR=$(mktemp -d)
fail=0

check() { # name, expected (fire|skip), input, [env]
  local out
  out=$(printf '%s' "$3" | env ${4:-} "$hook")
  if { [ "$2" = fire ] && [ -n "$out" ]; } || { [ "$2" = skip ] && [ -z "$out" ]; }; then
    echo "ok   $1"
  else
    echo "FAIL $1"; fail=1
  fi
}

pr='{"tool_input":{"command":"gh pr create --fill"},"tool_response":{"stdout":"https://github.com/a/b/pull/12"}}'
check "gh pr create"        fire "$pr"
check "same PR again"       skip "$pr"
check "MCP tool"            fire '{"tool_name":"mcp__github__create_pull_request","tool_response":"{\"html_url\":\"https://github.com/a/b/pull/7\"}"}'
check "GitHub Enterprise"   fire '{"tool_input":{"command":"gh pr create"},"tool_response":"https://git.corp.example/a/b/pull/3"}'
check "create failed"       skip '{"tool_input":{"command":"gh pr create"},"tool_response":{"stderr":"no commits"}}'
check "other command"       skip '{"tool_input":{"command":"ls"},"tool_response":"https://github.com/a/b/pull/9"}'
check "turned off by env"   skip '{"tool_input":{"command":"gh pr create"},"tool_response":"https://github.com/a/b/pull/20"}' DEV_KNOWLEDGE_RECAP_AUTO=off

rm -rf "$TMPDIR"
exit $fail
