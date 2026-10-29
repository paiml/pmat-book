# Chapter 21: Templates and Scaffolding

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 24 | Executed against pmat 3.32.0; output pasted verbatim |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite.** The 2025 edition documented a template
> registry that `pmat` does not have. Three corrections dominate:
>
> - **There are nine templates, not a catalogue.** They are Makefile, README and
>   .gitignore for three toolchains (`rust`, `deno`, `python-uv`). There is no
>   `rust/cli` application template, no `python/api`, no `rust-api`, no
>   `python-ml`, no `polyglot`. Every `pmat generate rust cli` in the old
>   chapter failed with `Error: Invalid template URI: template://rust/cli`,
>   because that URI names nothing. Run `pmat list` — the full inventory fits on
>   one screen and is printed below.
> - **`pmat scaffold project` takes a `<TOOLCHAIN>` positional and `-t` /
>   `-p`.** It has no `--name`, `--path`, `--git`, `--interactive`, `--config`,
>   `--languages`, `--author`, `--force` or `--backup`. The old chapter used
>   all nine.
> - **Six scaffold subcommands never existed**: `create-template`,
>   `publish-template`, `compose`, `cache-warm`, `cache-clear`, `cache-stats`,
>   `update-registry`. There is no template cache and no registry to publish to.
>
> Also removed: `pmat list --refresh`, `pmat generate --dry-run`, `pmat generate
> --use-defaults`, `pmat generate custom --template-path`, and `pmat
> quality-gate --strict` (the gate is strict by default in 3.32.0; the flag that
> exists is `--report-only`).

## The Inventory

Start here. `pmat list` prints everything the binary ships:

```bash
pmat list
```

```
┌──────────────────────────────────────────┬───────────┬───────────┬──────────────────────────────────────────────────────────────┐
│                   Name                   │ Toolchain │ Category  │                         Description                          │
├──────────────────────────────────────────┼───────────┼───────────┼──────────────────────────────────────────────────────────────┤
│ Rust CLI Makefile                        │ rust      │ Makefile  │ Makefile for building Rust command-line applications with ca... │
│ Rust CLI README                          │ rust      │ Readme    │ README template for Rust command-line applications           │
│ Rust CLI .gitignore                      │ rust      │ Gitignore │ Gitignore template for Rust CLI projects                     │
│ Deno TypeScript CLI Application Makefile │ deno      │ Makefile  │ Makefile for Deno TypeScript CLI applications                │
│ Deno CLI Application README              │ deno      │ Readme    │ README template for Deno CLI applications                    │
│ Deno CLI Application .gitignore          │ deno      │ Gitignore │ .gitignore template for Deno projects                        │
│ Python UV CLI Application Makefile       │ python-uv │ Makefile  │ Makefile for Python CLI applications using UV package manage... │
│ Python UV CLI Application README         │ python-uv │ Readme    │ README template for Python UV CLI applications               │
│ Python UV CLI Application .gitignore     │ python-uv │ Gitignore │ .gitignore template for Python UV projects                   │
└──────────────────────────────────────────┴───────────┴───────────┴──────────────────────────────────────────────────────────────┘
```

Nine templates, three per toolchain. This is a **project-hygiene** generator —
build file, readme, ignore file — not an application scaffolder. Nothing here
writes `main.rs` or a web server.

The JSON form carries the URIs and, crucially, each template's parameter list:

```bash
pmat list --format json
```

```json
[
  {
    "uri": "template://makefile/rust/cli",
    "name": "Rust CLI Makefile",
    "description": "Makefile for building Rust command-line applications with cargo",
    "toolchain": {
      "type": "rust",
      "cargo_features": []
    },
    "category": "makefile",
    "parameters": [
      {
        "name": "project_name",
        "param_type": "string",
        "required": true,
        "default_value": null,
        "validation_pattern": null,
        "description": "The name of the Rust project"
      },
      {
        "name": "has_tests",
        "param_type": "boolean",
        "required": false,
        "default_value": "true",
        "validation_pattern": null,
        "description": "Whether the project has tests"
      }
    ]
  }
]
```

(Abridged.) `--format yaml` and `--verbose` also work. Filter with
`--toolchain` or `--category`:

```bash
pmat list --toolchain rust
pmat list --category makefile
```

