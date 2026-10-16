# Chapter 9: Enhanced Analysis Reports

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 16 | Executed against pmat 3.32.0; output pasted verbatim |
| ⚠️ Not Implemented | 4 | `--include-visualizations`, `-f html`, `-f pdf`, `-f dashboard` — `pmat` rejects these itself |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite.** Every example in the 2025 edition was written
> as `pmat report .` — a positional path. `pmat report` does not take a
> positional argument; clap rejects it with "unexpected argument found" and exits
> 2. **Thirty-nine of this chapter's forty commands failed on that single
> mistake.** The path goes in `-p` / `--project-path`.
>
> Three further corrections, because the old text asserted the opposite:
>
> - **`pmat report` reports self-admitted technical debt, and nothing else.** The
>   old chapter showed complexity findings, duplication clusters, dead-code
>   listings, maintainability indices and quality trends. None of those appear.
>   A function with a cyclomatic complexity over 20 produces zero defects from
>   this command; see "What the report actually contains".
> - **`--analyses` and `--confidence-threshold` parse but change nothing.** All
>   six `--analyses` values return byte-identical output, as do
>   `--confidence-threshold 0` and `100`. Measured, below.
> - **`--stream`, `--parallel-jobs`, `--max-file-size`, `--template`,
>   `--list-templates` and `--exclude` do not exist.** Those examples are gone
>   rather than guessed at.

## What `pmat report` Is

`pmat report` runs one analysis pass over a project and serialises the findings
as JSON, CSV, Markdown or plain text. It is a *format* command: the value it
adds over `pmat analyze satd` is the report envelope — metadata, a severity
histogram, hotspot ranking and a file index — not extra analysis.

Read the next section before you build anything on it.

## What the Report Actually Contains

The worked example below is a two-file Rust crate. `src/lib.rs` carries a `TODO`
on line 1, a `FIXME` on line 12, a function with six branches, and an unused
`pub fn unused_helper`:

```bash
pmat report -p .
```

```json
{
  "metadata": {
    "tool": "pmat",
    "version": "3.32.0",
    "generated_at": "2026-08-25T20:40:28.798408392Z",
    "project_root": ".",
    "total_files_analyzed": 1,
    "analysis_duration_ms": 14
  },
  "defects": [
    {
      "id": "SATD-0001",
      "severity": "low",
      "category": "technical_debt",
      "file_path": "./src/lib.rs",
      "line_start": 1,
      "line_end": null,
      "column_start": 1,
      "column_end": null,
      "message": "Requirement: TODO: validate the input range before shipping",
      "rule_id": "satd-requirement",
      "fix_suggestion": "Complete the missing requirement implementation",
      "metrics": {
        "debt_category": 0.0
      }
    },
    {
      "id": "SATD-0002",
      "severity": "high",
      "category": "technical_debt",
      "file_path": "./src/lib.rs",
      "line_start": 12,
      "line_end": null,
      "column_start": 9,
      "column_end": null,
      "message": "Defect: FIXME: this branch was never reviewed",
      "rule_id": "satd-defect",
      "fix_suggestion": "Fix the known defect or bug",
      "metrics": {
        "debt_category": 0.0
      }
    }
  ],
  "summary": {
    "total_defects": 2,
    "by_severity": {
      "high": 1,
      "low": 1
    },
    "by_category": {
      "TechnicalDebt": 2
    },
    "hotspot_files": [
      {
        "path": "./src/lib.rs",
        "defect_count": 2,
        "severity_score": 6.0
      }
    ]
  },
  "file_index": {
    "./src/lib.rs": [
      "SATD-0001",
      "SATD-0002"
    ]
  }
}
```

Two comment markers, two defects. Note what is *not* there:

- **No complexity finding**, though `classify` has six branches. Adding a
  function with cyclomatic complexity well over 20 to this crate changes the
  output not at all — still exactly the two SATD entries.
- **No dead-code finding**, though `unused_helper` is never called.
- **No duplication, no maintainability index, no trends.**

`by_category` has held only `TechnicalDebt` in every run. If you need
complexity, dead code or duplication, run `pmat analyze complexity`,
`pmat analyze dead-code` or `pmat analyze duplicates` — the report command does
not aggregate them.

