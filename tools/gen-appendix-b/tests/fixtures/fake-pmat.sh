#!/bin/sh
# Fake `pmat` for the gen-appendix-b tests: prints canned clap-style --help trees.
# Set FAKE_PMAT_BREAK=<path words> to make that path exit 2 (unresolvable).
args="$*"
if [ -n "$FAKE_PMAT_BREAK" ] && [ "$args" = "$FAKE_PMAT_BREAK --help" ]; then
  echo "error: unrecognized subcommand" >&2
  exit 2
fi
case "$args" in
  "--version")
    echo "pmat 9.9.9"
    echo "commit: deadbeef"
    ;;
  "--help")
    cat <<'EOT'
Fake pmat top-level

Usage: pmat [OPTIONS] [COMMAND]

Commands:
  analyze  Analyze code metrics and patterns
  tdg      Grade technical debt | pipes and pmat mentions [aliases: grade, t]
  query    Search code with pmat and a very long description that keeps going well past the
           truncation limit so that the cell function has to cut it at a word boundary and add
           an ellipsis marker to the end of the text
  repo-score  Score a repo [alias: rs]
  extract  Extract items from a file
  hooks    [NOT AVAILABLE in the default build] Manage hooks
  help     Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
EOT
    ;;
  "analyze --help")
    cat <<'EOT'
Analyze code metrics and patterns

Usage: pmat analyze [OPTIONS] <COMMAND>

Commands:
  complexity  Analyze code complexity [aliases: cx, complex]

  satd        Analyze SATD [alias: debt]
  dag         [REMOVED] Dependency graphs
  help        Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
EOT
    ;;
  "analyze complexity --help")
    cat <<'EOT'
Analyze code complexity

Usage: pmat analyze complexity [OPTIONS]

Options:
  -p, --path <PATH>
          Project path
      --max-cyclomatic <N>
          Cap
  -v, --verbose
  -f, --format <FORMAT>
          Output; see also --not-a-flag in prose
EOT
    ;;
  "analyze satd --help")
    cat <<'EOT'
Analyze SATD

Usage: pmat analyze satd [OPTIONS]

Options:
      --project-path <PATH>
          Project path
EOT
    ;;
  "analyze dag --help")
    echo "Usage: pmat analyze dag"
    ;;
  "tdg --help")
    cat <<'EOT'
Grade debt

Usage: pmat tdg [OPTIONS] [PATH] [COMMAND]

Commands:
  compare  Compare two files
  history  View history
  help     Print this message

Arguments:
  [PATH]
          File or directory to analyze

          [default: .]

Options:
  -h, --help  Print help
EOT
    ;;
  "tdg compare --help")
    cat <<'EOT'
Compare

Arguments:
  <FILE>
  <OTHER>
  Extra prose line after args

Options:
      --path <PATH>
EOT
    ;;
  "tdg history --help")
    echo "Usage: pmat tdg history"
    ;;
  "query --help")
    cat <<'EOT'
Query

Arguments:
  <QUERY>
          The query

Options:
      --limit <N>
EOT
    ;;
  "repo-score --help")
    cat <<'EOT'
Score

Options:
  -p, --path <PATH>
EOT
    ;;
  "extract --help")
    cat <<'EOT'
Extract

Options:
      --list <FILE>
EOT
    ;;
  "hooks --help")
    echo "Usage: pmat hooks"
    ;;
  *)
    echo "error: unrecognized path: $args" >&2
    exit 2
    ;;
esac