```
┌─────────────────────┬───────────┬───────────┬───────────────────────────────────
│        Name         │ Toolchain │ Category  │            Description
├─────────────────────┼───────────┼───────────┼───────────────────────────────────
│ Rust CLI Makefile   │ rust      │ Makefile  │ Makefile for building Rust comm...
│ Rust CLI README     │ rust      │ Readme    │ README template for Rust comman...
│ Rust CLI .gitignore │ rust      │ Gitignore │ Gitignore template for Rust CLI...
```

The nine URIs, in full:

```
template://makefile/rust/cli        template://readme/rust/cli        template://gitignore/rust/cli
template://makefile/deno/cli        template://readme/deno/cli        template://gitignore/deno/cli
template://makefile/python-uv/cli   template://readme/python-uv/cli   template://gitignore/python-uv/cli
```

## Searching

```bash
pmat search "cli"
```

```
 1. template://gitignore/rust/cli (score: 8.00)
    Matches: name: Rust CLI .gitignore, description
 2. template://makefile/deno/cli (score: 8.00)
    Matches: name: Deno TypeScript CLI Application Makefile, description
 3. template://readme/deno/cli (score: 8.00)
    Matches: name: Deno CLI Application README, description
```

`--limit` and `--toolchain` narrow it:

```bash
pmat search "makefile" --limit 2
pmat search "cli" --toolchain deno
```

```
 1. template://makefile/deno/cli (score: 8.00)
    Matches: name: Deno TypeScript CLI Application Makefile, description
 2. template://readme/deno/cli (score: 8.00)
    Matches: name: Deno CLI Application README, description
 3. template://gitignore/deno/cli (score: 5.00)
    Matches: name: Deno CLI Application .gitignore
```

## Generating One File

`pmat generate <CATEGORY> <TEMPLATE>` — two positionals. The category is the
first URI segment (`makefile`, `readme`, `gitignore`) and the template is the
rest (`rust/cli`). Getting this pair backwards is what produced the old
chapter's `Invalid template URI` errors.

```bash
pmat generate makefile rust/cli -p project_name=my-cli
```

```makefile
# my-cli - Rust CLI Binary Makefile
# Generated by Pragmatic AI Labs MCP Agent Toolkit (pmat)

.PHONY: all check format lint test bench build build-release run clean install help

# Default target: run all checks and build
all: format check lint test build

# Type check the code
check:
	cargo check

# Format code with rustfmt
format:
	cargo fmt --all

# Lint with clippy
lint:
	cargo clippy --all-targets -- -D warnings
```

Output goes to stdout. `-o` writes a file, and `--create-dirs` makes the
parents:

```bash
pmat generate readme rust/cli -p project_name=my-cli -p description="A demo CLI" -o out/nested/README.md --create-dirs
```

```
✅ Generated: out/nested/README.md
```

```markdown
# my-cli

A demo CLI
```

### Missing parameters name themselves

Omit a required parameter and `pmat` tells you the flag to add, not just that
something is wrong:

```bash
pmat generate makefile rust/cli
```

```
Error: Parameter validation failed: project_name - required parameter(s) missing. Add:
  -p project_name=<value>  (The name of the Rust project)
```

This is the fastest way to discover a template's parameters — faster than the
JSON. The README template needs two:

```
Error: Parameter validation failed: description - required parameter(s) missing. Add:
  -p description=<value>  (A brief description of the project)
```

For the record, `template://readme/rust/cli` accepts eleven parameters, nine of
them optional with defaults: `project_name` (required), `description`
(required), `features` (`[]`), `rust_version` (`1.75`), `install_command`
(`cargo install --path .`), `usage_example`, `prerequisites` (`[]`),
`build_command` (`make build`), `test_command` (`make test`), `license` (`MIT`),
`author`.

## Validating Before Generating

`pmat validate <URI>` checks a parameter set without writing anything. The
argument is the **full URI**, not a category/template pair:

```bash
pmat validate template://makefile/rust/cli -p project_name=my-cli
```

```
✅ All parameters valid
```

```bash
pmat validate template://makefile/rust/cli
```

```
❌ Validation errors:
  - project_name: Required parameter missing
```

`pmat validate` exits 0 when the parameter set is complete and 1 when it is
not, so it is usable directly as a gate:

```bash
pmat validate template://makefile/rust/cli -p project_name=my-cli && echo "safe to generate"
```

## Scaffolding a Whole Project

`pmat scaffold project <TOOLCHAIN>` writes all three files for a toolchain at
once. The toolchain is a positional; templates are selected with `-t` (repeat
it) and parameters with `-p`:

```bash
pmat scaffold project rust -t makefile -t readme -t gitignore -p project_name=my-cli -p description="A demo CLI"
```

```
✅ Created: my-cli/README.md
✅ Created: my-cli/.gitignore
✅ Created: my-cli/Makefile

🚀 Project scaffolded successfully!
```

```
my-cli/.gitignore
my-cli/Makefile
my-cli/README.md
```

**The output directory is `project_name`**, not a `--path` flag — there is no
`--path` on this command. Omit `-t` entirely and you get all three anyway:

```bash
pmat scaffold project rust -p project_name=demo2 -p description=d
```

```
✅ Created: demo2/Makefile
✅ Created: demo2/README.md
✅ Created: demo2/.gitignore

🚀 Project scaffolded successfully!
```

`--parallel <N>` sets the parallelism level; it defaults to the machine's core
count. Valid toolchains are `rust`, `deno` and `python-uv` — the same three
`pmat list` shows.

## Scaffolding an MCP Agent

`pmat scaffold agent` is a different generator: it writes a complete, buildable
Rust MCP agent, not a config file. Four templates:

```bash
pmat scaffold list-templates
```

```
📦 Available Agent Templates:

  • calculator - Deterministic calculator agent with verified operations
  • hybrid - Hybrid agent with deterministic core and probabilistic wrapper
  • mcp-server - MCP tool server with async handlers and resource management
  • state-machine - State machine agent with transitions and invariants

Total: 4 templates available
```

Preview with `--dry-run`:

```bash
pmat scaffold agent -n code_analyzer -t mcp-server --dry-run
```

```
🔍 Dry run mode - would generate the following:
  Agent: code_analyzer
  Template: MCPToolServer
  Quality: Strict
  Features: 0 enabled
  Output: code_analyzer
```

Then create it:

```bash
pmat scaffold agent -n code_analyzer -t mcp-server -o ./agent_out
```

The command prints nothing on success and exits 0. The tree it wrote:

```
agent_out/README.md
agent_out/Cargo.toml
agent_out/src/main.rs
agent_out/src/agent/mod.rs
agent_out/src/agent/handlers.rs
agent_out/src/quality/mod.rs
agent_out/src/quality/invariants.rs
agent_out/src/quality/validators.rs
agent_out/tests/integration.rs
agent_out/tests/deterministic.rs
agent_out/.pmat/agent.toml
agent_out/.pmat/quality-gates.toml
```

### The name must be a Rust identifier

```bash
pmat scaffold agent -n code-analyzer -t mcp-server
```

```
Error: Agent name must be alphanumeric with underscores only
```

Exit code 1. A hyphen is rejected because the name becomes a crate and module
name. Use `code_analyzer`.

Other options: `-l` / `--quality` (`standard`, `strict` (default), `extreme`),
`-f` / `--features` (comma-separated), `--force` to overwrite an existing
directory, `-i` / `--interactive` for guided creation, and
`--deterministic-core <SPEC>` for hybrid agents.

### Validating an agent template

```bash
pmat scaffold validate-template nope.yaml
```

```
🔍 Validating template: nope.yaml
❌ Template validation failed:
   Template not found: nope.yaml
```

The path argument is a template *file*, not a template name.

## Claude Code Sub-Agents

`pmat scaffold` also generates Claude Code sub-agent definitions:

```bash
pmat scaffold list-subagents
```

```
Available PMAT Sub-Agents

  ✓ MVP complexity-analyst - Expert in cyclomatic and cognitive complexity analysis, suggests refactorings
    Tools: analyze_complexity, analyze_cognitive_complexity

  ✓ MVP mutation-tester - Mutation testing specialist with ML prediction and test improvement suggestions
    Tools: mutation_test, mutation_predict, equivalent_detector

  ✓ MVP satd-detector - Technical debt identifier tracking TODO, FIXME, and HACK comments
    Tools: analyze_satd, analyze_context

  ✓ MVP dead-code-eliminator - Unused code removal specialist identifying safe-to-delete code
    Tools: analyze_dead_code, analyze_imports
```

