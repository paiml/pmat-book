# Appendix B: Command Reference

> **This appendix is generated from the binary, not written by hand.**
> Every command path below was read out of `{version}`'s own `--help` output and
> then re-checked by running `pmat <path> --help` and requiring exit status 0.
> Nothing in the tables is transcribed from memory. Regenerate it with:
>
> ```bash
> cargo run -q --release --manifest-path tools/gen-appendix-b/Cargo.toml > src/appendix-b-commands.md
> ```
>
> **If you bookmarked this page before {date}, what you read here was wrong.**
> Earlier editions listed 31 top-level commands that `pmat` has never had —
> `pmat architecture`, `pmat rules`, `pmat clippy`, `pmat status`, `pmat scan`,
> `pmat dashboard` and more. Of the 150 command paths that edition printed, 73 did
> not resolve. Every one of them is accounted for in
> [Commands earlier editions listed that do not exist](#commands-earlier-editions-listed-that-do-not-exist),
> with the real replacement where there is one.

`{version}` exposes **{n_top} top-level commands** and **{n_sub} subcommands**.

## How to read this appendix

- **Aliases are real.** `pmat a cx` is `pmat analyze complexity`. Anything in the
  Aliases column can be substituted for the command name.
- **`--help` works at every level**, and short-circuits before argument validation:
  `pmat <command> --help` and `pmat <command> <subcommand> --help` always print and
  exit 0 if the path exists. That is exactly the check this appendix is built on.
- **A command with subcommands requires one.** `pmat analyze .` is not "analyze the
  current directory" — it exits 2 with `error: unrecognized subcommand`. The path
  goes to the *subcommand*: `pmat analyze complexity --path .`
- **Path arguments are not uniform, and this is the single most common mistake.**
  Some commands take a positional path, some take `--path`, some take
  `--project-path`, and passing a positional to a command that wants a flag exits 2
  with `error: unexpected argument found`. The tables below name the form for every
  command, so check the column rather than guessing:

  ```bash
  pmat tdg .                              # positional
  pmat analyze complexity --path .        # --path
  pmat quality-gate --project-path .      # --project-path
  ```

- **`[NOT AVAILABLE in the default build]`** in a description is pmat's own wording.
  Those commands parse and appear in `--help`, but the shipped `cargo install pmat`
  binary refuses them at runtime; they need a non-default `--features` build. They are
  marked ⚠ below.
