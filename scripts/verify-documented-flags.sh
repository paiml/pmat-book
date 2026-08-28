#!/usr/bin/env bash
# POKA-YOKE II: a command this book prints must also PARSE.
#
# WHY THIS EXISTS
#
# Its sibling, verify-documented-commands.sh, checks that `pmat <a> <b> --help`
# exits 0 — that the SUBCOMMAND EXISTS. Its header says, in as many words, that
# it deliberately does not validate flags, because "running a command to check
# its flags would execute it, and the book documents commands that write files
# and start servers."
#
# That limit was reasonable and it is now obsolete, for two independent reasons.
#
# First, the defect it declines to catch is the dominant one. An audit on
# 2026-08-25 executed 1,640 distinct documented commands and found 829 broken
# across 66 chapters. Command existence explains 171 of them. The rest are flag
# shapes: a positional path where the command takes `-p/--path`, an enum value
# renamed (`--metrics pagerank` -> `page-rank`), a flag deleted two releases
# ago. Every one of those resolves under the existing gate and is wrong.
#
# Second, the premise is false. Executing is not required. clap reports a usage
# error BEFORE it honours `--help`, so appending `--help` to a documented
# command reproduces the parse error verbatim without running the command:
#
#     $ pmat analyze complexity --bogus-flag --help
#     error: unexpected argument found                      (exit 2)
#     $ pmat analyze graph-metrics --metrics pagerank --help
#     error: one of the values isn't valid for an argument  (exit 2)
#     $ pmat analyze tdg . --help
#     error: unexpected argument found                      (exit 2)
#     $ pmat analyze complexity --path . --help
#     (exit 0 — prints help, writes nothing, starts nothing)
#
# So the objection is not merely CONTAINED here, it is ELIMINATED: the default
# mode has no side effects to contain. It is also ~100x faster, which is the
# difference between a gate that runs on every PR and a gate that does not.
#
# --execute IS STILL PROVIDED, AND WHY IT IS NOT THE DEFAULT
#
# `--help` probing has exactly one blind spot, and it is measured, not assumed:
# clap short-circuits on `--help` before checking that REQUIRED arguments are
# present, so `pmat five-whys` (exit 2, "required arguments were not provided")
# reads as exit 0 under the probe. `--execute` runs each command for real, in a
# throwaway directory, and catches that class too.
#
# It is not the CI default because it is slower and, worse, it is NOT
# HERMETIC: its result depends on fixtures, network and git state. A gate that
# goes red for reasons the author cannot see gets ignored, and an ignored gate
# is worse than no gate. Run it deliberately — `make commands-parse-deep` —
# and compare the two with --report.
#
# CLASSIFICATION — THE PART THAT DECIDES WHETHER THIS IS SIGNAL OR NOISE
#
#   exit 2 + `error:` on stderr   PARSE FAILURE. clap could not read the line.
#   exit 2 + a `Usage:` block     PARSE FAILURE. How clap renders a missing
#                                 required subcommand (`pmat analyze`).
#   exit 124                      TIMEOUT. Reported, never counted as a parse
#                                 failure — a command that hangs, parsed fine.
#   exit 1 (or any other)         NOT A FAILURE. A command can parse perfectly
#                                 and exit 1 because a quality gate tripped or
#                                 a fixture is absent. Conflating the two would
#                                 make this gate noisy, and a noisy gate is
#                                 ignored. That is the whole design constraint.
#
# stderr is never discarded. The classification depends on it, and so does the
# operator: every failure is reported with the message that caused it.
#
# THE RATCHET
#
# Down-only, like its sibling: the parse-failure count may never rise. Unlike
# its sibling it does not FAIL when the count improves — it passes, prints the
# lower number and offers `--lower` to write it. Failing an improving PR adds
# friction without adding safety; the safety property is "may not go up".
#
# FAILS WHEN IT CANNOT MEASURE
#
# No pmat is exit 2, not a skip. So is an empty corpus, a missing baseline, and
# a run that blows its wall-clock budget with commands still unprobed. "We could
# not measure it" must never be printed as "it did not regress" — that is
# precisely how this book shipped 88 green MOCK_MODE assertions.

