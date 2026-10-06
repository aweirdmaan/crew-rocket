#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$(pwd)"
BACKEND_MEOWTH=""
BACKEND_JESSIE=""
BACKEND_JAMES=""
BEADS_DIR=""
ASSUME_YES=0
DRY_RUN=0

log()  { printf '%s\n' "$*"; }
step() { printf '\n== %s ==\n' "$*"; }
run()  {
  if [ "$DRY_RUN" = 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    log "+ $*"
    "$@"
  fi
}

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--target DIR] [--meowth BACKEND] [--jessie BACKEND] [--james BACKEND]
                   [--beads-dir DIR] [--yes] [--dry-run]
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --meowth) BACKEND_MEOWTH="$2"; shift 2 ;;
    --jessie) BACKEND_JESSIE="$2"; shift 2 ;;
    --james) BACKEND_JAMES="$2"; shift 2 ;;
    --beads-dir) BEADS_DIR="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log "unknown flag: $1"; exit 2 ;;
  esac
done

confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  printf '%s [y/N] ' "$1"
  read -r reply
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

step "1. KiroCrew itself"

if command -v kirocrew >/dev/null 2>&1; then
  log "found: $(command -v kirocrew)"
else
  log "kirocrew not found on PATH."
  if confirm "Install it now via 'curl -fsSL https://download.crew.kiro.dev/cli.sh | sh'?"; then
    run bash -c 'curl -fsSL https://download.crew.kiro.dev/cli.sh | sh'
  else
    log "Skipping install. The rest of this script still copies the crew into"
    log "--target and configures beads; install KiroCrew yourself before using it."
  fi
fi

if command -v kirocrew >/dev/null 2>&1; then
  run kirocrew doctor || log "kirocrew doctor reported problems above - resolve them before running the crew."
fi

step "2. Detect available backends"

have_claude=0;  command -v claude  >/dev/null 2>&1 && have_claude=1
have_codex=0;   command -v codex   >/dev/null 2>&1 && have_codex=1
have_opencode=0; command -v opencode >/dev/null 2>&1 && have_opencode=1
have_openrouter=0; [ -n "${OPENROUTER_API_KEY:-}" ] && have_openrouter=1
have_devpass=0; [ -n "${DEVPASS_BASE_URL:-}${DEVPASS_API_KEY:-}" ] && have_devpass=1

log "claude CLI:        $([ $have_claude = 1 ] && echo yes || echo no)"
log "codex CLI:          $([ $have_codex = 1 ] && echo yes || echo no)"
log "opencode CLI:        $([ $have_opencode = 1 ] && echo yes || echo no)  (needed to reach openrouter/devpass)"
log "OPENROUTER_API_KEY:  $([ $have_openrouter = 1 ] && echo set || echo unset)"
log "DEVPASS_BASE_URL/KEY: $([ $have_devpass = 1 ] && echo set || echo unset)"

default_for() {
  if [ "$1" = james ] && [ "$have_codex" = 1 ]; then echo codex; return; fi
  if [ "$have_claude" = 1 ]; then echo claude; return; fi
  if [ "$have_codex" = 1 ]; then echo codex; return; fi
  if [ "$have_opencode" = 1 ] && { [ "$have_openrouter" = 1 ] || [ "$have_devpass" = 1 ]; }; then echo opencode; return; fi
  echo claude
}

[ -z "$BACKEND_MEOWTH" ] && BACKEND_MEOWTH="$(default_for meowth)"
[ -z "$BACKEND_JESSIE" ] && BACKEND_JESSIE="$(default_for jessie)"
[ -z "$BACKEND_JAMES" ]  && BACKEND_JAMES="$(default_for james)"

log ""
log "Proposed assignment (edit .kiro/crew/crew.yaml any time after setup):"
log "  meowth (plan/discover) -> $BACKEND_MEOWTH"
log "  jessie (verify/review) -> $BACKEND_JESSIE"
log "  james  (implement/pr)  -> $BACKEND_JAMES"

if ! confirm "Use this assignment?"; then
  for m in meowth jessie james; do
    printf 'backend for %s [kiro|claude|kas|codex|opencode|pi|goose]: ' "$m"
    read -r b
    case "$m" in
      meowth) BACKEND_MEOWTH="$b" ;;
      jessie) BACKEND_JESSIE="$b" ;;
      james)  BACKEND_JAMES="$b" ;;
    esac
  done
fi

step "3. openrouter / devpass via opencode (only if either is chosen)"

wants_gateway=0
for b in "$BACKEND_MEOWTH" "$BACKEND_JESSIE" "$BACKEND_JAMES"; do
  [ "$b" = openrouter ] && wants_gateway=1
  [ "$b" = devpass ] && wants_gateway=1
