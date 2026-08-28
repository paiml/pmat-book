#!/usr/bin/env bash
# POKA-YOKE: a command this book prints must exist in the pmat it documents.
#
# WHY THIS EXISTS
#
# An audit on 2026-08-25 found whole chapters documenting subcommands that do
# not exist — `pmat architecture` (39 examples), `pmat rules` (29),
# `pmat mutate` (removed after 2.175.0, 28 examples), and an appendix listing 31
# top-level commands that were never real. The book's own tests were GREEN
# throughout, because eight of them ran in MOCK_MODE whenever pmat was on PATH:
# 88 assertions, 0 of them real.
#
# Detecting that after the fact is not enough. Toyota's answer is JIDOKA — the
# line stops itself the moment a defect appears — and POKA-YOKE: make the defect
# impossible to introduce rather than merely visible afterwards. A per-chapter
# test cannot do that, because a new chapter arrives with no test and nobody
# notices. This gate does not depend on anyone remembering: it EXTRACTS every
# `pmat` invocation the book prints, mechanically, and checks each against the
# real binary. A new chapter is covered the moment it is written.
#
# WHAT IT CHECKS, AND WHAT IT DELIBERATELY DOES NOT
#
# It verifies the SUBCOMMAND PATH resolves — `pmat <a> <b> --help` exits 0.
# `--help` short-circuits before argument validation, so this proves the command
# EXISTS without executing it. That is the unambiguous half, and it is the half
# that catches whole-chapter fiction.
#
# It does NOT validate flags. Running a command to check its flags would execute
# it, and the book documents commands that write files and start servers. Flag
# drift is real (the audit found ~500 instances) but it needs a different
# mechanism, and a gate that silently executed documented commands would be
# worse than the drift.
#
# THE RATCHET
#
# The book cannot be fixed in one commit, so this is a ratchet, not a wall: the
# count of unresolvable paths may only go DOWN. That is Kaizen — today's number
# is the ceiling, and every PR either holds it or improves it. Raising it
# requires editing the baseline deliberately, which is a reviewable act rather
# than an accident.
#
# FAILS CLOSED
#
# No pmat on PATH is a FAILURE, not a skip. A gate that passes when it cannot
# measure is the defect this book already shipped once: MOCK_MODE turned an
# absent tool into 88 green assertions.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || { echo "FAIL: cannot cd to the book root" >&2; exit 2; }

BASELINE_FILE="scripts/documented-commands.baseline"
PMAT="${PMAT:-pmat}"

if ! command -v "$PMAT" >/dev/null 2>&1; then
    echo "FAIL: '$PMAT' is not on PATH." >&2
    echo "  This is a FAILURE and not a skip. This book documents a tool; if the" >&2
    echo "  tool is absent, this run verified NOTHING about whether its commands" >&2
    echo "  exist. Install it (\`cargo install pmat\`) or set PMAT=/path/to/pmat." >&2
    exit 2
fi

echo "verifying documented commands against: $("$PMAT" --version 2>/dev/null | head -1)"

# Extract candidate subcommand paths. One or two words after `pmat`, lowercase
# and dash — enough to name a subcommand, short enough not to swallow arguments.
# A leading `$ ` prompt is stripped; flags terminate the path.
mapfile -t PATHS < <(
    grep -rhoE '(^|\$ |[[:space:]])pmat +[a-z][a-z0-9-]*( +[a-z][a-z0-9-]*)?' src/*.md 2>/dev/null \
    | sed -E 's/^.*pmat +//' \
    | awk 'NF' | sort -u
)

total=0; ok=0; bad=0
BAD_LIST=$(mktemp); trap 'rm -f "$BAD_LIST"' EXIT

for p in "${PATHS[@]}"; do
    # shellcheck disable=SC2086  # deliberate: $p is one or two bare words
    if timeout 20 "$PMAT" $p --help >/dev/null 2>&1; then
        ok=$((ok + 1))
    else
        bad=$((bad + 1)); printf '%s\n' "$p" >> "$BAD_LIST"
    fi
    total=$((total + 1))
done

echo "  checked $total distinct subcommand path(s): $ok resolve, $bad do not"

if [ ! -f "$BASELINE_FILE" ]; then
    echo "FAIL: no baseline at $BASELINE_FILE." >&2
    echo "  Create it with the current count so the ratchet has a starting point:" >&2
    echo "    echo $bad > $BASELINE_FILE" >&2
    exit 2
fi
BASELINE=$(tr -dc '0-9' < "$BASELINE_FILE")
[ -n "$BASELINE" ] || { echo "FAIL: $BASELINE_FILE holds no number." >&2; exit 2; }

if [ "$bad" -gt "$BASELINE" ]; then
    echo >&2
    echo "FAIL: $bad unresolvable command path(s), baseline is $BASELINE." >&2
    echo "  The book gained a command that pmat does not have. The ratchet may" >&2
    echo "  only go DOWN." >&2
    echo >&2
    echo "  Paths that do not resolve:" >&2
    sed 's/^/    pmat /' "$BAD_LIST" >&2
    exit 1
fi

if [ "$bad" -lt "$BASELINE" ]; then
    echo
    echo "IMPROVED: $bad unresolvable, down from $BASELINE. Lower the baseline:"
    echo "    echo $bad > $BASELINE_FILE"
    echo "  Leaving it high would let the book drift back to where it is today."
    exit 1
fi

echo "  ratchet holds at $BASELINE."
