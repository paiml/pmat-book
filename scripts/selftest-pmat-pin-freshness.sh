#!/usr/bin/env bash
# Stub test for scripts/pmat-pin-freshness.sh. No network: crates.io is a file:// fixture,
# and a stub curl on PATH records its arguments. SCRIPT=<path> runs it against a mutant.
# Every condition below is killed by at least one mutant in scripts/mutate-pmat-pin-freshness.sh.
set -u
SCRIPT="${SCRIPT:-$(dirname "$0")/pmat-pin-freshness.sh}"
T=$(mktemp -d) || exit 2
trap 'rm -rf "${T:?}"' EXIT
fail=0
check() { # name expected-rc actual-rc
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (want rc $2, got $3)"; fail=1; fi
}

mkdir -p "$T/bin"
printf 'env:\n  PMAT_VERSION: "3.44.0"\n' > "$T/pin-ok.yml"
printf 'env:\n  OTHER: "1"\n' > "$T/pin-none.yml"
printf 'env:\n  PMAT_VERSION: "3.44.0"\n  PMAT_VERSION: "3.43.0"\n' > "$T/pin-two.yml"
printf 'env:\n  PMAT_VERSION: "latest"\n' > "$T/pin-bad.yml"
echo '{"crate":{"max_stable_version":"3.44.0"}}' > "$T/api-same.json"
echo '{"crate":{"max_stable_version":"3.45.0"}}' > "$T/api-newer.json"
echo '{"crate":{"max_stable_version":null}}' > "$T/api-null.json"
echo '{"crate":{"max_stable_version":"3.44"}}' > "$T/api-short.json"
echo '{"errors":[{"detail":"rate limited"}]}' > "$T/api-err.json"
echo 'not json' > "$T/api-junk.json"

v() { CRATES_API_URL="file://$T/$2" bash "$SCRIPT" verdict "$T/$1" >/dev/null; echo $?; }
check "green: pin equals latest"            0 "$(v pin-ok.yml api-same.json)"
check "red: pin behind latest"              1 "$(v pin-ok.yml api-newer.json)"
check "not_measured: no pin"                2 "$(v pin-none.yml api-same.json)"
check "not_measured: two pins"              2 "$(v pin-two.yml api-same.json)"
check "not_measured: pin not semver"        2 "$(v pin-bad.yml api-same.json)"
check "not_measured: missing workflow file" 2 "$(v nonexistent.yml api-same.json)"
check "not_measured: latest null"           2 "$(v pin-ok.yml api-null.json)"
check "not_measured: latest not semver"     2 "$(v pin-ok.yml api-short.json)"
check "not_measured: error body"            2 "$(v pin-ok.yml api-err.json)"
check "not_measured: junk body"             2 "$(v pin-ok.yml api-junk.json)"
check "not_measured: fetch fails"           2 "$(v pin-ok.yml api-absent.json)"

# curl must send a User-Agent and fail on HTTP errors
cat > "$T/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CURL_ARGS"
echo '{"crate":{"max_stable_version":"3.44.0"}}'
STUB
chmod +x "$T/bin/curl"
CURL_ARGS="$T/args" PATH="$T/bin:$PATH" bash "$SCRIPT" verdict "$T/pin-ok.yml" >/dev/null
grep -qx -- '-A' "$T/args"; check "curl sends -A user agent" 0 $?
grep -Eq -- '^-[a-zA-Z]*f' "$T/args"; check "curl fails on HTTP errors (-f)" 0 $?
grep -qiE 'noah|paiml|tail-cop|claude' "$T/args"; check "user agent carries no identifiers" 1 $?

sc() { bash "$SCRIPT" should_comment "$1" "$2"; echo $?; }
check "comment: success->red"     0 "$(sc success red)"
check "silent: failure->red"      1 "$(sc failure red)"
check "silent: empty->red"        1 "$(sc '' red)"
check "silent: success->green"    1 "$(sc success green)"
check "silent: success->not_measured" 1 "$(sc success not_measured)"

st() { printf '%s\n' "$@" | bash "$SCRIPT" streak; }
check "streak: 3 then success" 3 "$(st failure failure cancelled success failure)"
check "streak: success first"  0 "$(st success failure)"
check "streak: all non-green"  7 "$(st failure failure failure failure failure failure failure)"
check "streak: empty"          0 "$(printf '' | bash "$SCRIPT" streak)"

exit "$fail"