done

if [ "$wants_gateway" = 1 ]; then
  log "openrouter/devpass are model gateways, not KiroCrew agent backends."
  log "Routing both through 'opencode' - substituting that as the actual"
  log "backend value, with the gateway as opencode's provider."
  BACKEND_MEOWTH=${BACKEND_MEOWTH/openrouter/opencode}; BACKEND_MEOWTH=${BACKEND_MEOWTH/devpass/opencode}
  BACKEND_JESSIE=${BACKEND_JESSIE/openrouter/opencode}; BACKEND_JESSIE=${BACKEND_JESSIE/devpass/opencode}
  BACKEND_JAMES=${BACKEND_JAMES/openrouter/opencode}; BACKEND_JAMES=${BACKEND_JAMES/devpass/opencode}

  mkdir -p "$HOME/.config/opencode"
  provider_file="$HOME/.config/opencode/crew-rocket-provider.json"
  if [ "$have_openrouter" = 1 ]; then
    cat > "$provider_file" <<'JSON'
{
  "provider": {
    "openrouter": {
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "https://openrouter.ai/api/v1" }
    }
  }
}
JSON
    log "Wrote $provider_file (baseURL only - opencode reads OPENROUTER_API_KEY from your env)."
  fi
  if [ "$have_devpass" = 1 ]; then
    cat > "$provider_file" <<JSON
{
  "provider": {
    "devpass": {
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "${DEVPASS_BASE_URL:-https://devpass.internal/v1}" }
    }
  }
}
JSON
    log "Wrote $provider_file (baseURL only - opencode reads DEVPASS_API_KEY from your env)."
  fi
  log "This is opencode's documented OpenAI-compatible provider shape as of writing -"
  log "check it merged correctly with 'opencode auth list' / your opencode.json before relying on it."
fi

step "4. Copy the crew into $TARGET"

run mkdir -p "$TARGET/.kiro/steering" "$TARGET/.kiro/crew" "$TARGET/.kiro/skills" "$TARGET/.kiro/workflows" "$TARGET/scripts"
for f in "$SCRIPT_DIR"/.kiro/steering/*.md; do
  dest="$TARGET/.kiro/steering/$(basename "$f")"
  if [ -f "$dest" ]; then
    log "skip (exists): $dest"
  else
    run cp "$f" "$dest"
  fi
done
for d in "$SCRIPT_DIR"/.kiro/skills/*/; do
  slug="$(basename "$d")"
  run mkdir -p "$TARGET/.kiro/skills/$slug"
  run cp "$d/SKILL.md" "$TARGET/.kiro/skills/$slug/SKILL.md"
done
run cp "$SCRIPT_DIR/.kiro/workflows/"*.yaml "$TARGET/.kiro/workflows/"
run cp "$SCRIPT_DIR/scripts/rocket-gate-check.sh" "$SCRIPT_DIR/scripts/rocket-use-backend.sh" "$SCRIPT_DIR/scripts/rocket-dag.sh" "$TARGET/scripts/"
run chmod +x "$TARGET/scripts/rocket-gate-check.sh" "$TARGET/scripts/rocket-use-backend.sh" "$TARGET/scripts/rocket-dag.sh"

