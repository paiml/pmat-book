#!/usr/bin/env bash
# Text assertions (NOT behavioural tests) over .github/workflows/test.yml and
# pmat-pin-freshness.yml: they check what the files say, not what a runner does.
# TEST_YML / FRESH_YML override the paths so mutants of the files can be checked.
# Exit 0 only if every row holds. Needs yq (mikefarah v4) and grep.
# shellcheck disable=SC2016  # patterns are single-quoted on purpose
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
T_YML="${TEST_YML:-$HERE/../.github/workflows/test.yml}"
F_YML="${FRESH_YML:-$HERE/../.github/workflows/pmat-pin-freshness.yml}"
fail=0
row() { # name, then a command that must succeed
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then echo "ok   $name"; else echo "FAIL $name"; fail=1; fi
}
q() { yq -r "$1" "$2"; }          # q <expr> <file>
eqq() { [ "$(q "$1" "$3")" = "$2" ]; }   # eqq <expr> <want> <file>
count() { grep -c -- "$1" "$2"; } # count <fixed text> <file>
cnt_is() { [ "$(grep -cF -- "$1" "$2")" -eq "$3" ]; }  # cnt_is <text> <file> <n>

row "test.yml parses" yq . "$T_YML"
row "fresh.yml parses" yq . "$F_YML"
row "PMAT_VERSION defined once at top level" eqq '.env.PMAT_VERSION' 3.44.0 "$T_YML"
row "6 install sites all pinned =PMAT_VERSION" cnt_is 'cargo install pmat --version "=${PMAT_VERSION}" --locked' "$T_YML" 6
row "no other cargo install pmat" eval '[ "$(grep -c "cargo install pmat" "$T_YML")" -eq 6 ]'
row "install sites use --locked (6)" eval '[ "$(grep "cargo install pmat" "$T_YML" | grep -c -- "--locked")" -eq 6 ]'
row "3 builds install into pmat-root" cnt_is '--locked --root "$GITHUB_WORKSPACE/pmat-root"' "$T_YML" 3
row "exact version read-back present 9 times (6 installs + 3 cells)" cnt_is '= "pmat ${PMAT_VERSION}" ]' "$T_YML" 9
row "read-back is head -n1 exact match, not grep" eval '[ "$(grep -c "head -n1" "$T_YML")" -eq 9 ] && ! grep -q "grep -F" "$T_YML"'
for os in ubuntu macos windows; do
  row "pmat-build-$os runs on $os-latest" eqq ".jobs.pmat-build-$os.\"runs-on\"" "$os-latest" "$T_YML"
  row "pmat-build-$os timeout 30" eqq ".jobs.pmat-build-$os.\"timeout-minutes\"" 30 "$T_YML"
  row "pmat-build-$os permissions contents read only" eqq ".jobs.pmat-build-$os.permissions | to_entries | map(.key + \"=\" + .value) | join(\",\")" "contents=read" "$T_YML"
  row "pmat-build-$os upload errors on missing files" eqq ".jobs.pmat-build-$os.steps[-1].with.\"if-no-files-found\"" error "$T_YML"
  row "pmat-build-$os uploads artifact pmat-$os-latest" eqq ".jobs.pmat-build-$os.steps[-1].with.name" "pmat-$os-latest" "$T_YML"
  row "test-$os needs only its own build" eqq ".jobs.test-$os.needs" "pmat-build-$os" "$T_YML"
  row "test-$os check name unchanged" eqq ".jobs.test-$os.name" "test-examples ($os-latest, \${{ matrix.chapter }})" "$T_YML"
  row "test-$os runs on $os-latest" eqq ".jobs.test-$os.\"runs-on\"" "$os-latest" "$T_YML"
  row "test-$os cell timeout 10" eqq ".jobs.test-$os.\"timeout-minutes\"" 10 "$T_YML"
  row "test-$os runs after a failed build (not skipped)" eqq ".jobs.test-$os.if" '${{ !cancelled() }}' "$T_YML"
  row "test-$os first step fails unless build succeeded" eval "yq -r '.jobs.test-$os.steps[0].run' '$T_YML' | grep -q 'exit 1' && [ \"\$(yq -r '.jobs.test-$os.steps[0].env.BUILD_RESULT' '$T_YML')\" = '\${{ needs.pmat-build-$os.result }}' ]"
  row "test-$os guard compares to success" eval "yq -r '.jobs.test-$os.steps[0].run' '$T_YML' | grep -qF '!= success'"
  row "test-$os permissions contents read only" eqq ".jobs.test-$os.permissions | to_entries | map(.key + \"=\" + .value) | join(\",\")" "contents=read" "$T_YML"
  row "test-$os 8 chapters" eqq ".jobs.test-$os.strategy.matrix.chapter | length" 8 "$T_YML"
  row "test-$os downloads pmat-$os-latest" eqq ".jobs.test-$os.steps[] | select(.uses == \"actions/download-artifact@v4\") | .with.name" "pmat-$os-latest" "$T_YML"
  row "test-$os runs make test-chapter" eqq ".jobs.test-$os.steps[] | select(.name == \"Run chapter tests\") | .run" 'make test-${{ matrix.chapter }}' "$T_YML"
  row "test-$os uploads results always" eqq ".jobs.test-$os.steps[-1].if" 'always()' "$T_YML"