set -uo pipefail

# ---------------------------------------------------------------- worker mode
# Re-entrant: xargs fans out by re-invoking this script. Handled before
# anything else so the worker pays for none of the setup.
if [ "${1:-}" = "--probe-one" ]; then
    cmd="$2"
    # Defence in depth. The extractor drops shell substitution, variables and
    # metasyntax; if any leaks through, refuse rather than eval it.
    case "$cmd" in
        *'$'*|*'`'*|*';'*|*'|'*|*'&'*|*'<'*|*'>'*)
            printf 'LEAK\t0\textractor-leak\t%s\t\n' "$cmd"; exit 0 ;;
    esac

    rundir=$(mktemp -d "${PF_RUNROOT:?}/cmd.XXXXXXXX") || exit 1
    cp -R "${PF_FIXTURE:?}/." "$rundir/" 2>/dev/null
    errf="$rundir/.stderr"

    (
        cd "$rundir" || exit 1
        set -f  # no globbing: `src/**/*.rs` must stay literal, or the result
                # depends on what happens to be lying around in the fixture.
        # shellcheck disable=SC2296,SC2206
        eval "argv=( $cmd )" 2>/dev/null || exit 250
        if [ "${PF_MODE:?}" = "parse" ]; then argv+=( --help ); fi
        exec timeout -k 2 "${PF_TIMEOUT:?}" "${PF_PMAT:?}" "${argv[@]:1}" >/dev/null 2>"$errf"
    )
    status=$?   # captured directly: a pipe here would report the wrong command

    # Classify against the WHOLE stderr, never a truncation of it. `--debug`
    # commands emit hundreds of bytes of tracing before clap's verdict, so a
    # prefix match on the first 200 chars silently reclassified six real parse
    # failures as "ran and exited 2". Truncation is for DISPLAY only.
    hasline() { [ -s "$errf" ] && grep -qF "$1" "$errf"; }

    # A PARSE FAILURE is recognised by CLAP'S OWN VOCABULARY, not by "exit 2".
    #
    # `pmat` prints clap's ErrorKind description verbatim (cli_run_command.rs),
    # and ErrorKind is a closed set — so an exact whitelist is possible, and it
    # is the only sound rule. "exit 2 with `error:` on stderr" is NOT sound:
    #
    #     $ pmat debug serve --port 5678
    #     error: pmat debug serve is not implemented (DEBUG-002)   (exit 2)
    #     $ pmat debug serve --port 5678 --help                    (exit 0)
    #
    # That command PARSES. pmat simply also uses exit 2 for a deliberate
    # not-implemented stub. Under the loose rule the --execute sweep reported 18
    # such lines as parse failures against 11 real ones — a majority-noise gate,
    # which is the failure mode this whole design is trying to avoid.
    #
    # Anything else that exits 2 is recorded as `exit2-app-error` and REPORTED,
    # never counted. If clap grows a message this list lacks, that shows up as a
    # visible unclassified line rather than as a silently missed defect.
    class=""; verdict="OK"
    case "$status" in
        250) verdict="LEAK"; class="unquotable" ;;
        124|137) verdict="TIMEOUT"; class="timeout" ;;
        2)
            verdict="PARSE"
            if   hasline "unrecognized subcommand";                          then class="unrecognized-subcommand"
            elif hasline "unexpected argument";                              then class="unexpected-argument"
            elif hasline "one of the values isn't valid for an argument";    then class="invalid-value"
            elif hasline "invalid value";                                    then class="invalid-value"
            elif hasline "one or more required arguments were not provided"; then class="missing-required"
            elif hasline "a subcommand is required but one was not provided"; then class="missing-subcommand"
            elif hasline "cannot be used with one or more of the other";     then class="conflicting-arguments"
            elif hasline "equal sign is needed when assigning values";       then class="needs-equals"
            elif hasline "unexpected value for one of the arguments";        then class="too-many-values"
            elif hasline "more values required for one of the arguments";    then class="too-few-values"
            elif hasline "wrong number of values was provided";              then class="wrong-value-count"
            elif hasline "invalid UTF-8 was detected";                       then class="invalid-utf8"
            elif hasline "Usage:" && ! hasline "error:";                     then class="missing-subcommand"
            else verdict="RAN"; class="exit2-app-error"
            fi ;;
        0) verdict="OK"; class="ok" ;;
        *) verdict="RAN"; class="exit${status}" ;;
    esac

    # Show clap's verdict, not the first line of a tracing preamble.
    err=""
    if [ -s "$errf" ]; then
        err=$(grep -m1 -F 'error:' "$errf" 2>/dev/null | tr '\t\n' '  ' | cut -c1-200)
        [ -n "$err" ] || err=$(tr '\t\n' '  ' < "$errf" | cut -c1-200)
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$verdict" "$status" "$class" "$cmd" "$err"
    rm -rf "$rundir"
    exit 0
