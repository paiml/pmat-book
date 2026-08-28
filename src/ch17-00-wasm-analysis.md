# Chapter 17: WebAssembly Analysis and Security

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 14 | `analyze web-assembly` / `analyze assembly-script`, executed against pmat 3.32.0 |
| ⚠️ Not Implemented | 1 | `pmat analyze wasm` — feature-gated, exits 1 in the default build |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **⚠️ This chapter was rebuilt around a different command.**
>
> The 2025 edition documented `pmat analyze wasm` and nothing else. Every one of
> its 48 examples fails against pmat 3.32.0, for two separate reasons:
>
> - **`pmat analyze wasm` is behind the non-default `wasm-ast` Cargo feature.**
>   In a `cargo install pmat` build it exits 1 with `Error: WASM analysis
>   requires the 'wasm-ast' feature. Build with --features wasm-ast`. Its
>   entry in `pmat analyze --help` says so: `[NOT AVAILABLE in the default
>   build]`.
> - **Twenty-eight of its flags never existed**, in any build:
>   `--fail-on-high`, `--hot-functions-only`, `--threshold`,
>   `--memory-analysis`, `--type-safety-only`, `--establish-baseline`,
>   `--anchor`, `--baseline-anchors`, `--stream`, `--chunk-size`, `--parallel`,
>   `--workers`, `--ruchy-mode`, `--ruchy-security`, `--notebook-analysis`,
>   `--sandbox-validation`, `--assemblyscript-mode`, `--typescript-source`,
>   `--emscripten-mode`, `--c-source-mapping`, `--security-only`,
>   `--fast-mode`, `--fast`, `--incremental`, `--cache-previous`, `--priority`,
>   `--timeout`, `--validate-only`, `--calibrate-target`,
>   `--conservative-estimates`, `--memory-safety-only`. And `pmat analyze
>   wasm-multi` is not a subcommand.
>
> **pmat does ship working WebAssembly analysis** — in two commands the old
> chapter never mentioned, neither of them feature-gated:
> `pmat analyze web-assembly` and `pmat analyze assembly-script`. This chapter is
> now about those. Every example below was executed.
>
> The invented security taxonomy (buffer overflow, integer overflow, type
> confusion, control-flow hijacking), the profiling reports and the multi-anchor
> baseline system have been removed. `analyze web-assembly` finds one class of
> issue today, and this chapter shows it finding it.

## The Problem

A `.wasm` binary is opaque. You cannot grep it, its call graph is not obvious
from the source that produced it, and the properties you care about — how much
linear memory it reserves, whether that memory is bounded, how many indirect
calls it makes — are structural facts about the module rather than anything the
source language shows you.

`pmat analyze web-assembly` reads the module and reports those facts.

## The Worked Example

Every command below runs against this directory:

```
math.wat      a hand-written module: two functions, 1 memory page, no maximum
math.wasm     wat2wasm math.wat -o math.wasm
empty.wasm    the 8-byte minimal module (magic + version, no sections)
as/index.ts   two AssemblyScript functions
```

`math.wat`:

```wat
(module
  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add)
  (func $classify (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.lt_s
    if (result i32)
      i32.const -1
    else
      local.get $n
      i32.const 0
      i32.eq
      if (result i32)
        i32.const 0
      else
        i32.const 1
      end
    end)
  (memory 1)
  (export "add" (func $add))
  (export "classify" (func $classify)))
```

## Basic Analysis

`pmat analyze web-assembly` scans a directory — it takes `-p`, not a file
argument:

```bash
pmat analyze web-assembly
```

```
🔍 Analyzing WebAssembly files...
📁 Found 3 WebAssembly files
✅ Analyzed binary: ./empty.wasm
✅ Analyzed binary: ./math.wasm
✅ Parsed WAT: ./math.wat
⚠️  Not reported: ./math.wat — .wat text format is parsed for security/complexity checks only; metrics come from binary .wasm files
📊 Analysis complete in 0.00s
# WebAssembly Analysis Report

📁 **Files analyzed**: 2
⏱️  **Analysis time**: 0.00s

## Results

1. ./math.wasm — functions 2 / memory pages 1
2. ./empty.wasm — functions 0 / memory pages 0
```

Read the fourth line carefully. It found three files, analysed three, and
**reported two** — and it says so, naming the file it left out and why. `.wat`
text modules contribute to the security and complexity sections but not to the
metrics table, because the metrics are read from the binary encoding. A tool
that silently reported "2 files" would have been hiding a real asymmetry.

`empty.wasm` is the 8-byte minimal module. Zero functions and zero memory pages
is the correct answer for it, which is a useful control: if your own module
reports zeros, check that it is not truncated.

## Detailed Metrics

`-f full` expands each module into its section counts:

```bash
pmat analyze web-assembly -f full
```

```markdown
### ./math.wasm
- **Functions**: 2
- **Imports**: 0
- **Exports**: 2
- **Globals**: 0
- **Memory pages**: 1
- **Memory sections**: 1
- **Table sections**: 0
- **Indirect calls**: 0
- **Custom sections**: 0
- **Element segments**: 0
- **Data segments**: 0
- **Memory loads**: 0
- **Memory stores**: 0
- **Memory grows**: 0
- **Atomic ops**: 0
- **SIMD ops**: 0
- **Bulk ops**: 0
```

