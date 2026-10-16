# Chapter 2: Getting Started with PMAT

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 18 | Executed against pmat 3.32.0; output pasted verbatim |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite.** `pmat context` has eight options. The 2025
> edition of this chapter documented twenty-six, and eighteen of them have never
> existed: `--include`, `--exclude`, `--exclude-large`, `--max-file-size`,
> `--with-analysis`, `--max-tokens`, `--max-files`, `--sort-by`,
> `--smart-truncate`, `--max-lines-per-file`, `--cache`, `--refresh`,
> `--clear-cache`, `--ttl`, `--ai-format`, `--prepend`, `--template`,
> `--repos-file`, `--monorepo`, `--incremental`, `--since`, `--timeout`,
> `--parallel`, `--stream`, `--max-memory`, `--skip-errors`. Whole sections
> ("Size Management", "Caching for Performance", "Custom Templates", "Multiple
> Repositories", "Incremental Context") were built on flags the parser rejects
> with exit 2, so they are gone rather than rewritten around a substitute that
> does not exist either.
>
> Two further corrections:
>
> - **`pmat context` takes no positional path.** `pmat context /path/to/project`
>   exits 2. The path goes in `-p` / `--project-path`.
> - **There is no `--include` / `--exclude` filtering.** The real way to narrow
>   a context is `--language` / `--languages`, or pointing `-p` at a
>   subdirectory. Both are demonstrated below.

## Your First PMAT Analysis

After installing PMAT (Chapter 1), `pmat context` is the command you will reach
for first. It walks a project, parses every source file it recognises, and
prints a structured summary — file inventory, per-function complexity, and a
quality scorecard — in a form an LLM or a tool can consume.

## The Worked Example

Everything below runs against this four-file polyglot project, which exercises
pmat's multi-language support:

```
Cargo.toml
src/lib.rs      // TODO: harden the parser  + two Rust fns
src/main.rs     one Rust fn
py/app.py       two Python fns
web/index.ts    two TypeScript fns + one arrow
```

## Basic Context Generation

```bash
pmat context
```

```
⏳ Analyzing project...
Analyses complete
Analysis complete!
# Project Context

**Language**: rust
**Project Path**: .

## Project Structure

- **Total Files**: 4
- **Total Functions**: 8
- **Median Cyclomatic**: 2.00
- **Median Cognitive**: 2.00

## Quality Scorecard

- **Overall Health**: 100.0%
- **Maintainability Index**: not measured
- **Complexity Score**: 100.0
- **Test Coverage**: N/A

## Files

### ./py/app.py

**File Complexity**: 3 | **Functions**: 2

- **Function**: `parse` [complexity: 3] [cognitive: 3] [big-o: O(1)] [satd: 0] [churn: low(1)]
- **Function**: `double` [complexity: 3] [cognitive: 3] [big-o: O(1)] [satd: 0] [churn: low(1)]

### ./src/lib.rs

**File Complexity**: 1 | **Functions**: 2

- **Function**: `parse` [complexity: 1] [cognitive: 0] [big-o: O(1)] [satd: 1 items] [churn: low(1)]
- **Function**: `double` [complexity: 1] [cognitive: 0] [big-o: O(1)] [satd: 1 items] [churn: low(1)]

### ./src/main.rs

**File Complexity**: 1 | **Functions**: 1

- **Function**: `main` [complexity: 1] [cognitive: 0] [big-o: O(1)] [satd: 0] [churn: low(1)]

### ./web/index.ts

**File Complexity**: 2 | **Functions**: 3

- **Function**: `parse` [complexity: 2] [cognitive: 2] [big-o: O(1)] [satd: 0] [churn: low(1)]
- **Function**: `anonymous` [satd: 0] [churn: low(1)]
- **Function**: `double` [complexity: 2] [cognitive: 2] [big-o: O(1)] [satd: 0] [churn: low(1)]
```

Note what each function line carries: cyclomatic complexity, cognitive
complexity, an inferred Big-O class, an SATD count, and a git churn bucket. The
`TODO` in `src/lib.rs` shows up as `[satd: 1 items]` on both functions in that
file — SATD is attributed per file, not per function.

`**Language**: rust` is the *detected primary* language. It does not mean the
Python and TypeScript were skipped; all four files are in the inventory.

Redirect, or use `-o`:

```bash
pmat context > project_context.txt
pmat context -o ctx.md
```

```
Analysis complete!
✅ Context written to: ctx.md
```

Scope to a subdirectory with `-p`:

```bash
pmat context -p ./py
```

```
# Project Context

**Language**: python
**Project Path**: ./py

## Project Structure

- **Total Files**: 1
- **Total Functions**: 2
- **Median Cyclomatic**: 3.00
- **Median Cognitive**: 3.00
```

Detection re-runs against the narrowed path — the primary language is now
`python`.

## Narrowing by Language

This is the real replacement for the `--include` / `--exclude` globs the old
chapter documented. `--language` restricts the analysis to a single language:

```bash
pmat context --language python
```

```
# Project Context

**Language**: python
**Project Path**: .

## Project Structure

- **Total Files**: 1
- **Total Functions**: 2
- **Median Cyclomatic**: 2.00
- **Median Cognitive**: 2.00
```

One file, not four. `--languages` takes a comma-separated list:

```bash
pmat context --languages rust,typescript
```

```
# Project Context

**Language**: rust
**Project Path**: .

## Project Structure

- **Total Files**: 3
- **Total Functions**: 6
- **Median Cyclomatic**: 2.00
- **Median Cognitive**: 2.00
```

Three files — the Python is excluded. An unsupported name is rejected loudly,
and the error doubles as the list of what `pmat` can parse:

```bash
pmat context --language klingon
```

```
Error: Language 'klingon' is not supported. Supported languages: rust, python, javascript, typescript, go, cpp, c, java, kotlin, swift, ruby, php, bash, sh, shell, wasm, wat, lean
```

Exit code 1.

`-t` / `--toolchain` also exists and is auto-detected when omitted. Unlike
`--language`, an unrecognised toolchain is **not** rejected — `pmat context -t
nonsense` exits 0 and analyses the project as if the flag were absent. Prefer
`--language`, which validates.

## Output Formats

`--format` takes `markdown` (default), `json`, `sarif` and `llm-optimized`.

### JSON

```bash
pmat context --format json > context.json
```

```json
{
  "version": "1.0",
  "project": {
    "language": "rust",
    "path": ".",
    "total_files": 4,
    "total_functions": 8,
    "overall_health": 100.0,
    "maintainability_index": null
  },
  "files": [
    {
      "path": "./py/app.py",
      "items": [
        {
          "name": "parse",
          "type": "function",
          "line": 1,
          "complexity": 3,
          "cognitive_complexity": 3
        },
        {
          "name": "double",
          "type": "function",
          "line": 8,
          "complexity": 3,
          "cognitive_complexity": 3
        }
      ]
    },
    {
      "path": "./web/index.ts",
      "items": [
        {
          "name": "parse",
          "type": "function",
          "line": 1,
          "complexity": 2,
          "cognitive_complexity": 2
        },
        {
          "name": "anonymous",
          "type": "function",
          "line": 1
        }
      ]
    }
  ]
}
```

(Abridged to two files; the real output lists all four.) Note that the JSON
carries **less** than the Markdown: no Big-O, no SATD count, no churn bucket,
and `maintainability_index` is `null`. Items `pmat` could not measure — the
TypeScript arrow function, listed as `anonymous` — simply omit the `complexity`
keys rather than reporting zero.

### SARIF

```bash
pmat context --format sarif > context.sarif
```

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "pmat",
          "informationUri": "https://github.com/paiml/pmat",
          "semanticVersion": "3.32.0"
        }
      },
      "invocations": [
        {
          "executionSuccessful": true,
          "toolConfigurationNotifications": []
        }
      ],
      "properties": {
        "language": "rust",
        "projectPath": "."
      },
      "results": []
    }
  ]
}
```

**`results` is empty**, on a project that has an SATD marker and four files of
measurable complexity. `pmat context --format sarif` emits a well-formed but
finding-free SARIF document. Do not wire it into a code-scanning upload
expecting annotations; use `pmat analyze satd` or `pmat report` and convert, or
check whether a later `pmat` has populated it.

### Markdown and llm-optimized

```bash
pmat context --format markdown > PROJECT_CONTEXT.md
pmat context --format llm-optimized
```

On this project `llm-optimized` is **byte-identical** to `markdown`:

```bash
diff <(pmat context --format markdown) <(pmat context --format llm-optimized)
```

produces no output. Treat `llm-optimized` as an alias until proven otherwise on
your own tree.

## The Remaining Two Flags

`--include-large-files` pulls in files over 500 KB, which are skipped by
default. `--skip-expensive-metrics` skips TDG and complexity analysis for speed:

```bash
pmat context --include-large-files
pmat context --skip-expensive-metrics
```

On a four-file project `--skip-expensive-metrics` produces output identical to
the default run — there is nothing expensive to skip. Its value is on large
trees; measure it on yours before assuming a speedup.

That is the complete option set:

| Flag | Meaning |
|------|---------|
| `-p, --project-path <PATH>` | Project path (default `.`) |
| `-o, --output <PATH>` | Write to a file instead of stdout |
| `--format <FORMAT>` | `markdown` (default), `json`, `sarif`, `llm-optimized` |
| `-t, --toolchain <TOOLCHAIN>` | Target toolchain; auto-detected if omitted, not validated |
| `--language <LANGUAGE>` | Single-language override; validated |
| `--languages <LANGUAGES>` | Comma-separated language list |
| `--include-large-files` | Include files over 500 KB |
| `--skip-expensive-metrics` | Skip TDG and complexity for speed |

## Integration Examples

### Feeding an LLM

There is no `--ai-format` and no `--prepend`. Compose with the shell:

```bash
pmat context --format llm-optimized -o ctx.md
{ echo "Analyze this codebase for security vulnerabilities:"; cat ctx.md; } | your-llm-cli
```

### In CI

```yaml
- name: Generate project context
  run: |
    pmat context --format json -o context.json
    pmat context --format markdown -o PROJECT_CONTEXT.md