fi

# ------------------------------------------------------------------ main mode
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
cd "$(dirname "${BASH_SOURCE[0]}")/.." || { echo "FAIL: cannot cd to the book root" >&2; exit 2; }

MODE="parse"
SRC_DIR="src"
BASELINE_FILE=""   # defaulted per mode, once the flags are parsed
PMAT="${PMAT:-pmat}"
TIMEOUT=""
JOBS=""
BUDGET=""
LOWER=0
LIST=0
REPORT=""
COMPARE_TO=""
RATCHET=1

usage() {
    cat <<'EOF'
verify-documented-flags.sh — every pmat command this book prints must PARSE.

  --execute          run each command for real instead of appending --help.
                     Catches missing-required-argument too; slower, not hermetic.
  --src DIR          chapter directory to scan          (default: src)
  --baseline FILE    ratchet file  (default: scripts/documented-flags.baseline,
                     or documented-flags-execute.baseline under --execute — the
                     two modes measure different things and cannot share a number)
  --jobs N           parallel probes                    (default: min(nproc,8))
  --timeout SECONDS  per-command wall clock             (default: 15 parse / 25 execute)
  --budget SECONDS   total wall clock for the sweep     (default: 300 parse / 1800 execute)
  --report FILE      write the full per-command TSV here
  --compare-to DIR   on regression, name only the commands that fail here and
                     did NOT fail in DIR. Auto-derived from git HEAD when
                     scanning the default src/ inside a work tree.
  --no-ratchet       measure and report; skip the baseline comparison entirely
  --lower            rewrite the baseline when the count improved
  --list             print the extracted corpus and exit; probe nothing
  -h, --help         this text

Exit: 0 pass · 1 the ratchet regressed · 2 could not measure.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --execute)  MODE="execute" ;;
        --src)      SRC_DIR="${2:?--src needs a directory}"; shift ;;
        --baseline) BASELINE_FILE="${2:?--baseline needs a file}"; shift ;;
        --jobs)     JOBS="${2:?--jobs needs a number}"; shift ;;
        --timeout)  TIMEOUT="${2:?--timeout needs seconds}"; shift ;;
        --budget)   BUDGET="${2:?--budget needs seconds}"; shift ;;
        --report)   REPORT="${2:?--report needs a file}"; shift ;;
        --compare-to) COMPARE_TO="${2:?--compare-to needs a directory}"; shift ;;
        --no-ratchet) RATCHET=0 ;;
        --lower)    LOWER=1 ;;
        --list)     LIST=1 ;;
        -h|--help)  usage; exit 0 ;;
        *) echo "FAIL: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [ "$MODE" = "parse" ]; then
    : "${TIMEOUT:=15}"; : "${BUDGET:=300}"
    : "${BASELINE_FILE:=scripts/documented-flags.baseline}"
else
    : "${TIMEOUT:=25}"; : "${BUDGET:=1800}"
    : "${BASELINE_FILE:=scripts/documented-flags-execute.baseline}"
