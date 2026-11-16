#!/usr/bin/env bash
# Mechanical mutation pass. For every non-blank, non-comment line of the targets and every operator below
# that changes that line, make a mutant COPY (in a mktemp dir) and classify it:
#   unparseable  the mutant no longer parses (bash -n / yq .)
#   killed       its checker (stub test or text-assertion rows) goes red
#   equivalent   only text after a trailing " # " comment changed (cannot change behaviour)
#   survived     the checker stays green: reviewed by hand, listed in the PR
# Targets: scripts/pmat-pin-freshness.sh (checker: selftest-pmat-pin-freshness.sh, behavioural),
#          .github/workflows/pmat-pin-freshness.yml (every line) and the lines of test.yml this PR added
#          (checker: selftest-workflow-rows.sh, TEXT assertions, not behavioural).
# Usage: mutate-mechanical.sh [base-ref]   (default origin/main; prints one line per mutant, then totals)
# The only delete is `rm -rf "${T:?}"` of that mktemp dir; no target contains a delete rule.
# shellcheck disable=SC2016
set -u

# Survivors proven equivalent (reviewed by hand). Format: target:line:op  -- proof.
# scripts/pmat-pin-freshness.sh:7:del      -- set -u only turns a read of an unset variable into an error; every expansion is
#                                             defined first or written ${1:-}/${2:-}, so no input reaches an unset read.
# scripts/pmat-pin-freshness.sh:14:del     -- [ -r f ]: an unreadable file makes sed print nothing, pins is empty, the count
#                                             check on the next line returns 1 anyway (same exit 2). Fixture "missing workflow file".
# scripts/pmat-pin-freshness.sh:14:num-9   -- return 19 instead of return 1: every caller only tests for non-zero.
# scripts/pmat-pin-freshness.sh:17:num-9   -- same (return 19).
# scripts/pmat-pin-freshness.sh:24:num-9   -- same (return 19).
# scripts/pmat-pin-freshness.sh:25:num-9   -- same (return 19).
# scripts/pmat-pin-freshness.sh:22:del     -- local body latest: read_latest runs inside $( ), so its variables never leave the subshell.
# scripts/pmat-pin-freshness.sh:30:del     -- local pin latest: one cmd_verdict per process; the globals are not read elsewhere.
# scripts/pmat-pin-freshness.sh:58:num-9  -- the first digit run on that line is the 0 of $0 in the usage text: only the message changes.
PROVEN='|scripts/pmat-pin-freshness.sh:7:del|scripts/pmat-pin-freshness.sh:14:del|scripts/pmat-pin-freshness.sh:14:num-9|scripts/pmat-pin-freshness.sh:17:num-9|scripts/pmat-pin-freshness.sh:22:del|scripts/pmat-pin-freshness.sh:24:num-9|scripts/pmat-pin-freshness.sh:25:num-9|scripts/pmat-pin-freshness.sh:30:del|scripts/pmat-pin-freshness.sh:58:num-9|'
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
BASE="${1:-origin/main}"

OPS=(
  'del|d'
  'eq-ne|s/ -eq / -ne /'
  'ge-lt|s/ -ge / -lt /'
  'eq-neq|s/ = / != /'
  'and-or|s/ && / || /'
  'or-and|s/ || / \&\& /'
  'ret1-0|s/return 1/return 0/'
  'exit1-0|s/exit 1/exit 0/'
  'read-write|s/: read$/: write/'
  'error-warn|s/: error$/: warn/'
  'locked-drop|s/ --locked//'
  'success-fail|s/success/failure/'
  'num-9|s/[0-9][0-9]*/&9/'
  'cancelled-always|s/!cancelled()/always()/'
  'bang-drop|s/!= success/= success/'
)

