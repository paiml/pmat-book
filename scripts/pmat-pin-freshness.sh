#!/usr/bin/env bash
# Pin-freshness LAB row helper (pmat-book#105). Never runs on a PR path.
#   verdict <workflow-file>   print "<state> <detail>"; exit 0 green, 1 red (pin behind), 2 not_measured
#   should_comment <prev> <state>   exit 0 only on the green->red edge (prev=success, state=red)
#   streak                    read conclusions (newest first) on stdin; print the leading non-success count
# Fails closed: anything unreadable is not_measured (exit 2), never green and never red.
set -u

API_URL="${CRATES_API_URL:-https://crates.io/api/v1/crates/pmat}"
SEMVER='^[0-9]+\.[0-9]+\.[0-9]+$'

read_pin() {
  local f=$1 pins
  [ -r "$f" ] || return 1
  pins=$(sed -n 's/^  PMAT_VERSION: "\([^"]*\)"[[:space:]]*$/\1/p' "$f")
  [ "$(printf '%s\n' "$pins" | grep -c .)" -eq 1 ] || return 1
  printf '%s\n' "$pins" | grep -Eq "$SEMVER" || return 1
  printf '%s\n' "$pins"
}

read_latest() {
  local body latest
  body=$(curl -fsS --max-time 30 -A "pmat-book-pin-freshness-check" "$API_URL") || return 1
  latest=$(printf '%s' "$body" | jq -er '.crate.max_stable_version') || return 1
  printf '%s\n' "$latest" | grep -Eq "$SEMVER" || return 1
  printf '%s\n' "$latest"
}

cmd_verdict() {
  local pin latest
  pin=$(read_pin "${1:-}") || { echo "not_measured cannot read exactly one PMAT_VERSION pin"; return 2; }
  latest=$(read_latest) || { echo "not_measured crates.io read failed or malformed"; return 2; }
  if [ "$pin" = "$latest" ]; then
    echo "green pin $pin equals crates.io max_stable_version"
    return 0
  fi
  echo "red pin $pin differs from crates.io max_stable_version $latest"
  return 1
}

cmd_should_comment() {
  [ "${1:-}" = "success" ] && [ "${2:-}" = "red" ]
}

cmd_streak() {
  local n=0 c
  while read -r c; do
    [ "$c" = "success" ] && break
    n=$((n + 1))
  done
  echo "$n"
}

case "${1:-}" in
  verdict) shift; cmd_verdict "$@" ;;
  should_comment) shift; cmd_should_comment "$@" ;;
  streak) cmd_streak ;;
  *) echo "usage: $0 verdict <file> | should_comment <prev> <state> | streak" >&2; exit 64 ;;
esac