fi
if [ -z "$JOBS" ]; then
    JOBS=$(nproc 2>/dev/null || echo 4)
    [ "$JOBS" -gt 8 ] 2>/dev/null && JOBS=8
fi

for tool in awk sort mktemp timeout xargs; do
    command -v "$tool" >/dev/null 2>&1 || { echo "FAIL: '$tool' is required and absent." >&2; exit 2; }
done

if ! command -v "$PMAT" >/dev/null 2>&1; then
    echo "FAIL: '$PMAT' is not on PATH." >&2
    echo "  This is a FAILURE and not a skip. This book documents a tool; with the" >&2
    echo "  tool absent this run verified NOTHING about whether its commands parse." >&2
    echo "  Install it (\`cargo install pmat\`) or set PMAT=/path/to/pmat." >&2
    exit 2
fi

[ -d "$SRC_DIR" ] || { echo "FAIL: no chapter directory at '$SRC_DIR'." >&2; exit 2; }

WORKROOT=$(mktemp -d "${TMPDIR:-/tmp}/pmat-book-flags.XXXXXXXX") || exit 2
# Kill the whole process group on the way out: --execute starts daemons and
# servers, and `timeout` only reaps the direct child.
cleanup() { trap - EXIT; kill -- -$$ 2>/dev/null; rm -rf "$WORKROOT"; }
trap cleanup EXIT INT TERM

CORPUS="$WORKROOT/corpus.tsv"
RESULTS="$WORKROOT/results.tsv"

