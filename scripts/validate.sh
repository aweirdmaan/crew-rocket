#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
fail=0
ok()  { printf 'PASS  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; fail=1; }
note() { printf '  %s\n' "$1"; }

echo "== skills referenced by rocket-crew.md exist =="
while IFS= read -r skill; do
  if [ -f ".kiro/skills/$skill/SKILL.md" ]; then
    ok "$skill"
  else
    bad "$skill (referenced by rocket-crew.md, missing from .kiro/skills/)"
  fi
done < <(grep -oE '`rocket-[a-z-]+`' .kiro/skills/rocket-crew/SKILL.md | tr -d '`' \
           | grep -vx -e rocket-gate-check -e rocket-use-backend | sort -u)

echo "== skill frontmatter =="
for f in .kiro/skills/*/SKILL.md; do
  if grep -q '^description:' "$f" && grep -q '^crew_member:' "$f" && grep -q '^repo_scope:' "$f"; then
    ok "$f"
  else
    bad "$f (missing description:, crew_member:, or repo_scope: frontmatter)"
  fi
done

echo "== artifacts exist =="
for f in .kiro/steering/opinions.md .kiro/steering/philosophy.md \
         .kiro/steering/failure-modes.md .kiro/crew/crew.yaml \
         .kiro/crew/beads-dir.example .kiro/agents/rocket-meowth.json \
         .kiro/agents/rocket-jessie.json .kiro/agents/rocket-james.json; do
  if [ -f "$f" ]; then ok "$f"; else bad "$f (missing)"; fi
done

echo "== agent specs parse as JSON =="
for f in .kiro/agents/rocket-*.json; do
  if python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
    ok "$f"
  else
    bad "$f (invalid JSON)"
  fi
done

echo "== crew.yaml parses =="
if python3 -c "import yaml" 2>/dev/null; then
  if python3 -c "import yaml; yaml.safe_load(open('.kiro/crew/crew.yaml'))" 2>/dev/null; then
    ok ".kiro/crew/crew.yaml"
  else
    bad ".kiro/crew/crew.yaml (invalid YAML)"
  fi
else
  note "(PyYAML not installed - skipped YAML parse check; install via 'pip install pyyaml')"
fi

echo "== kiro workflow templates (migrated from .archon/workflows) =="
if python3 -c "import yaml" 2>/dev/null; then
  for f in .kiro/workflows/*.yaml; do
    if python3 -c "
import sys, yaml
doc = yaml.safe_load(open('$f'))
assert isinstance(doc, dict) and 'agents' in doc, 'missing top-level agents: key'
assert isinstance(doc['agents'], dict) and doc['agents'], 'agents: must be a non-empty mapping'
for name, spec in doc['agents'].items():
    assert 'prompt' in spec, f'{name}: missing prompt'
" 2>/dev/null; then
      ok "$f"
    else
      bad "$f (invalid, or not shaped like a Task Runner agents: DAG)"
    fi
  done
else
  note "(PyYAML not installed - skipped workflow YAML parse check)"
fi

echo "== kiro workflow templates reference real skills =="
for f in .kiro/workflows/*.yaml; do
  while IFS= read -r skill; do
    if [ -f ".kiro/skills/$skill/SKILL.md" ]; then
      ok "$f -> $skill"
    else
      bad "$f references .kiro/skills/$skill/SKILL.md, which does not exist"
    fi
  done < <(grep -oE '\.kiro/skills/rocket-[a-z-]+/SKILL\.md' "$f" | sed -E 's#\.kiro/skills/(.*)/SKILL\.md#\1#' | sort -u)
done

echo "== shell scripts =="
HAVE_SHELLCHECK=0; command -v shellcheck >/dev/null 2>&1 && HAVE_SHELLCHECK=1
while IFS= read -r s; do
  [ -x "$s" ] && ok "executable: $s" || bad "not executable: $s (chmod +x)"
  if [ "$HAVE_SHELLCHECK" = 1 ]; then
    if shellcheck -S warning "$s" >/dev/null 2>&1; then ok "shellcheck: $s"; else bad "shellcheck: $s"; fi
  fi
done < <(find . -name '*.sh' -not -path './.git/*' | sort)
[ "$HAVE_SHELLCHECK" = 0 ] && note "(shellcheck not installed - skipped lint; install via 'brew install shellcheck')"

echo "== setup.sh dry-run =="
tmp=$(mktemp -d)
if ./setup.sh --target "$tmp" --meowth claude --jessie claude --james codex --yes --dry-run >/dev/null 2>&1; then
  ok "setup.sh --dry-run"
else
  bad "setup.sh --dry-run (nonzero exit)"
fi
rm -rf "$tmp"

echo
if [ "$fail" = 0 ]; then echo "ALL CHECKS PASSED"; else echo "VALIDATION FAILED"; fi
exit "$fail"
