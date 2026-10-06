#!/usr/bin/env bash
set -uo pipefail

PORT="${KIROCREW_PORT:-5476}"
BASE="http://localhost:$PORT"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOWS_DIR="$PROJECT_DIR/.kiro/workflows"
SPEC_DIR="$(mktemp -d)"
trap 'rm -rf "$SPEC_DIR"' EXIT

log()  { printf '%s\n' "$*"; }
step() { printf '\n== %s ==\n' "$*"; }

token() {
  kirocrew token 2>/dev/null | sed -n 's/.*token=//p'
}

api() {
  local method="$1" path="$2" body="${3:-}"
  local tok; tok="$(token)"
  if [ -z "$tok" ]; then
    echo "could not get a dashboard token - is 'kirocrew gateway' running?" >&2
    return 1
  fi
  if [ -n "$body" ]; then
    curl -sf -X "$method" "$BASE$path?token=$tok" -H 'Content-Type: application/json' -d "$body"
  else
    curl -sf -X "$method" "$BASE$path?token=$tok"
  fi
}

render_template() {
  local template="$1" out="$2"
  shift 2
  cp "$template" "$out"
  for kv in "$@"; do
    local key="${kv%%=*}" val="${kv#*=}"
    python3 - "$out" "$key" "$val" <<'PY'
import sys
path, key, val = sys.argv[1:4]
text = open(path).read()
text = text.replace("{{" + key + "}}", val)
open(path, "w").write(text)
PY
  done
}

tr_start() {
  local agent="$1" name="$2" spec_path="$3"
  local body
  body=$(python3 -c '
import json, sys
print(json.dumps({
    "spec": sys.argv[1],
    "agent": sys.argv[2],
    "name": sys.argv[3],
    "workspace_dir": sys.argv[4],
    "auto_approve": True,
}))
' "$spec_path" "$agent" "$name" "$PROJECT_DIR")
  api POST /api/taskrunner "$body"
}

tr_wait() {
  local task_id="$1"
  while :; do
    local out; out=$(api GET /api/taskrunner) || return 1
    local line
    line=$(echo "$out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for r in d.get('runs', []):
    if r['task_id'] == sys.argv[1]:
        print(r['running'], r['status'], r.get('error', ''))
        break
" "$task_id")
    read -r running status err <<<"$line"
    if [ "$running" = "False" ]; then
      log "task-runner run $task_id finished: $status $err"
      [ "$status" = "completed" ] && return 0 || return 1
    fi
    sleep 3
  done
}

run_workflow() {
  local agent="$1" name="$2" template="$3"
  shift 3
  step "$name (agent: $agent, template: $(basename "$template"))"
  local spec_path="$SPEC_DIR/$name.yaml"
  render_template "$template" "$spec_path" "$@"
  local resp task_id
  resp=$(tr_start "$agent" "$name" "$spec_path") || { log "failed to start $name"; return 1; }
  task_id=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('task_id',''))" 2>/dev/null)
  if [ -z "$task_id" ]; then
    log "no task_id returned starting $name: $resp"
    return 1
  fi
  log "started $name as $task_id"
  tr_wait "$task_id"
}

gate() {
  local epic="$1" want="$2"
  bash "$SCRIPT_DIR/rocket-gate-check.sh" "$epic" "$want"
}

latest_epic() {
  # bd list --sort created is already newest-first; --reverse flips it to
  # oldest-first (verified against a real bd install - the opposite of what
  # the flag name suggests). Do not add --reverse here.
  bd list --type epic --sort created --limit 1 --json 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['id'] if d else '')"
}

cmd_plan() {
  local story="$1"
  [ -f .kiro/crew/beads-dir ] && export BEADS_DIR; BEADS_DIR=$(cat .kiro/crew/beads-dir)

  run_workflow rocket-meowth plan "$WORKFLOWS_DIR/rocket-plan.yaml" "STORY=$story" || return 1

  local epic; epic=$(latest_epic)
  [ -z "$epic" ] && { log "could not find the new epic in beads"; return 1; }

  log ""
  log "Plan phase done for epic $epic. OPEN QUESTIONS should be on it - answer them with:"
  log "  bd comment $epic \"1. ...  2. ...\""
  log "Then run: scripts/rocket-dag.sh implement $epic"
}

cmd_implement() {
  local epic="$1"
  [ -f .kiro/crew/beads-dir ] && export BEADS_DIR; BEADS_DIR=$(cat .kiro/crew/beads-dir)

  run_workflow rocket-meowth confirm-plan "$WORKFLOWS_DIR/rocket-confirm-plan.yaml" "EPIC=$epic" || return 1
  gate "$epic" "GATE: PASS" || { log "confirm-plan gate failed - answer any new questions and rerun."; return 1; }

  run_workflow rocket-meowth approval-check "$WORKFLOWS_DIR/rocket-approval-check.yaml" "EPIC=$epic" || return 1
  if ! gate "$epic" "GATE: PASS"; then
    log ""
    log "Awaiting your APPROVED comment on $epic. Then rerun: scripts/rocket-dag.sh implement $epic"
    return 1
  fi

  for i in $(seq 1 25); do
    gate "$epic" "GATE: PASS" || { log "approval gate no longer passes - stopping the loop."; return 1; }
    local out
    out=$(run_workflow rocket-james "implement-$i" "$WORKFLOWS_DIR/rocket-implement.yaml" "EPIC=$epic")
    echo "$out" | grep -q "ALL_TASKS_COMPLETE" && { log "implement loop done after $i iteration(s)"; break; }
  done

  run_workflow rocket-jessie verify "$WORKFLOWS_DIR/rocket-verify.yaml" "EPIC=$epic" || return 1
  run_workflow rocket-james fix "$WORKFLOWS_DIR/rocket-fix.yaml" "EPIC=$epic" || return 1
  run_workflow rocket-jessie confirm "$WORKFLOWS_DIR/rocket-confirm.yaml" "EPIC=$epic" || return 1
  gate "$epic" "GATE: PASS" || { log "confirm gate failed - a broken change must not reach the PR. Stopping."; return 1; }

  run_workflow rocket-james pr "$WORKFLOWS_DIR/rocket-pr.yaml" "EPIC=$epic" || return 1
  run_workflow rocket-meowth retro "$WORKFLOWS_DIR/rocket-retro.yaml" "EPIC=$epic" || return 1

  log ""
  log "Pipeline done for $epic. Run 'scripts/rocket-dag.sh harvest <mr-url>' after human review."
}

cmd_harvest() {
  local mr="$1"
  [ -f .kiro/crew/beads-dir ] && export BEADS_DIR; BEADS_DIR=$(cat .kiro/crew/beads-dir)
  run_workflow rocket-james harvest "$WORKFLOWS_DIR/rocket-harvest.yaml" "MR=$mr"
}

case "${1:-}" in
  plan)       shift; cmd_plan "$*" ;;
  implement)  shift; cmd_implement "$1" ;;
  harvest)    shift; cmd_harvest "$*" ;;
  *)
    echo "usage: rocket-dag.sh plan '<story id or description>'"
    echo "       rocket-dag.sh implement <epic-id>"
    echo "       rocket-dag.sh harvest '<mr-url>'"
    exit 2
    ;;
esac