# ------------------------------------------------------------------- extract
# Deduplicate by command text, keeping the first file:line that printed it, so
# a failure is reported at a place a human can go and edit.
# A skip record carries its reason in $3 and the raw line in $4, so it must be
# deduplicated on $4 — keying skips on $3 collapses every skipped line in the
# book down to one per reason and reports a coverage gap 10x smaller than it is.
awk -f scripts/extract-documented-commands.awk "$SRC_DIR"/*.md 2>/dev/null \
  | awk -F'\t' '{ k = ($3 ~ /^!/) ? $3 FS $4 : $3 } !seen[k]++' > "$CORPUS"

skipped=$(awk -F'\t' '$3 ~ /^!/' "$CORPUS" | wc -l | tr -d ' ')
awk -F'\t' '$3 !~ /^!/' "$CORPUS" > "$CORPUS.cmds"
n=$(wc -l < "$CORPUS.cmds" | tr -d ' ')

if [ "$LIST" -eq 1 ]; then
    cut -f3 "$CORPUS.cmds"
    exit 0
fi

# --------------------------------------------------- execute-mode policy skips
# Parse mode probes every command in the corpus: appending `--help` cannot start
# a server or pin a CPU, so nothing needs excusing. --execute is different, and
# these are the commands it will NOT run, each for a stated reason:
#
#   pmat comply *      `comply check` drives one process to ~744% CPU and load
#                      to 75 with no child processes to kill individually. It is
#                      documented as unrunnable alongside anything else.
#   pmat serve *       binds a port and blocks.
#   pmat mcp-server *  same, plus a unix socket.
#   pmat agent *       starts a daemon that outlives `timeout`, which reaps only
#                      its direct child.
#
# They are EXCLUDED and COUNTED, never silently dropped: "not run" must not be
# readable as "ran clean". Parse mode still checks every one of them, so their
# flags are covered — by the gate that can afford to look.
policy_skipped=0
if [ "$MODE" = "execute" ]; then
    awk -F'\t' '$3 ~ /^pmat +(comply|serve|mcp-server|agent)( |$)/' "$CORPUS.cmds" > "$CORPUS.denied"
    awk -F'\t' '$3 !~ /^pmat +(comply|serve|mcp-server|agent)( |$)/' "$CORPUS.cmds" > "$CORPUS.keep"
    policy_skipped=$(wc -l < "$CORPUS.denied" | tr -d ' ')
    mv "$CORPUS.keep" "$CORPUS.cmds"
    n=$(wc -l < "$CORPUS.cmds" | tr -d ' ')
fi

if [ "$n" -eq 0 ]; then
    echo "FAIL: extracted 0 commands from $SRC_DIR/*.md." >&2
    echo "  An empty corpus is a broken extractor, not a clean book. Refusing to" >&2
    echo "  report a green ratchet over nothing measured." >&2
    exit 2
fi

echo "verifying documented flags against: $("$PMAT" --version 2>/dev/null | head -1)"
echo "  mode: $MODE ($([ "$MODE" = parse ] && echo 'append --help; nothing is executed' || echo 'run for real in a throwaway dir'))"
echo "  corpus: $n distinct command(s) from $SRC_DIR/*.md ($skipped line(s) skipped as unexecutable)"
[ "$policy_skipped" -gt 0 ] && \
    echo "  NOT RUN: $policy_skipped command(s) held back by execute-mode policy (servers, daemons, comply)."
echo "  bounds: ${TIMEOUT}s per command, $JOBS in parallel, ${BUDGET}s total budget"

# --------------------------------------------------------------------- probe
mkdir -p "$WORKROOT/run"
FIXTURE="$WORKROOT/fixture"
mkdir -p "$FIXTURE/src"
cat > "$FIXTURE/Cargo.toml" <<'EOF'
[package]
name = "book-fixture"
version = "0.1.0"
edition = "2021"
EOF
printf 'fn main() {\n    println!("fixture");\n}\n' > "$FIXTURE/src/main.rs"
( cd "$FIXTURE" && git init -q . && git add -A && \
  git -c user.email=book@example.com -c user.name=book commit -qm fixture ) >/dev/null 2>&1

export PF_MODE="$MODE" PF_TIMEOUT="$TIMEOUT" PF_PMAT="$PMAT" \
       PF_RUNROOT="$WORKROOT/run" PF_FIXTURE="$FIXTURE"

started=$SECONDS
cut -f3 "$CORPUS.cmds" \
  | tr '\n' '\0' \
  | timeout "$BUDGET" xargs -0 -P "$JOBS" -I{} "$SELF" --probe-one '{}' > "$RESULTS"
sweep_status=${PIPESTATUS[2]}   # xargs, NOT the last stage of the pipe
elapsed=$((SECONDS - started))

probed=$(wc -l < "$RESULTS" | tr -d ' ')
if [ "$sweep_status" -eq 124 ] || [ "$sweep_status" -eq 137 ]; then
    echo >&2
    echo "FAIL: the sweep exceeded its ${BUDGET}s budget with $probed/$n command(s) probed." >&2
    echo "  This is a MEASUREMENT FAILURE, not a pass. Raise --budget or --jobs." >&2
    exit 2
fi
if [ "$probed" -ne "$n" ]; then
    echo >&2
    echo "FAIL: probed $probed of $n command(s) (xargs exit $sweep_status)." >&2
    echo "  An incomplete sweep cannot certify a count. Refusing to report one." >&2
    exit 2
fi

[ -n "$REPORT" ] && { cp "$RESULTS" "$REPORT"; echo "  report: $REPORT"; }

# ------------------------------------------------------------------ classify
# Counts are assigned from awk, never piped into `grep -c`: grep -c PRINTS 0 and
# EXITS 1 when nothing matches, which under `set -o pipefail` turns a clean
# result into a failed pipeline.
count_of() { awk -F'\t' -v v="$1" '$1 == v { c++ } END { print c + 0 }' "$RESULTS"; }
bad=$(count_of PARSE)
ok=$(count_of OK)
ran=$(count_of RAN)
slow=$(count_of TIMEOUT)
leak=$(count_of LEAK)

echo "  ${elapsed}s: $ok parse clean, $bad PARSE FAILURE(S), $ran ran-and-exited-nonzero, $slow timed out, $leak unquotable"
# One stable, machine-readable line. Callers must never have to scrape the
# prose above it — a summary sentence gets reworded, and the scraper then reads
# an empty string as a zero.
echo "PARSE_FAILURES=$bad PROBED=$n MODE=$MODE POLICY_SKIPPED=$policy_skipped ELAPSED=${elapsed}s"

if [ "$leak" -gt 0 ]; then
    echo >&2
    echo "FAIL: $leak extracted command(s) could not be split into arguments." >&2
    awk -F'\t' '$1 == "LEAK" { print "    " $4 }' "$RESULTS" >&2
    echo "  The extractor let something through that it should have skipped." >&2
    exit 2
fi

# Under-detection must be VISIBLE. Anything that exited 2 without a message
# this classifier recognises is not counted — and is printed, because "we did
# not recognise it" silently reads as "it was fine".
unclassified=$(awk -F'\t' '$3 == "exit2-app-error" { c++ } END { print c + 0 }' "$RESULTS")
if [ "$unclassified" -gt 0 ]; then
    echo
    echo "  NOTICE: $unclassified command(s) exited 2 with a message clap does not own."
    echo "  Not counted as parse failures — they parsed, and pmat exited 2 for its own"
    echo "  reasons. Listed so a real clap message never hides in this bucket:"
    awk -F'\t' '$3 == "exit2-app-error" { printf "    %s\n      %s\n", $4, $5 }' "$RESULTS" | head -20
fi

if [ "$bad" -gt 0 ]; then
    echo
    echo "  parse failures by kind:"
    awk -F'\t' '$1 == "PARSE" { c[$3]++ } END { for (k in c) printf "    %5d  %s\n", c[k], k }' \
        "$RESULTS" | sort -rn
fi

# ------------------------------------------------------------------- ratchet
if [ "$RATCHET" -eq 0 ]; then
    exit 0
fi

if [ ! -f "$BASELINE_FILE" ]; then
    echo "FAIL: no baseline at $BASELINE_FILE." >&2
    echo "  Create it so the ratchet has a starting point:" >&2
    echo "    echo $bad > $BASELINE_FILE" >&2
    exit 2
fi
# Read the first bare number, honouring `#` comments, and REFUSE anything else.
# `tr -dc '0-9'` would happily turn a baseline file documented as
#   412   # measured against pmat 3.32.0
# into 4123232 — a silently inflated ceiling that can never fail. A baseline the
# reader is not allowed to annotate is a baseline nobody will maintain, so parse
# it properly instead of forbidding comments.
BASELINE=$(awk '
    { sub(/#.*/, ""); gsub(/[[:space:]]/, "") }
    $0 == "" { next }
    /^[0-9]+$/ { print; exit }
    { print "NAN"; exit }
