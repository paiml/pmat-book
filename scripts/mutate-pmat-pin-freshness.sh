#!/usr/bin/env bash
# Mutation table for scripts/pmat-pin-freshness.sh: each mutant must turn the stub test red.
# Mutants are sed edits of a COPY in a mktemp dir; the target script contains no delete/sweep rule.
# Exit 0 only if every mutant is killed and every sed edit actually changed the copy.
# shellcheck disable=SC2016  # sed programs are single-quoted on purpose
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d) || exit 2
trap 'rm -rf "${T:?}"' EXIT
n=0 killed=0 bad=0
mutant() { # id description sed-expression
  n=$((n + 1))
  cp "$HERE/pmat-pin-freshness.sh" "$T/m.sh"
  sed -i -e "$3" "$T/m.sh"
  if cmp -s "$HERE/pmat-pin-freshness.sh" "$T/m.sh"; then echo "BAD  $1 $2 (sed changed nothing)"; bad=$((bad + 1)); return; fi
  if SCRIPT="$T/m.sh" bash "$HERE/selftest-pmat-pin-freshness.sh" >/dev/null 2>&1; then
    echo "LIVE $1 $2"; bad=$((bad + 1))
  else
    echo "dead $1 $2"; killed=$((killed + 1))
  fi
}
mutant M1 "pin==latest test always true"        's/\[ "\$pin" = "\$latest" \]/true/'
mutant M2 "red returns green"                   '/^  echo "red /{n;s/return 1/return 0/}'
mutant M3 "two pins accepted"                   's/\[ "\$(printf .%s\\n. "\$pins" | grep -c \.)" -eq 1 \] || return 1/true/'
mutant M4 "pin semver check dropped"            '/grep -Eq "\$SEMVER" || return 1/{x;s/^/x/;/^x$/{x;s/ || return 1//;b};x}'
mutant M5 "latest semver check dropped"         's/printf .%s\\n. "\$latest" | grep -Eq "\$SEMVER" || return 1/true/'
mutant M6 "user agent dropped"                  's/ -A "pmat-book-pin-freshness-check"//'
mutant M7 "curl -f dropped"                     's/curl -fsS/curl -sS/'
mutant M8 "user agent carries an identifier"   's/pmat-book-pin-freshness-check/tail-cop/'
mutant M9 "comment on any prev"                's/\[ "\${1:-}" = "success" \] \&\& //'
mutant M10 "comment on any state"               's/ \&\& \[ "\${2:-}" = "red" \]//'
mutant M11 "streak ignores success"             's/\[ "\$c" = "success" \] \&\& break/:/'
mutant M12 "streak off by one"                  's/n=\$((n + 1))/n=$((n + 2))/'
echo "mutants=$n killed=$killed not_killed_or_bad=$bad"
[ "$bad" -eq 0 ]