**`total_files_analyzed` counts files that produced findings, not files
scanned.** The crate above has two `.rs` files and the field reads `1`. Adding a
`TODO` to `src/main.rs` makes it read `2`. Do not use it as a project size
metric.

## Choosing a Format

The default is JSON. Three shorthand flags cover the rest, and each has a long
form via `-f` / `--output-format` (aliased as `--format`):

```bash
pmat report -p .                    # JSON (default)
pmat report -p . --md               # same as -f markdown
pmat report -p . --csv              # same as -f csv
pmat report -p . --txt              # same as -f text
pmat report -p . -f json
```

### Markdown

```bash
pmat report -p . --md
```

````markdown
# Code Quality Report

Generated: 2026-08-25 20:40:28 UTC

## Executive Summary

- **Total Defects**: 2
- **Files Analyzed**: 1
- **Analysis Duration**: 13ms

### Severity Distribution

```
high     ██████████░░░░░░░░░░ 1 (50.0%)
low      ██████████░░░░░░░░░░ 1 (50.0%)
```

### Top 10 Hotspot Files

| Rank | File | Defects | Severity Score |
|------|------|---------|----------------|
| 1 | ./src/lib.rs | 2 | 6.0 |

## Detailed Findings

### Technical Debt (2 issues)

#### ./src/lib.rs:1-1

**Low** - Requirement: TODO: validate the input range before shipping

> 💡 **Suggestion**: Complete the missing requirement implementation

#### ./src/lib.rs:12-12

**High** - Defect: FIXME: this branch was never reviewed

> 💡 **Suggestion**: Fix the known defect or bug
````

The executive summary is always present. See "Flags that parse but do nothing"
for why `--include-executive-summary` cannot turn it off.

### CSV

```bash
pmat report -p . --csv
```

```
id,severity,category,file_path,line_start,line_end,message,rule_id,cyclomatic,cognitive
SATD-0001,low,TechnicalDebt,./src/lib.rs,1,,Requirement: TODO: validate the input range before shipping,satd-requirement,,
SATD-0002,high,TechnicalDebt,./src/lib.rs,12,,Defect: FIXME: this branch was never reviewed,satd-defect,,
```

The `cyclomatic` and `cognitive` columns are declared in the header and empty in
every row. They stay empty even for a deliberately hairy function — consistent
with the command emitting only SATD defects. Budget for them being blank if you
import this into a spreadsheet.

### Plain text

```bash
pmat report -p . --txt
```

```
CODE QUALITY REPORT
===================

Generated: 2026-08-25 20:40:38 UTC
Project: .
Total Defects: 2
Files Analyzed: 1

SEVERITY BREAKDOWN
------------------
high       1
low        1

CATEGORY BREAKDOWN
------------------
TechnicalDebt        2

TOP HOTSPOT FILES
-----------------
1. ./src/lib.rs (2 defects, score: 6.0)

DEFECTS
-------
[Low] Technical Debt - ./src/lib.rs:1
  Requirement: TODO: validate the input range before shipping
```

## Writing to a File

`-o` / `--output` takes a path. Without it the report goes to stdout and no file
is created:

```bash
pmat report -p . --md -o R.md
```

```
📄 Report saved to: R.md
```

Piping works as you would expect, since stdout carries only the report:

```bash
pmat report -p . -f json | gzip > report.json.gz
pmat report -p . -f json | jq '.summary.total_defects'
```

## Timing

`--perf` appends two lines after the report body:

```bash
pmat report -p . --perf
```

```
⏱️  perf: report completed in 13.3 ms
⏱️  perf: report throughput: 75 files/second
```

## Formats That `pmat` Rejects