' "$BASELINE_FILE")
case "$BASELINE" in
    ""|NAN)
        echo "FAIL: $BASELINE_FILE does not begin with a bare number." >&2
        echo "  Expected a count, optionally followed by '#' comments." >&2
        exit 2 ;;
esac

# Name the failures at the file:line that prints them, with clap's own message.
# A gate that says only "206 failures" when ONE was added makes the reader redo
# the entire audit by hand — and a 53KB failure report is a gate that gets
# scrolled past. So when a comparison tree is available, print ONLY what is new.
render() {
    awk -F'\t' 'NR == FNR { where[$3] = $1 ":" $2; next }
                { printf "    %s\n      %s  (%s)\n      %s\n", $1, where[$1], $2, $3 }' \
        "$CORPUS.cmds" "$1"
}

# Where the book stood at HEAD. Only auto-derived for the default src/ inside a
# git work tree; an explicit --src elsewhere has no meaningful "before".
derive_compare_tree() {
    [ -n "$COMPARE_TO" ] && { printf '%s' "$COMPARE_TO"; return 0; }
    [ "$SRC_DIR" = "src" ] || return 1
    command -v git >/dev/null 2>&1 || return 1
    command -v tar >/dev/null 2>&1 || return 1
    git rev-parse --verify -q HEAD >/dev/null 2>&1 || return 1
    mkdir -p "$WORKROOT/head" || return 1
    git archive HEAD -- "$SRC_DIR" 2>/dev/null | tar -x -C "$WORKROOT/head" 2>/dev/null
    [ -d "$WORKROOT/head/$SRC_DIR" ] || return 1
    printf '%s' "$WORKROOT/head/$SRC_DIR"
}

