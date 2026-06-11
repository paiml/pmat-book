# Installing PMAT

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (1/1 methods)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 1 | `cargo install pmat` |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2026-06-11*  
*PMAT version: pmat 3.18.0*
<!-- DOC_STATUS_END -->

## Installation

PMAT is installed from [crates.io](https://crates.io/crates/pmat) with Cargo.
**This is the single supported install method** — one way, no scripts, no
hand-managed binaries.

```bash
cargo install pmat
```

**Prerequisites**: Rust 1.80+ installed via [rustup.rs](https://rustup.rs).

This installs the `pmat` binary to `~/.cargo/bin/pmat` (which rustup adds to your
`PATH`). It always builds the latest published version, optimized for your CPU,
on every platform.

### From source (latest unreleased)

To install the in-development version directly from a checkout:

```bash
git clone https://github.com/paiml/paiml-mcp-agent-toolkit
cd paiml-mcp-agent-toolkit
cargo install --path .
```

This uses the same Cargo path — it does **not** introduce a second install
location.

## Verification

```bash
# Check version
pmat --version
# Output: pmat 3.18.0

# Show help
pmat --help

# Quick test
echo "print('Hello PMAT')" > test.py
pmat analyze test.py
```

## Upgrading

```bash
cargo install pmat --force
```

## Pre-flight verification (`pmat verify`)

Before committing changes to a Rust project, run the CI-faithful pre-flight gate:

```bash
pmat verify --format json
```

It runs **format, complexity, satd, clippy, tests** fail-fast — the exact set CI
enforces — so you get a "green here ⇒ green in CI" signal before pushing. See
[Pre-commit Hooks Management](ch09-00-precommit-hooks.md).

## Feature Flags (Optional)

PMAT supports optional features enabled at compile time. They add functionality
and dependencies.

| Feature | Description | Dependencies Added |
|---------|-------------|-------------------|
| `git-lib` | Use libgit2 for git operations (faster, more features) | ~67 deps |
| `github-api` | GitHub API integration via octocrab | ~255 deps |
| `analytics-simd` | SIMD-accelerated analytics | platform-specific |

```bash
# Default (no optional features)
cargo install pmat

# With a feature
cargo install pmat --features git-lib

# Multiple features
cargo install pmat --features "git-lib,github-api"

# All features
cargo install pmat --all-features
```

Without `git-lib`, PMAT shells out to `git` (works on any system with git).
`github-api` enables repo-size checks and rate-limit awareness, and reads
`GITHUB_TOKEN` for authenticated requests.

## System Requirements

- **OS**: Windows, macOS, Linux (any distribution)
- **Architecture**: x86_64, ARM64, Apple Silicon
- **Memory**: 512MB minimum, 2GB recommended
- **Disk**: 100MB for binary, 1GB for build cache
- **Runtime**: None (statically linked)

## Troubleshooting

### Command not found

Ensure Cargo's bin directory is on your `PATH`:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

### Old version installed

```bash
cargo install pmat --force
```

## Next Steps

With PMAT installed, continue to [First Analysis](ch01-02-first-analysis-tdd.md).