KIROCREW_HOME="${KIROCREW_HOME:-$HOME/.kiro/crew}"
run mkdir -p "$KIROCREW_HOME/skills"
for d in "$SCRIPT_DIR"/.kiro/skills/*/; do
  slug="$(basename "$d")"
  run mkdir -p "$KIROCREW_HOME/skills/$slug"
  run cp "$d/SKILL.md" "$KIROCREW_HOME/skills/$slug/SKILL.md"
done
log "Installed as global KiroCrew skills too ($KIROCREW_HOME/skills/rocket-*), each"
log "scoped with repo_scope: .kiro/crew/crew.yaml - they only activate in a session"
log "whose project contains that file, so no per-project dashboard trust grant is"
log "needed. Restart the gateway (kirocrew restart) to pick them up."

run mkdir -p "$TARGET/.kiro/agents" "$HOME/.kiro/agents"
for a in "$SCRIPT_DIR"/.kiro/agents/*.json; do
  run cp "$a" "$TARGET/.kiro/agents/$(basename "$a")"
  run cp "$a" "$HOME/.kiro/agents/$(basename "$a")"
done
log "Installed rocket-meowth / rocket-jessie / rocket-james as real KiroCrew agents"
log "(not just skill text on the default agent) - each maps its own skills as"
log "always-on resources and gets its own system prompt and tools. Start a session"
log "as one with: kirocrew chat --agent rocket-meowth"

if command -v kirocrew >/dev/null 2>&1; then
  for member in meowth jessie james; do
    if out=$(kirocrew agent create --name "rocket-$member" --kiro-agent "rocket-$member" 2>&1); then
      log "+ enrolled rocket-$member as a crew member (dashboard: Agent Capabilities > Agents)"
    elif echo "$out" | grep -qi "already exists"; then
      log "rocket-$member already enrolled - left as is"
    else
      log "warning: could not enroll rocket-$member ($out)"
    fi
  done
fi

crew_yaml="$TARGET/.kiro/crew/crew.yaml"
if [ ! -f "$crew_yaml" ]; then
  run cp "$SCRIPT_DIR/.kiro/crew/crew.yaml" "$crew_yaml"
fi
if [ "$DRY_RUN" = 0 ] && [ -f "$crew_yaml" ]; then
  python3 - "$crew_yaml" "$BACKEND_MEOWTH" "$BACKEND_JESSIE" "$BACKEND_JAMES" <<'PY' || log "warning: could not rewrite crew.yaml backends automatically - edit it by hand."
import re, sys
path, meowth, jessie, james = sys.argv[1:5]
text = open(path).read()
for member, backend in (("meowth", meowth), ("jessie", jessie), ("james", james)):
    text = re.sub(
        rf"({member}:.*?backend: )\S+",
        rf"\g<1>{backend}",
        text, count=1, flags=re.S,
    )
open(path, "w").write(text)
PY
fi

step "5. beads (task memory)"

if [ -z "$BEADS_DIR" ]; then
  BEADS_DIR="$TARGET/.beads"
fi
run mkdir -p "$BEADS_DIR"
if [ "$DRY_RUN" = 0 ]; then
  printf '%s\n' "$BEADS_DIR" > "$TARGET/.kiro/crew/beads-dir"
fi
log "wrote $TARGET/.kiro/crew/beads-dir -> $BEADS_DIR"

if command -v bd >/dev/null 2>&1; then
  export BEADS_DIR
  if ! (cd "$TARGET" && run bd init); then
    log "bd init reported an issue - check $BEADS_DIR by hand."
  fi
else
  log "bd (beads) not found on PATH. Install it (https://github.com/steveyegge/beads)"
  log "before running any rocket-* skill; every one of them shells out to bd."
fi

step "6. Apply the backend choice to KiroCrew"

if command -v kirocrew >/dev/null 2>&1; then
  if ! run kirocrew config set agent.acp_backend "$BACKEND_MEOWTH"; then
    log "kirocrew rejected agent.acp_backend=$BACKEND_MEOWTH - check 'kirocrew config edit'."
  fi
  if ! run kirocrew config set agent.member_acp_backend "$BACKEND_JESSIE"; then
    log "kirocrew rejected agent.member_acp_backend=$BACKEND_JESSIE - check 'kirocrew config edit'."
  fi
  log ""
  log "Before invoking james's skills (rocket-implement, rocket-fix, rocket-pr,"
  log "rocket-harvest) on a different backend than meowth, run:"
  log "  $TARGET/scripts/rocket-use-backend.sh james"

  if ! run kirocrew config set knowledge.auto_add_documents true; then
    log "kirocrew rejected knowledge.auto_add_documents=true - rocket-plan's Knowledge"
    log "Library step will skip itself since the tool it needs stays gated off."
  fi
else
  log "kirocrew not installed - crew.yaml records the intended backends; apply them"
  log "with 'kirocrew config set agent.acp_backend <backend>' once it is."
fi

step "Done"

log "Crew copied into: $TARGET"
log "Steering:          $TARGET/.kiro/steering/{philosophy,opinions,failure-modes}.md"
log "Skills:            $TARGET/.kiro/skills/rocket-*/SKILL.md (+ global copies under $KIROCREW_HOME/skills/)"
log "Workflows:         $TARGET/.kiro/workflows/rocket-*.yaml (native Task Runner DAGs, migrated from Archon)"
log "Crew manifest:     $crew_yaml"
log "Beads:             $BEADS_DIR"
log ""
log "Next: from $TARGET, either invoke the 'rocket-crew' skill with a story id or"
log "description (in Claude Code / Codex / KiroCrew, whichever backend you assigned"
log "to meowth), or run the native workflows directly:"
log "  scripts/rocket-dag.sh plan '<story id or description>'"
log "  scripts/rocket-dag.sh implement <epic-id>"
log "  scripts/rocket-dag.sh harvest '<mr-url>'"
log "See README.md for the full pipeline and the two human approval gates."