`--output-format` advertises `html`, `pdf` and `dashboard`, and refuses all
three at runtime. Its own help text marks them "NOT IMPLEMENTED, rejected
(issue #672)":

```bash
pmat report -p . -f html
```

```
Error: --format html is not implemented for `pmat report` (it previously emitted plain text, not html). Supported formats: json, csv, markdown, text.
```

Exit code 1. `-f pdf` and `-f dashboard` produce the same message with the
format name substituted. This is the right behaviour — an earlier `pmat` quietly
wrote a plain-text file with an `.html` name — but it means you cannot generate
a browser-ready report from this command. Render the Markdown yourself.

`--include-visualizations` is rejected on the same grounds:

```bash
pmat report -p . --include-visualizations
```

```
Error: --include-visualizations is not implemented for `pmat report`: it changed nothing in json, csv, markdown or text, and the formats that could embed charts (html, pdf, dashboard) are not implemented either. Re-run without it.
```

Exit code 1.

## Flags That Parse but Do Nothing

These four are accepted by the argument parser and have no observable effect.
They are documented here so you do not build a pipeline on them; they are not
recommended.

**`--analyses`** advertises `complexity`, `dead-code`, `duplication`,
`technical-debt`, `big-o` and `all` (note the hyphens — the underscore spellings
in the old chapter are rejected). All six produce identical output:

```bash
for a in all complexity dead-code duplication technical-debt big-o; do
  pmat report -p . --analyses $a | jq -c '[.summary.total_defects, (.defects|map(.id))]'
done
```

```
[2,["SATD-0001","SATD-0002"]]
[2,["SATD-0001","SATD-0002"]]
[2,["SATD-0001","SATD-0002"]]
[2,["SATD-0001","SATD-0002"]]
[2,["SATD-0001","SATD-0002"]]
[2,["SATD-0001","SATD-0002"]]
```

Asking for `complexity` alone still returns the SATD defects; asking for
`technical-debt` alone returns no fewer. The filter is not applied.

**`--confidence-threshold`** takes 0–100 and filters nothing:

```bash
pmat report -p . --confidence-threshold 0   | jq '.summary.total_defects'   # 2
pmat report -p . --confidence-threshold 50  | jq '.summary.total_defects'   # 2
pmat report -p . --confidence-threshold 100 | jq '.summary.total_defects'   # 2
```

**`--include-executive-summary`** and **`--include-recommendations`** are bare
flags — `--include-executive-summary=false` is a parse error, and there is no
`--no-` counterpart. Passing them produces output identical to the default:

```bash
diff <(pmat report -p . --md) \
     <(pmat report -p . --md --include-executive-summary --include-recommendations)
```

The only difference is the `Analysis Duration` line, which varies run to run.
The executive summary and the fix suggestions are unconditional.

## Flags That Do Not Exist

The 2025 edition documented these. None is in `pmat report --help`, and each
exits 2 with "unexpected argument found":

| Documented | Reality |
|------------|---------|
| `--stream` | Never existed. There is no streaming mode. |
| `--parallel-jobs=N` | Never existed. |
| `--max-file-size=1MB` | Never existed. |
| `--template=executive` | Never existed. There is no report template system. |
| `--list-templates` | Never existed. |
| `--exclude="vendor/,target/"` | Never existed on `report`. Scope by pointing `-p` at a subdirectory. |

To scope the report, narrow the path:

```bash
pmat report -p ./src -f json
```

## Integration Patterns

### CI artifact

```bash
pmat report -p . --md -o QUALITY_REPORT.md
pmat report -p . -f json -o quality-report.json
```

### Failing a build on SATD

`pmat report` exits 0 whether it found defects or not, so the threshold is
yours to write:

```bash
count=$(pmat report -p . -f json | jq '.summary.total_defects')
high=$(pmat report -p . -f json | jq '[.defects[] | select(.severity=="high")] | length')
echo "$count defects, $high high-severity"
[ "$high" -eq 0 ] || { echo "high-severity technical debt present"; exit 1; }
```

### Spreadsheet export

```bash
pmat report -p . --csv -o quality-data.csv
```

Remember that `cyclomatic` and `cognitive` arrive empty.

## Summary

`pmat report` is a formatter over one analysis: self-admitted technical debt.
It writes JSON, CSV, Markdown or text, to stdout or to `-o`, and it tells you
honestly when a format is not implemented rather than faking one.

Key takeaways:
- **The path is `-p`, not positional.** This alone broke 39 of the old
  chapter's 40 examples.
- The defect list is SATD only. Complexity, dead code and duplication have their
  own `pmat analyze` subcommands.
- `total_files_analyzed` counts files with findings, not files scanned.
- `--analyses` and `--confidence-threshold` are inert; do not filter with them.
- `html`, `pdf`, `dashboard` and `--include-visualizations` exit 1 with an
  explanation. Render the Markdown yourself if you need a web page.