done
row "dogfood-pmat needs the 3 test jobs" eqq '.jobs.dogfood-pmat.needs | join(",")' test-ubuntu,test-macos,test-windows "$T_YML"
row "build-book needs 3 tests + dogfood" eqq '.jobs.build-book.needs | join(",")' test-ubuntu,test-macos,test-windows,dogfood-pmat "$T_YML"
row "no test-examples job id left" eqq '.jobs."test-examples"' null "$T_YML"
row "no continue-on-error anywhere" eval '! grep -q "continue-on-error" "$T_YML" "$F_YML"'
row "no || true anywhere" eval '! grep -q "|| true" "$T_YML" "$F_YML"'
row "test.yml triggers unchanged (push, pull_request, dispatch, schedule)" eqq '.on | keys | join(",")' push,pull_request,workflow_dispatch,schedule "$T_YML"

row "fresh: triggers are schedule + dispatch only" eqq '.on | keys | join(",")' schedule,workflow_dispatch "$F_YML"
row "fresh: top-level permissions empty" eqq '.permissions | length' 0 "$F_YML"
row "fresh: job permissions exactly contents,actions read + issues write" eqq '.jobs.check.permissions | to_entries | map(.key + "=" + .value) | join(",")' "contents=read,actions=read,issues=write" "$F_YML"
row "fresh: timeout 5" eqq '.jobs.check."timeout-minutes"' 5 "$F_YML"
row "fresh: ticket is 105" eqq '.jobs.check.env.TICKET' 105 "$F_YML"
row "fresh: only one gh issue comment" cnt_is 'gh issue comment' "$F_YML" 1
row "fresh: never creates an issue or PR comment" eval '! grep -qE "gh (issue create|pr comment)" "$F_YML"'
row "fresh: current run excluded from history" cnt_is 'select(.databaseId != ${GITHUB_RUN_ID})' "$F_YML" 1
row "fresh: history is completed runs only" cnt_is '--status completed' "$F_YML" 1
row "fresh: STOP uses streak >= 7" eval 'grep -qF -- '"'"'[ "$n" -ge 7 ]'"'"' "$F_YML" && grep -qF "STOP:" "$F_YML"'
row "fresh: streak looks at the last 7 nights" cnt_is 'head -n7 prev.txt' "$F_YML" 1
row "fresh: comment step only when red" eqq '.jobs.check.steps[] | select(.name | test("Comment")) | .if' "steps.verdict.outputs.state == 'red'" "$F_YML"
row "fresh: comment goes through should_comment" cnt_is 'should_comment "$LAST" "$STATE"' "$F_YML" 1
row "fresh: run fails unless green" eqq '.jobs.check.steps[-1].if' "steps.verdict.outputs.rc != '0'" "$F_YML"
row "fresh: final step is exit 1" eqq '.jobs.check.steps[-1].run' 'exit 1' "$F_YML"
row "fresh: verdict is read from the script" cnt_is 'scripts/pmat-pin-freshness.sh verdict .github/workflows/test.yml' "$F_YML" 1