`--top-files N` trims the list (default 10, `0` for all):

```bash
pmat analyze web-assembly --top-files 1
```

```
## Results

1. ./math.wasm — functions 2 / memory pages 1
```

## Security Validation

`--security` adds a findings section. This is the real output — one finding, on
the module that declares unbounded memory:

```bash
pmat analyze web-assembly --security
```

```markdown
## Security (--security)

- [info/security] ./empty.wasm no issue found by the binary format/size rules
- [info/security] ./math.wasm no issue found by the binary format/size rules
- [Medium/ResourceExhaustion] ./math.wat line 22: linear memory declared with initial 1 page(s) and no maximum — the module can grow memory without bound
```

Three things worth noting, because they set expectations correctly:

1. **The finding is on the `.wat`, not the `.wasm`.** Line-level findings need
   the text format. If you ship only binaries, you get the format/size rules and
   nothing more — and the report says which rules it applied rather than
   printing a bare "no issues found".
2. **`info` lines are emitted for clean files.** A file that produced no finding
   is listed as such. Silence is not used to mean "clean".
3. **The taxonomy is small.** `ResourceExhaustion` on unbounded linear memory is
   what this ruleset detects. There is no buffer-overflow, integer-overflow,
   type-confusion or control-flow-hijack analysis in pmat 3.32.0, whatever the
   previous edition of this chapter listed.

## Memory and Complexity

`--memory-analysis` reports linear memory reservations:

```bash
pmat analyze web-assembly --memory-analysis
```

```markdown
## Memory (--memory-analysis)

- [info/linear-memory] ./empty.wasm declares no linear memory
- [info/linear-memory] ./math.wasm 1 memory section(s), 1 initial page(s) = 64 KiB reserved
```

`--complexity` reports cyclomatic and cognitive complexity, plus a gas estimate
— again only for text modules:

```bash
pmat analyze web-assembly --complexity
```

```markdown
## Complexity (--complexity)

- [info/text-module-complexity] ./math.wat cyclomatic 10, cognitive 10, max loop depth 1, estimated gas 10000
```

The three combine:

```bash
pmat analyze web-assembly --security --complexity --memory-analysis -f full
```

## Controlling What Is Scanned

`--include-binary` and `--include-text` both default to `true` and take an
explicit `=false`:

```bash
pmat analyze web-assembly --include-text=false
```

```
🔍 Analyzing WebAssembly files...
📁 Found 2 WebAssembly files
✅ Analyzed binary: ./empty.wasm
✅ Analyzed binary: ./math.wasm
📊 Analysis complete in 0.00s
```

Three files became two, and the `.wat` warning disappears with the `.wat`. Use
`--include-binary=false` for the mirror case. Note that excluding text modules
also removes every line-level security and complexity finding, per the section
above.

## Machine-Readable Output

```bash
pmat analyze web-assembly -f json
```

```json
{
      "file": "./empty.wasm",
      "metrics": {
        "memory_sections": 0,
        "table_sections": 0,
        "import_count": 0,
        "export_count": 0,
        "function_count": 0,
        "global_count": 0,
        "linear_memory_pages": 0,
        "indirect_calls": 0,
        "memory_operations": {
          "loads": 0,
          "stores": 0,
          "grows": 0,
          "atomic_ops": 0,
          "simd_ops": 0,
          "bulk_ops": 0
        },
        "instruction_histogram": {},
        "custom_sections": 0,
        "element_segments": 0,
        "data_segments": 0
      }
    }
  ],
  "security": null,
  "memory": null,
  "complexity": null,
  "performance": null
}
```

(Tail of the document.) The four trailing keys are `null` unless you asked for
the corresponding section — `"security": null` means "not requested", not "no
findings". Pass `--security` and it becomes an array.

SARIF, for a code-scanning upload:

```bash
pmat analyze web-assembly --security -f sarif
```

```json
{
          "ruleId": "wasm-analysis-finding",
          "kind": "fail",
          "level": "warning",
          "message": {
            "text": "ResourceExhaustion: line 22: linear memory declared with initial 1 page(s) and no maximum — the module can grow memory without bound"
          },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {
                  "uri": "./math.wat"
                }
              }
            }
          ],
          "properties": {
            "section": "Security (--security)",
            "severity": "Medium",
            "category": "ResourceExhaustion"
          }
        }
```

Unlike `pmat context --format sarif` (see [Chapter 2](ch02-00-getting-started.md)),
this SARIF **does** carry results.

Write to a file with `-o`:

```bash
pmat analyze web-assembly -f json -o wasm.json
```

```
📊 Analysis complete in 0.00s
📝 Results written to: wasm.json
```

`--perf` appends a timing line:

```bash
pmat analyze web-assembly --perf
```

```
⏱️  perf: analyze web-assembly completed in 3.3 ms
```

## AssemblyScript Source

`pmat analyze assembly-script` analyses the TypeScript-like source before it
becomes WASM:

```bash
pmat analyze assembly-script -p ./as
```

```
🔍 Analyzing AssemblyScript code...
📁 Found 1 AssemblyScript files
✅ Parsed: ./as/index.ts
📊 Analysis complete in 0.00s
# AssemblyScript Analysis Report

📁 **Files analyzed**: 1
⏱️  **Analysis time**: 0.00s

## Results

1. ./as/index.ts — cyclomatic 5 / cognitive 5
```

With the analysis sections:

```bash
pmat analyze assembly-script -p ./as --security --memory-analysis -f full
```

```markdown
### ./as/index.ts
- **Cyclomatic complexity**: 5
- **Cognitive complexity**: 5
- **Max loop depth**: 1
- **Memory pressure**: 1.00
- **Hot path score**: 10.00
- **Indirect call overhead**: 1.00
- **Estimated gas**: 5000


## Security (--security)

- [info/security] ./as/index.ts no issue found by the memory/resource rules

## Memory (--memory-analysis)

- [info/memory-sites] ./as/index.ts memory.grow: 0, raw load<T>(): 0, raw store<T>(): 0, changetype<>: 0, `new` allocation: 0
```

The memory section counts the AssemblyScript-specific escape hatches — raw
`load<T>()` / `store<T>()`, `changetype<>`, explicit `memory.grow` — which is
the right granularity for this language, where those are the operations that can
corrupt the heap.

`--wasm-complexity` is a documented no-op, and `pmat` says so on stderr rather
than pretending:

```bash
pmat analyze assembly-script -p ./as --wasm-complexity
```

```
note: --wasm-complexity is a no-op — cyclomatic and cognitive complexity are measured for every parsed file
```

Its `--help` entry reads `NO-OP: complexity is measured for every parsed file
already`. It changes nothing else in the output.

`--timeout` (default 30 seconds) caps parsing time; `-f`, `-o`, `--perf` and
`--top-files` behave as they do for `web-assembly`.

## The Feature-Gated Command

`pmat analyze wasm` is a third, deeper analyser — formal verification,
profiling, baseline comparison — that is not compiled into the published binary:

```bash
pmat analyze wasm math.wasm --security
```

```
Error: WASM analysis requires the 'wasm-ast' feature. Build with --features wasm-ast
```

Exit code 1, for every combination of `--security`, `--profile`, `--verify` and
`--baseline`. The `wasm-ast` feature is real in the published crate — `cargo add
--dry-run pmat --features wasm-ast` resolves against 3.32.0 — so:

```bash
cargo install pmat --features wasm-ast
```

is the supported route. That build has not been exercised for this chapter and
no output from it is reproduced here. Its genuine flags, per `--help`, are
`--security`, `--profile`, `--verify`, `--baseline <FILE>`, `-f
<summary|detailed|json|sarif>`, `-o`, and `--verbose`. Everything else the
previous edition attached to it was invented.

## Integration

### CI gate on WASM security

`analyze web-assembly` exits 0 whether or not it found something, so gate on the
JSON:

```bash
pmat analyze web-assembly --security -f json -o wasm.json
python3 - <<'PY'
import json, sys
d = json.load(open("wasm.json"))
findings = [f for f in (d.get("security") or []) if not str(f).startswith("info")]
print(f"{len(findings)} non-info security finding(s)")
sys.exit(1 if findings else 0)
PY
```

### Code scanning

```bash
pmat analyze web-assembly --security -f sarif -o wasm-security.sarif
```

Upload `wasm-security.sarif` with `github/codeql-action/upload-sarif`.

## Troubleshooting

### "Found N files, Files analyzed: M" with M < N

Expected when the directory holds `.wat` files. They are parsed for security and
complexity but excluded from the metrics table; the run prints a `⚠️ Not
reported:` line naming each one.

### No line numbers in security findings

Line-level findings come from `.wat` text modules. Binary-only scans get the
format and size rules, which have no line information.

### `"security": null` in the JSON

You did not pass `--security`. `null` means "section not requested"; an empty
array would mean "requested, nothing found".

### `Error: WASM analysis requires the 'wasm-ast' feature`

You invoked `pmat analyze wasm`. Use `pmat analyze web-assembly`, which is
compiled in, or reinstall with `--features wasm-ast`.

## Summary

`pmat` has three WebAssembly commands. Two work in every install:

| Command | Input | Gated? |
|---------|-------|--------|
| `pmat analyze web-assembly` | `.wasm` and `.wat` in a directory | No |
| `pmat analyze assembly-script` | AssemblyScript `.ts` source | No |
| `pmat analyze wasm` | one `.wasm` file | **Yes** — needs `--features wasm-ast` |

Key takeaways:
- `web-assembly` and `assembly-script` take `-p <directory>`, not a file.
- Metrics come from binary modules; line-level security and complexity findings
  come from `.wat` text modules. The report tells you which files it left out.
- The security ruleset finds unbounded linear memory. It is not a
  memory-safety verifier.
- `null` section keys in the JSON mean "not requested".
- `pmat analyze wasm` exits 1 in a `cargo install pmat` build.