- uses: actions/upload-artifact@v3
  with:
    name: pmat-context
    path: |
      context.json
      PROJECT_CONTEXT.md
```

### For an editor workspace

```bash
mkdir -p .vscode && pmat context --format json -o .vscode/pmat-context.json
```

The `mkdir -p` matters: `pmat context -o` does not create parent directories,
and shell redirection into a missing directory fails before `pmat` even starts.

## Managing Size

There is no `--max-tokens`, `--max-files` or `--smart-truncate`. The levers that
exist are:

1. **Narrow the path**: `pmat context -p ./src`
2. **Narrow the language**: `pmat context --language rust`
3. **Pick a leaner format**: JSON omits the Big-O, SATD and churn annotations
   and is smaller than the Markdown for the same project.
4. **Post-process**: the Markdown is one `### ./path` section per file, so
   `awk`/`csplit` can slice it however your context window needs.

## Troubleshooting

### `error: unexpected argument found`

You passed a positional path or one of the eighteen flags listed in the banner
at the top of this chapter. `pmat context --help` is the authority; it fits on
one screen.

### `Error: Language 'X' is not supported`

Exit 1, and the message lists every accepted value. Note that `--toolchain`
does not validate this way — a typo there is silently ignored.

### The SARIF file has no results

That is current behaviour, not a configuration problem. See the SARIF section.

### `.vscode/pmat-context.json: No such file or directory`

Shell redirection into a directory that does not exist. `mkdir -p` first.

## Best Practices

1. **Use `-p`, never a positional path.**
2. **Filter with `--language`/`--languages`**, not with globs — globs do not
   exist here.
3. **Choose the format for the consumer**: Markdown for humans and LLMs, JSON
   for tools. SARIF currently carries no findings.
4. **Check the primary language line.** `**Language**: rust` on a polyglot repo
   means "detected primary", not "only language analysed".
5. **Never point `pmat` at a tree containing secrets.** There is no exclude flag
   to rescue you; scope with `-p` instead.

## Summary

`pmat context` generates a structured, multi-language snapshot of a project for
humans, tools and LLMs. It has eight options, all documented above, and every
example in this chapter was executed against pmat 3.32.0.

Key takeaways:
- Path via `-p`; there is no positional argument.
- Filtering is by language or by path, not by glob.
- Markdown carries the richest annotations; JSON is leaner; SARIF is currently
  empty of results.
- `llm-optimized` was byte-identical to `markdown` in this test.

## Next Steps

- [Chapter 3: MCP Protocol](ch03-00-mcp-protocol.md) - Integrate PMAT with AI agents
- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Analyze code quality
