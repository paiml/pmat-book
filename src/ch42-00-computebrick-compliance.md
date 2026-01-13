# Chapter 42: ComputeBrick Compliance

The `pmat comply` command provides comprehensive support for ComputeBrick projects—WebGPU/WGSL shader generation systems that produce GPU compute code from Rust type definitions. This chapter covers the compliance checking, enforcement hooks, and defect detection algorithms.

## Overview

ComputeBrick compliance integrates Toyota Production System (TPS) principles with static analysis:

- **CB-001 to CB-022**: Defect pattern detection in WGSL shaders
- **Pre-push hooks**: Automatic compliance validation before push
- **Probar integration**: GUI coverage enforcement >= 80%
- **Jidoka principle**: Block merge on P0 defects

## Quick Start

```bash
# Check ComputeBrick compliance
pmat comply check

# Install enforcement hooks (pre-commit + pre-push)
pmat comply enforce -y

# Generate compliance report
pmat comply report --format markdown
```

## Defect Taxonomy

### Critical Defects (P0)

| ID | Pattern | Description |
|----|---------|-------------|
| CB-001 | WGPU_NO_BOUNDS_CHECK | `global_invocation_id` used without bounds validation |
| CB-002 | WGSL_BARRIER_DIVERGENCE | `workgroupBarrier()` unreachable from some threads |
| CB-003 | TILE_DIMENSION_MISMATCH | Tile size exceeds tensor dimensions |
| CB-004 | SHARED_MEM_OVERFLOW | Workgroup shared memory exceeds 16KB limit |

### Performance Defects (P1)

| ID | Pattern | Description |
|----|---------|-------------|
| CB-010 | WGPU_SUBOPTIMAL_WORKGROUP | Workgroup size not multiple of 32 (warp) |
| CB-011 | WGSL_REDUNDANT_BARRIER | Barrier without preceding shared memory write |
| CB-012 | LOW_VECTORIZATION_RATIO | <50% of operations use vector types |

### Code Quality Defects (P2)

| ID | Pattern | Description |
|----|---------|-------------|
| CB-020 | UNSAFE_NO_SAFETY_COMMENT | `unsafe` block without `// SAFETY:` comment |
| CB-021 | MISSING_TARGET_FEATURE | SIMD intrinsics without `#[target_feature]` |
| CB-022 | EXCESSIVE_BARRIERS | >4 barriers per kernel |

## Detection Algorithms

### CB-001: Bounds Check Detection

The detector identifies WGSL shaders using `global_invocation_id` without bounds validation:

```wgsl
// ❌ UNSAFE PATTERN (CB-001):
@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let gid = global_id.x;
    output[gid] = input[gid];  // No bounds check!
}

// ✅ SAFE PATTERN:
@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let gid = global_id.x;
    if (gid >= arrayLength(&input)) { return; }  // Bounds check
    output[gid] = input[gid];
}
```

### CB-002: Barrier Divergence Detection

Detects `workgroupBarrier()` inside conditional blocks where not all threads can reach:

```wgsl
// ❌ UNSAFE PATTERN (CB-002):
@compute @workgroup_size(64)
fn main(@builtin(local_invocation_id) local_id: vec3<u32>) {
    if (local_id.x == 0u) {
        shared_data[0] = compute();
        workgroupBarrier();  // DANGER: Only thread 0 reaches!
    }
}

// ✅ SAFE PATTERN:
@compute @workgroup_size(64)
fn main(@builtin(local_invocation_id) local_id: vec3<u32>) {
    if (local_id.x == 0u) {
        shared_data[0] = compute();
    }
    workgroupBarrier();  // Safe: All threads reach this
    let val = shared_data[0];
}
```

## Enforcement Hooks

### Pre-Push Hook

The pre-push hook validates ComputeBrick compliance before push:

```bash
# Installed by: pmat comply enforce -y

# What it checks:
# 1. ComputeBrick compliance via pmat comply check
# 2. Probar GUI coverage >= 80% (if probador installed)
# 3. Missing [compute-brick] config in .pmat-gates.toml
```

### Pre-Commit Hook

The pre-commit hook ensures active work tickets:

```bash
# Blocks commits without active work ticket
# Use: pmat work start <ticket-id> before committing
```

## Configuration

### .pmat-gates.toml

```toml
[compute-brick]
enabled = true
min_score = 70
block_on_p0 = true
require_probar_coverage = 80

[compute-brick.checks]
bounds_check = "hard"      # Block on CB-001
barrier_safety = "hard"    # Block on CB-002
tile_validation = "hard"   # Block on CB-003
workgroup_limit = "hard"   # Block on CB-004
vectorization = "soft"     # Warn on CB-012
```

## CI/CD Integration

### GitHub Actions

```yaml
name: ComputeBrick Compliance

on: [push, pull_request]

jobs:
  comply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Check Compliance
        run: pmat comply check --strict

      - name: Generate Report
        run: pmat comply report --format markdown --output compliance.md

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: compliance-report
          path: compliance.md
```

## Toyota Way Principles

The ComputeBrick compliance system embodies Toyota Production System principles:

| Principle | Application |
|-----------|-------------|
| **Jidoka** | Automatic stop on P0 defect detection |
| **Poka-Yoke** | Static analysis prevents common shader errors |
| **Kaizen** | Track defect metrics over time with score trends |
| **Genchi Genbutsu** | Analyze actual WGSL/PTX artifacts |
| **Hansei** | 5-Why root cause analysis for each defect |

## Probar Integration

For projects using the probar testing framework:

```bash
# Check GUI coverage
probador playbook --validate --min-coverage 80

# Generate coverage report
probador playbook --coverage --output coverage.json
```

The pre-push hook automatically checks probar coverage if `probador` is installed.

## Specification Reference

Full specification: `docs/specifications/compute-brick-support.md`

Based on:
- Popper, K. R. (1959). *The Logic of Scientific Discovery*
- Liker, J. K. (2004). *The Toyota Way*
- PROBAR-SPEC-009-P8 (ComputeBrick paradigm specification)