worker() { # worker <target> <line> <opid> ; prints one result line
  local target=$1 line=$2 opid=$3 sedx="" op
  for op in "${OPS[@]}"; do [ "${op%%|*}" = "$opid" ] && sedx="${op#*|}"; done
  local d; d=$(mktemp -d) || exit 2
  local ext="${target##*.}"
  local m="$d/m.$ext" orig="$ROOT/$target"
  if [ "$sedx" = d ]; then sed "${line}d" "$orig" > "$m"; else sed "${line}${sedx}" "$orig" > "$m"; fi
  local status
  if cmp -s "$orig" "$m"; then rm -rf "${d:?}"; return 0; fi
  local before after
  before=$(sed -n "${line}p" "$orig"); after=$(sed -n "${line}p" "$m")
  local parses=0 green=0
  if [ "$ext" = sh ]; then bash -n "$m" 2>/dev/null && parses=1; else yq . "$m" >/dev/null 2>&1 && parses=1; fi
  if [ "$parses" -eq 0 ]; then status=unparseable
  elif [ "$ext" = yml ] && [ "$sedx" != d ] && [ "${before%% # *}" = "${after%% # *}" ] && [[ "$before" == *" # "* ]]; then status=equivalent
  else
    case "$target" in
      scripts/pmat-pin-freshness.sh) SCRIPT="$m" bash "$ROOT/scripts/selftest-pmat-pin-freshness.sh" >/dev/null 2>&1 && SCRIPT="$m" bash "$ROOT/scripts/selftest-workflow-rows.sh" >/dev/null 2>&1 && green=1 ;;
      .github/workflows/pmat-pin-freshness.yml) FRESH_YML="$m" bash "$ROOT/scripts/selftest-workflow-rows.sh" >/dev/null 2>&1 && green=1 ;;
      .github/workflows/test.yml) TEST_YML="$m" bash "$ROOT/scripts/selftest-workflow-rows.sh" >/dev/null 2>&1 && green=1 ;;
    esac
    if [ "$green" -eq 0 ]; then status=killed; else status=survived; fi
  fi
  rm -rf "${d:?}"
  printf '%s\t%s:%s\t%s\t%s\n' "$status" "$target" "$line" "$opid" "$(printf '%s' "$before" | cut -c1-90)"
}

if [ "${1:-}" = "--worker" ]; then shift; worker "$@"; exit 0; fi

list() { # list <target> [only-lines-file]
  local t=$1 only=${2:-} n=0 l
  while IFS= read -r l || [ -n "$l" ]; do
    n=$((n + 1))
    case "$l" in ''|*[![:space:]]*) ;; esac
    [ -z "${l//[[:space:]]/}" ] && continue
    case "${l#"${l%%[![:space:]]*}"}" in '#'*) continue ;; esac
    if [ -n "$only" ] && ! grep -qx "$n" "$only"; then continue; fi
    local op; for op in "${OPS[@]}"; do
      [ "${op%%|*}" = num-9 ] && ! grep -qE "timeout|-ge |max-time|head -n|limit|exit [0-9]|return [0-9]|PMAT_VERSION|cron|chapter|[0-9]+\.[0-9]+\.[0-9]+|-eq [0-9]" <<< "$l" && continue
      printf "%s\t%s\t%s\n" "$t" "$n" "${op%%|*}"
    done
  done < "$ROOT/$t"
}

ADDED=$(mktemp) || exit 2
trap 'rm -f "${ADDED:?}"' EXIT
git -C "$ROOT" diff -U0 -w --ignore-blank-lines "$BASE" -- .github/workflows/test.yml 2>/dev/null \
  | awk '/^@@/ { split($3, a, ","); s = substr(a[1], 2) + 0; c = (a[2] == "" ? 1 : a[2]) + 0; for (i = 0; i < c; i++) print s + i }' > "$ADDED"
if [ ! -s "$ADDED" ]; then
  # no diff against base (e.g. after merge): treat the whole file as in scope
  seq 1 "$(wc -l < "$ROOT/.github/workflows/test.yml")" > "$ADDED"
fi

export ROOT
{ list scripts/pmat-pin-freshness.sh; list .github/workflows/pmat-pin-freshness.yml; list .github/workflows/test.yml "$ADDED"; } \
  | xargs -P "$(nproc)" -L1 bash -c 'bash "'"$HERE"'/mutate-mechanical.sh" --worker "$0" "$1" "$2"' \
  | awk -F"\t" -v OFS="\t" -v P="$PROVEN" '$1 == "survived" && index(P, "|" $2 ":" $3 "|") { $1 = "equivalent" } { print }' | sort > "$ADDED.out"
cat "$ADDED.out"
awk -F"\t" '{c[$1]++} END{printf "killed=%d equivalent=%d unparseable=%d survived=%d\n", c["killed"], c["equivalent"], c["unparseable"], c["survived"]}' "$ADDED.out"
rm -f "${ADDED:?}.out"
