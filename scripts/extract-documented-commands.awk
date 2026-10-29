# Extract the `pmat` command lines this book PRINTS as things to type.
#
# Emits one TSV record per accepted command:   file <TAB> line <TAB> command
# and one per deliberately skipped line:       file <TAB> line <TAB> !reason <TAB> raw
#
# The skips are emitted, not swallowed, because a gate that quietly narrows its
# own corpus is how a book gets a green check over 829 broken commands. The
# caller reports the skip tally so coverage is visible rather than assumed.
#
# WHAT COUNTS AS A COMMAND
#
# Only lines inside a fenced code block whose language is shell-ish (or bare),
# after stripping an interactive `$ ` prompt, that begin with `pmat` followed by
# a lowercase subcommand word. Prose mentions are not commands; a reader does
# not type a sentence.
#
# WHAT IS DELIBERATELY SKIPPED, AND WHY
#
# The consumer of this list EXECUTES what comes out (see
# verify-documented-flags.sh). So anything whose meaning depends on the
# reader's shell state is dropped rather than guessed at:
#
#   subst   `$(...)` / backticks — executing them would run arbitrary code from
#           a markdown file. Never.
#   var     `$VAR` — an unset variable does not vanish harmlessly. `--path $DIR`
#           with $DIR unset becomes `--path --threshold`, and clap rejects a
#           value that starts with `-`. That is a FABRICATED parse failure, and
#           a gate that manufactures its own findings is worthless.
#   meta    `<PATH>`, `[OPTIONS]`, `...` — metasyntax, addressed to a human.
#           Not a defect, not executable.
#   heredoc `<<` — spans lines this scanner does not own.
#
# Everything else is truncated at the first shell operator OUTSIDE QUOTES
# (`#`, `|`, `&`, `;`, `<`, `>`), because the pmat invocation is the part this
# book is responsible for. `pmat analyze complexity --format json > out.json`
# tests exactly as `pmat analyze complexity --format json`.
#
# Backslash continuations are joined first, so a wrapped multi-line invocation
# is tested as the single command it is rather than as two broken halves.

function is_shellish(l) {
    return (l == "" || l == "bash" || l == "sh" || l == "shell" ||
            l == "console" || l == "terminal" || l == "zsh")
}

# Truncate at the first shell operator that is not inside quotes.
# Returns the prefix. Quote state is tracked character by character; a naive
# index() would cut `pmat query "a|b"` in half and invent a parse failure.
function cut_at_operator(s,   i, c, sq, dq, out) {
    sq = 0; dq = 0; out = ""
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\" && !sq) { out = out c substr(s, i + 1, 1); i++; continue }
        if (c == "'" && !dq) { sq = !sq; out = out c; continue }
        if (c == "\"" && !sq) { dq = !dq; out = out c; continue }
        if (!sq && !dq && (c == "#" || c == "|" || c == "&" || c == ";" || c == "<" || c == ">")) break
        out = out c
    }
    return out
}

function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }

function emit_skip(reason, raw) { printf "%s\t%d\t!%s\t%s\n", FILENAME, start_line, reason, raw }

# Reset per-file so an unterminated fence cannot leak into the next chapter.
FNR == 1 { infence = 0; lang = ""; pending = ""; start_line = 0 }

/^[[:space:]]*```/ {
    if (infence) { infence = 0; lang = "" }
    else {
        infence = 1
        lang = $0
        sub(/^[[:space:]]*```[[:space:]]*/, "", lang)
        sub(/[[:space:]].*$/, "", lang)
        lang = tolower(lang)
    }
    pending = ""
    next
}

!infence || !is_shellish(lang) { next }

{
    line = trim($0)

    # Join backslash continuations into one logical command.
    if (pending != "") {
        raw = pending " " line
        if (line ~ /\\$/) { sub(/\\$/, "", raw); pending = trim(raw); next }
        pending = ""
    } else {
        sub(/^\$[[:space:]]+/, "", line)          # strip an interactive prompt
        if (line !~ /^pmat[[:space:]]+[a-z-]/) next
        start_line = FNR
        if (line ~ /\\$/) { raw = line; sub(/\\$/, "", raw); pending = trim(raw); next }
        raw = line
    }

    raw = trim(raw)
    if (raw !~ /^pmat[[:space:]]+[a-z-]/) next

    if (raw ~ /\$\(/ || raw ~ /`/)                { emit_skip("subst",   raw); next }
    if (raw ~ /<</)                               { emit_skip("heredoc", raw); next }
    if (raw ~ /<[A-Za-z_][A-Za-z0-9_-]*>/ ||
        raw ~ /\[[A-Z]+\]/ || raw ~ /\.\.\./ ||
        raw ~ /\{\{/)                             { emit_skip("meta",    raw); next }

    cmd = trim(cut_at_operator(raw))
    sub(/\\$/, "", cmd); cmd = trim(cmd)

    if (cmd !~ /^pmat[[:space:]]+[a-z-]/)         { emit_skip("empty",   raw); next }
    if (cmd ~ /\$[A-Za-z_{]/)                     { emit_skip("var",     raw); next }

    printf "%s\t%d\t%s\n", FILENAME, start_line, cmd
}
