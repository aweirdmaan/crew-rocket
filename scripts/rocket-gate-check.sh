#!/usr/bin/env bash
# rocket-gate-check.sh <epic-id> <expected-prefix>
#
# Replaces Archon's bash gate nodes (which read a verdict file written by a
# fresh-context AI node) with a durable, backend-agnostic equivalent: the
# verdict lives as the LAST beads comment on the epic, not in a run-scoped
# artifacts directory that dies with the session.
#
# A skill that gates on human approval or a prior skill's verdict must run
# this script and stop cold if it exits non-zero. It never guesses "probably
# fine" - missing or malformed input fails closed.
#
# Convention: the gating skill's last action is
#   bd comment <epic-id> "GATE: PASS <one-line reason>"
# or
#   bd comment <epic-id> "GATE: FAIL <what is missing>"
#
# Usage:
#   rocket-gate-check.sh <epic-id> GATE:\ PASS
set -uo pipefail

epic="${1:-}"
want="${2:-}"

if [ -z "$epic" ] || [ -z "$want" ]; then
  echo "usage: rocket-gate-check.sh <epic-id> <expected-prefix>" >&2
  exit 2
fi

if [ -f .kiro/crew/beads-dir ]; then
  export BEADS_DIR
  BEADS_DIR=$(cat .kiro/crew/beads-dir)
fi

if ! command -v bd >/dev/null 2>&1; then
  echo "GATE FAIL: bd (beads) not on PATH - setup failure, not a missing approval" >&2
  exit 1
fi

last=$(bd comments "$epic" 2>/dev/null | grep '^GATE:' | tail -1)

if [ -z "$last" ]; then
  echo "GATE FAIL: no GATE: comment found on $epic" >&2
  exit 1
fi

case "$last" in
  "$want"*)
    echo "GATE PASS: $last"
    exit 0
    ;;
  *)
    echo "GATE FAIL: $last" >&2
    exit 1
    ;;
esac
