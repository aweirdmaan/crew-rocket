#!/usr/bin/env bash
set -uo pipefail

PORT="${KIROCREW_PORT:-5476}"
BASE="http://localhost:$PORT"

usage() {
  cat <<'EOF'
Usage: rocket-watch.sh <task_id-or-name>

Streams live Task Runner progress over GET /api/taskrunner/{task_id}/stream -
a real Server-Sent Events push, not a poll. Requires a KiroCrew build that
carries this endpoint (kirodotdev/KiroCrew PR from aweirdmaan/KiroCrew's
fix/claude-backend-and-devpass branch; mainline does not have it yet).

Prints one line per frame: a run status change, a step status change, or a
step's result/error text once it finishes. Ctrl-C to stop; the stream also
ends on its own once the run reaches a terminal state.
EOF
}

case "${1:-}" in
  -h|--help|"") usage; exit "$([ "${1:-}" = "" ] && echo 2 || echo 0)" ;;
esac
REF="$1"

token() {
  kirocrew token 2>/dev/null | sed -n 's/.*token=//p'
}

TOKEN="$(token)"
if [ -z "$TOKEN" ]; then
  echo "could not get a dashboard token - is 'kirocrew gateway' running?" >&2
  exit 1
fi

curl -sN --fail-with-body "$BASE/api/taskrunner/$REF/stream?token=$TOKEN" \
  | sed -u -n 's/^data: //p' \
  | python3 -u -c '
import json
import sys

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except json.JSONDecodeError:
        print(line)
        continue
    kind = ev.get("type")
    if kind == "run":
        status = ev.get("status")
        completed = ev.get("completed", 0)
        tasks = ev.get("tasks", 0)
        print(f"RUN {status} ({completed}/{tasks})")
    elif kind == "step":
        index = ev.get("index")
        title = ev.get("title")
        status = ev.get("status")
        print(f"  [{index}] {title}: {status}")
    elif kind == "result":
        for row in (ev.get("text") or "").splitlines():
            print(f"      {row}")
    elif kind == "ended":
        reason = ev.get("reason", "")
        status = ev.get("status", "")
        print(f"ENDED: {reason} ({status})")
    else:
        print(ev)
'