# --- snapshot rows: the whole job/file as parsed YAML (comments and formatting are not part of it) ---
snapall() { local n=$1 e=$2 f=$3 x=$4; if [ "$(yq -o=json -I0 "$e" "$f")" = "$x" ]; then echo "ok   snapshot: $n"; else echo "FAIL snapshot: $n"; fail=1; fi; }
IFS= read -r EXP_BUILD <<'JSON'
{"runs-on":"@OS@-latest","timeout-minutes":30,"permissions":{"contents":"read"},"steps":[{"name":"Build PMAT","shell":"bash","run":"cargo install pmat --version \"=${PMAT_VERSION}\" --locked --root \"$GITHUB_WORKSPACE/pmat-root\"\n[ \"$(\"$GITHUB_WORKSPACE/pmat-root/bin/pmat\" --version | head -n1)\" = \"pmat ${PMAT_VERSION}\" ]\n"},{"uses":"actions/upload-artifact@v4","with":{"name":"pmat-@OS@-latest","path":"pmat-root/bin","if-no-files-found":"error"}}]}
JSON
IFS= read -r EXP_TEST <<'JSON'
{"name":"test-examples (@OS@-latest, ${{ matrix.chapter }})","needs":"pmat-build-@OS@","if":"${{ !cancelled() }}","runs-on":"@OS@-latest","timeout-minutes":10,"permissions":{"contents":"read"},"strategy":{"matrix":{"chapter":["ch01","ch02","ch03","ch04","ch05","ch06","ch07","ch08"]}},"steps":[{"name":"Fail unless the pmat build for @OS@ succeeded","shell":"bash","env":{"BUILD_RESULT":"${{ needs.pmat-build-@OS@.result }}"},"run":"if [ \"$BUILD_RESULT\" != success ]; then\n  echo \"::error::pmat build for @OS@ failed (result: $BUILD_RESULT)\"\n  exit 1\nfi\n"},{"uses":"actions/checkout@v4"},{"uses":"actions/download-artifact@v4","with":{"name":"pmat-@OS@-latest","path":".pmat-bin"}},{"name":"Put the built PMAT on PATH","shell":"bash","run":"chmod +x .pmat-bin/pmat*\necho \"$GITHUB_WORKSPACE/.pmat-bin\" >> \"$GITHUB_PATH\"\n"},{"name":"Check PMAT version","shell":"bash","run":"[ \"$(pmat --version | head -n1)\" = \"pmat ${PMAT_VERSION}\" ]"},{"name":"Run chapter tests","run":"make test-${{ matrix.chapter }}\n"},{"name":"Upload test results","uses":"actions/upload-artifact@v4","if":"always()","with":{"name":"test-results-@OS@-latest-${{ matrix.chapter }}","path":"test-results/"}}]}
JSON
IFS= read -r EXP_FRESH <<'JSON'
{"name":"pmat-pin-freshness","on":{"schedule":[{"cron":"43 3 * * *"}],"workflow_dispatch":null},"permissions":{},"jobs":{"check":{"runs-on":"ubuntu-latest","timeout-minutes":5,"permissions":{"contents":"read","actions":"read","issues":"write"},"env":{"GH_TOKEN":"${{ github.token }}","GH_REPO":"${{ github.repository }}","TICKET":"105"},"steps":[{"uses":"actions/checkout@v4"},{"name":"Compare the pin with crates.io","id":"verdict","run":"if out=$(bash scripts/pmat-pin-freshness.sh verdict .github/workflows/test.yml); then rc=0; else rc=$?; fi\necho \"$out\" | tee -a \"$GITHUB_STEP_SUMMARY\"\necho \"state=${out%% *}\" >> \"$GITHUB_OUTPUT\"\necho \"rc=$rc\" >> \"$GITHUB_OUTPUT\"\n"},{"name":"Previous completed nights","id":"prev","run":"gh run list --workflow pmat-pin-freshness.yml --status completed --limit 8 \\\n  --json databaseId,conclusion \\\n  --jq \"[.[] | select(.databaseId != ${GITHUB_RUN_ID})] | .[].conclusion\" > prev.txt\necho \"last=$(head -n1 prev.txt)\" >> \"$GITHUB_OUTPUT\"\nn=$(head -n7 prev.txt | bash scripts/pmat-pin-freshness.sh streak)\necho \"streak=$n\" >> \"$GITHUB_OUTPUT\"\nif [ \"$n\" -ge 7 ]; then\n  echo \"STOP: 7 consecutive non-green nights. Maintainer: gh workflow disable pmat-pin-freshness.yml\" | tee -a \"$GITHUB_STEP_SUMMARY\"\nfi\n"},{"name":"Comment on the standing ticket (green to red edge only)","if":"steps.verdict.outputs.state == 'red'","env":{"LAST":"${{ steps.prev.outputs.last }}","STATE":"${{ steps.verdict.outputs.state }}"},"run":"if bash scripts/pmat-pin-freshness.sh should_comment \"$LAST\" \"$STATE\"; then\n  gh issue comment \"$TICKET\" --body \"pmat-pin-freshness went red: the PMAT_VERSION pin in test.yml is behind crates.io. Run: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}. Bump the pin by PR; the gate re-runs against the new version.\"\nfi\n"},{"name":"Fail unless green","if":"steps.verdict.outputs.rc != '0'","run":"exit 1"}]}}}
JSON
IFS= read -r EXP_TOP <<'JSON'
{"env":{"PMAT_VERSION":"3.44.0"},"on":{"push":{"branches":["main"]},"pull_request":{"branches":["main"]},"workflow_dispatch":null,"schedule":[{"cron":"17 5 * * 1"}]},"keys":["documented-commands","documented-flags-deep","pmat-build-ubuntu","test-ubuntu","pmat-build-macos","test-macos","pmat-build-windows","test-windows","dogfood-pmat","build-book"]}
JSON
IFS= read -r EXP_DC <<'JSON'
{"name":"Install PMAT","run":"cargo install pmat --version \"=${PMAT_VERSION}\" --locked\n[ \"$(pmat --version | head -n1)\" = \"pmat ${PMAT_VERSION}\" ]\n"}
JSON
IFS= read -r EXP_DF <<'JSON'
{"name":"Install PMAT","run":"cargo install pmat --version \"=${PMAT_VERSION}\" --locked\n[ \"$(pmat --version | head -n1)\" = \"pmat ${PMAT_VERSION}\" ]\n"}
JSON
IFS= read -r EXP_DOG <<'JSON'
{"needs":["test-ubuntu","test-macos","test-windows"],"step":{"name":"Install PMAT","run":"cargo install pmat --version \"=${PMAT_VERSION}\" --locked\n[ \"$(pmat --version | head -n1)\" = \"pmat ${PMAT_VERSION}\" ]\n"}}
JSON
IFS= read -r EXP_BOOK <<'JSON'
["test-ubuntu","test-macos","test-windows","dogfood-pmat"]
JSON
for os in ubuntu macos windows; do
  snapall "pmat-build-$os job" ".jobs.pmat-build-$os" "$T_YML" "${EXP_BUILD//@OS@/$os}"
  snapall "test-$os job" ".jobs.test-$os" "$T_YML" "${EXP_TEST//@OS@/$os}"