The related subcommands are `create-subagent`, `create-all-subagents`,
`validate-subagent`, `show-tool-mapping` and `export-tool-mapping`.

## Scaffolding a WASM Project

```bash
pmat scaffold wasm -n my_wasm_project
```

Options: `-w` / `--framework` (`wasm-labs` (default), `pure-wasm`), `-f` /
`--features`, `-l` / `--quality`, `-o` / `--output`, `--force`.

## Checking What You Generated

The generated project is ordinary code; analyse it like any other:

```bash
pmat analyze complexity --path .
pmat quality-gate
```

There is no `pmat quality-gate --strict`. Since 3.32.0 the gate exits non-zero
on a blocking violation by default, so no flag is needed to make it strict.

On a freshly scaffolded project it will fail, and the reason is worth reading:

```
Quality Gate: FAILED
Total violations: 1
Blocking violations: 1

## coverage (1 violations)
  - project - Code coverage was NOT measured (no coverage report at .pmat/coverage-cache.json or .pmat-metrics/coverage.json), so the 80.0% minimum is unverified — this gate does not cover coverage
    Factors: coverage: not measured

❌ Quality gate FAILED
```

"Not measured" is treated as a blocking violation rather than a pass — the gate
refuses to let an unmeasured 80% minimum read as a met one. Run your coverage
tool first, or scope the run with `--checks`.
`--fail-on-violation` is still accepted and `pmat` says on stderr that it does
nothing:

```
note: --fail-on-violation is a no-op since 3.32.0 — blocking violations exit non-zero by default; pass --report-only for the old report-and-exit-0 behaviour
```

Use `--report-only` (alias `--no-fail`) for the report-and-exit-0 behaviour.

## Complete Command Reference

| Command | Positionals | Key options |
|---------|-------------|-------------|
| `pmat list` | — | `--format json\|yaml`, `--toolchain`, `--category`, `--verbose` |
| `pmat search <QUERY>` | query | `--limit`, `--toolchain` |
| `pmat generate <CATEGORY> <TEMPLATE>` | e.g. `makefile rust/cli` | `-p k=v` (repeat), `-o`, `--create-dirs` |
| `pmat validate <URI>` | e.g. `template://makefile/rust/cli` | `-p k=v` |
| `pmat scaffold project <TOOLCHAIN>` | `rust`\|`deno`\|`python-uv` | `-t` (repeat), `-p k=v`, `--parallel` |
| `pmat scaffold agent` | — | `-n`, `-t`, `-o`, `-l`, `-f`, `--force`, `--dry-run`, `-i` |
| `pmat scaffold wasm` | — | `-n`, `-w`, `-o`, `-l`, `-f`, `--force` |
| `pmat scaffold list-templates` | — | — |
| `pmat scaffold validate-template <PATH>` | template file | — |
| `pmat scaffold list-subagents` | — | — |

## Troubleshooting

### `Error: Invalid template URI: template://rust/cli`

You passed the toolchain as the category. The category is `makefile`, `readme`
or `gitignore`; the template is `rust/cli`. Run `pmat list --format json` and
read the `uri` field.

### `error: unexpected argument found` on `scaffold project`

You used `--name` or `--path`. The toolchain is positional, the project name is
`-p project_name=…`, and the output directory is that name.

### `Agent name must be alphanumeric with underscores only`

Hyphens are rejected; the name becomes a Rust crate name.

### `pmat quality-gate --strict` is rejected

That flag never existed. The gate is strict by default in 3.32.0; use
`--report-only` if you want findings without a non-zero exit.

## Summary

pmat's template system is small and honest about its size: nine project-hygiene
templates across three toolchains, plus two code generators (`scaffold agent`,
`scaffold wasm`) that write complete, buildable trees.

Key takeaways:
- `pmat list` is the whole inventory. Trust it over any prose, including this
  chapter.
- `generate` takes `<CATEGORY> <TEMPLATE>`; `validate` takes a full
  `template://` URI; `scaffold project` takes a bare toolchain.
- Missing parameters print the exact `-p` flag to add.
- There is no registry, no cache, no template composition, and no `--dry-run` on
  `generate` (only on `scaffold agent`).
