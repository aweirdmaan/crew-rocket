#!/usr/bin/env bash
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