done
snapall "test.yml env, triggers, job list" '{"env":.env,"on":.on,"keys":(.jobs|keys)}' "$T_YML" "$EXP_TOP"
snapall "documented-commands install step" '.jobs.documented-commands.steps[1]' "$T_YML" "$EXP_DC"
snapall "documented-flags-deep install step" '.jobs.documented-flags-deep.steps[1]' "$T_YML" "$EXP_DF"
snapall "dogfood-pmat needs + install step" '{"needs":.jobs.dogfood-pmat.needs,"step":.jobs.dogfood-pmat.steps[1]}' "$T_YML" "$EXP_DOG"
snapall "build-book needs" '.jobs."build-book".needs' "$T_YML" "$EXP_BOOK"
snapall "pmat-pin-freshness.yml whole file" '.' "$F_YML" "$EXP_FRESH"

# every run block parses as shell (expressions replaced by a placeholder)
runs_parse() {
  local file=$1 n i
  n=$(yq '[.jobs[].steps[] | select(has("run"))] | length' "$file") || return 1
  for ((i = 0; i < n; i++)); do
    yq "[.jobs[].steps[] | select(has(\"run\"))] | .[$i].run" "$file" | sed 's/\${{[^}]*}}/X/g' | bash -n 2>/dev/null || return 1
  done
}
row "test.yml run blocks parse as shell" runs_parse "$T_YML"
row "pmat-pin-freshness.yml run blocks parse as shell" runs_parse "$F_YML"

# script text rows (the offline fixtures cannot see the real endpoint or the timeout)
S_SH="${SCRIPT:-$HERE/pmat-pin-freshness.sh}"
row "script: real crates.io endpoint is the default" grep -qF 'API_URL="${CRATES_API_URL:-https://crates.io/api/v1/crates/pmat}"' "$S_SH"
row "script: curl timeout is 30 s" grep -qF -- '--max-time 30 ' "$S_SH"
row "script: unknown subcommand exits 64" grep -qF 'exit 64' "$S_SH"

exit "$fail"
