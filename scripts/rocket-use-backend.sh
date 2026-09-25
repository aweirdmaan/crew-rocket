#!/usr/bin/env bash
# rocket-use-backend.sh <member>
#
# KiroCrew 0.7.1's config is NOT per-named-crew-member: `kirocrew config get`
# exposes exactly two backend knobs, both global -
#   agent.acp_backend         - the backend THIS session runs on
#   agent.member_acp_backend  - the backend a session delegates
#                                spawned/subagent work to
# (confirmed against a real install - `kirocrew config set member_acp_backend
# ...`, without the `agent.` prefix, fails with "Unknown key"). So true
# per-role pinning means switching `agent.acp_backend` before you start that
# role's session, not three roles coexisting simultaneously under one
# config. This script is that switch, reading the intended backend for a
# role straight out of .kiro/crew/crew.yaml instead of you looking it up.
#
# Usage: scripts/rocket-use-backend.sh meowth   # before invoking rocket-plan
#        scripts/rocket-use-backend.sh james    # before invoking rocket-implement
set -uo pipefail

member="${1:-}"
crew_yaml=".kiro/crew/crew.yaml"

if [ -z "$member" ]; then
  echo "usage: rocket-use-backend.sh <meowth|jessie|james>" >&2
  exit 2
fi

if [ ! -f "$crew_yaml" ]; then
  echo "no $crew_yaml in this directory - run this from the project setup.sh copied into." >&2
  exit 1
fi

backend=$(awk -v m="$member:" '
  $0 ~ "^  *"m {found=1}
  found && /backend:/ {print $2; exit}
' "$crew_yaml")

if [ -z "$backend" ]; then
  echo "could not find a backend: line under '$member:' in $crew_yaml" >&2
  exit 1
fi

if ! command -v kirocrew >/dev/null 2>&1; then
  echo "kirocrew not on PATH - intended backend for $member is '$backend'; apply it yourself." >&2
  exit 1
fi

echo "+ kirocrew config set agent.acp_backend $backend   ($member)"
kirocrew config set agent.acp_backend "$backend"