report_failures() {
    awk -F'\t' '$1 == "PARSE" { print $4 "\t" $3 "\t" $5 }' "$RESULTS" | sort > "$WORKROOT/bad.tsv"

    local tree extra=""
    tree=$(derive_compare_tree) || tree=""
    if [ -n "$tree" ] && [ -d "$tree" ]; then
        local flags=(--src "$tree" --no-ratchet --jobs "$JOBS" --timeout "$TIMEOUT"
                     --budget "$BUDGET" --report "$WORKROOT/before.tsv")
        [ "$MODE" = "execute" ] && flags+=(--execute)
        if "$SELF" "${flags[@]}" >/dev/null 2>&1 && [ -s "$WORKROOT/before.tsv" ]; then
            awk -F'\t' '$1 == "PARSE" { print $4 }' "$WORKROOT/before.tsv" | sort > "$WORKROOT/before.set"
            cut -f1 "$WORKROOT/bad.tsv" | sort > "$WORKROOT/now.set"
            comm -23 "$WORKROOT/now.set" "$WORKROOT/before.set" > "$WORKROOT/new.set"
            extra=$(wc -l < "$WORKROOT/new.set" | tr -d ' ')
        fi
    fi

    if [ -n "$extra" ] && [ "$extra" -gt 0 ]; then
        echo "  $extra command(s) fail here that did NOT fail in the comparison tree:"
        awk -F'\t' 'NR == FNR { new[$0] = 1; next } ($1 in new)' "$WORKROOT/new.set" "$WORKROOT/bad.tsv" \
            > "$WORKROOT/new.tsv"
        render "$WORKROOT/new.tsv"
        return
    fi

    # No usable "before": say so, and cap the dump rather than emitting 53KB.
    echo "  Could not diff against a previous state, so this is the WHOLE failing"
    echo "  set, capped. The regression is one of these:"
    head -40 "$WORKROOT/bad.tsv" > "$WORKROOT/capped.tsv"
    render "$WORKROOT/capped.tsv"
    local total
    total=$(wc -l < "$WORKROOT/bad.tsv" | tr -d ' ')
    [ "$total" -gt 40 ] && echo "    ... and $((total - 40)) more (see --report FILE for all of them)"
}

if [ "$bad" -gt "$BASELINE" ]; then
    echo >&2
    echo "FAIL: $bad command(s) do not parse, baseline is $BASELINE." >&2
    echo "  The book gained a command pmat cannot read. The ratchet only goes DOWN." >&2
    echo >&2
    report_failures >&2
    exit 1
fi

if [ "$bad" -lt "$BASELINE" ]; then
    echo
    echo "IMPROVED: $bad parse failures, down from $BASELINE."
    if [ "$LOWER" -eq 1 ]; then
        # Rewrite the NUMBER, keep the prose. A --lower that truncates the file
        # to one integer deletes the explanation of what the integer means and
        # how it was measured, which is how a baseline becomes folklore.
        awk -v n="$bad" '
            !done && /^[[:space:]]*[0-9]+[[:space:]]*(#.*)?$/ { print n; done = 1; next }
            { print }
            END { if (!done) print n }
        ' "$BASELINE_FILE" > "$BASELINE_FILE.tmp" && mv "$BASELINE_FILE.tmp" "$BASELINE_FILE"
        echo "  baseline lowered to $bad in $BASELINE_FILE (comments preserved)."
    else
        echo "  Lower the baseline so the gain cannot be given back:"
        echo "    echo $bad > $BASELINE_FILE      (or re-run with --lower)"
    fi
    exit 0
fi

echo "  ratchet holds at $BASELINE."
