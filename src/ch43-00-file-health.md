# Chapter 43: File Health and Max-Lines Enforcement (CB-040)

The File Health system enforces code maintainability by preventing excessively large files. Based on Toyota Production System principles and peer-reviewed research, this feature ensures:

- **No file exceeds 500 lines** (new files)
- **Existing files cannot grow** (ratchet mechanism)
- **Test-to-Lines Ratio (TLR)** scaling requirements

## The Problem

Large files violate the Single Responsibility Principle and become:
- Untestable (cognitive overload)
- Unmaintainable (merge conflicts)
- Error-prone (complexity hotspots)

Research shows files over 500 lines have 2.4x higher defect rates (Nagappan et al., IEEE TSE 2006).

## Quick Start

```bash
# Check file health in your project
pmat comply check

# View detailed file health report
pmat comply check --verbose
```

## File Health Metrics

### 1. File Size Classes

| Class | Lines | Risk Level |
|-------|-------|------------|
| Optimal | 0-200 | Low |
| Acceptable | 201-500 | Medium |
| Warning | 501-1000 | High |
| Critical | 1001-2000 | Very High |
| Emergency | 2000+ | Extreme |

### 2. Test-to-Lines Ratio (TLR)

TLR requirements scale with file size:

| File Size | Required TLR | Rationale |
|-----------|--------------|-----------|
| < 100 lines | 0.3 | Simple code needs fewer tests |
| 100-300 lines | 0.5 | Moderate complexity |
| 300-500 lines | 0.8 | Complex code needs more tests |
| 500-1000 lines | 1.2 | High complexity penalty |
| > 1000 lines | 1.5 | Critical files need extensive tests |

### 3. File Health Score Formula

```
Health Score = (Size Score × 0.30) + (TLR Score × 0.40) +
               (Complexity Score × 0.20) + (Stability Score × 0.10)

Where:
- Size Score: 100 - (lines / max_lines × 100)
- TLR Score: min(100, actual_tlr / required_tlr × 100)
- Complexity Score: 100 - (avg_complexity / threshold × 100)
- Stability Score: 100 - (churn_30d / 10 × 100)
```

### 4. Health Grades

| Grade | Score Range | Status |
|-------|-------------|--------|
| A+ | 95-100 | Excellent |
| A | 90-94 | Great |
| B | 80-89 | Good |
| C | 70-79 | Acceptable |
| D | 60-69 | Needs Work |
| F | < 60 | Critical |

## Pre-commit Hook Enforcement

The pre-commit hook enforces two rules:

### Rule 1: New Files Must Be < 500 Lines

```bash
# New file check
if [ "$LINES" -gt "$MAX_LINES_NEW" ]; then
    echo "❌ NEW file $file has $LINES lines (max: $MAX_LINES_NEW)"
    exit 1
fi
```

### Rule 2: Existing Files Cannot Grow (Ratchet)

```bash
# Ratchet mechanism - Toyota Way Kaizen
BASELINE=$(git show HEAD:"$file" 2>/dev/null | wc -l || echo 0)
if [ "$LINES" -gt "$BASELINE" ] && [ "$BASELINE" -gt 0 ]; then
    echo "❌ RATCHET: $file grew from $BASELINE to $LINES lines"
    echo "   Files can only shrink or stay the same (Toyota Way: Kaizen)"
    exit 1
fi
```

## Installing the Pre-commit Hook

```bash
# Install PMAT hooks (includes file health check)
pmat hooks install

# Verify hook is installed
cat .git/hooks/pre-commit | grep "File Health"
```

## Compliance Check Output

When you run `pmat comply check`, the file health section shows:

```
📊 File Health Summary
├── 60 files >2000 lines (CRITICAL)
├── 117 files >1000 lines
├── 459 files >500 lines
├── Average Health Score: 73%
└── Grade: C

Priority Files for Refactoring:
1. analysis_utilities.rs (12,087 lines) - EMERGENCY
2. deep_context.rs (7,211 lines) - EMERGENCY
3. commands.rs (6,273 lines) - EMERGENCY
4. tools.rs (6,111 lines) - EMERGENCY
```

## Toyota Way Principles

### Jidoka (Built-in Quality)
Quality is built into the process through automated enforcement at commit time.

### Kaizen (Continuous Improvement)
The ratchet mechanism ensures files never grow larger - only improvement is allowed.

### Muda (Waste Elimination)
Large files represent waste: duplicated logic, dead code, and cognitive overhead.

### Genchi Genbutsu (Go and See)
File health metrics are based on actual measurements, not estimates.

## Refactoring Strategies

When a file exceeds limits, use these strategies:

### 1. Extract Module
```rust
// Before: large_file.rs (2000+ lines)
mod validation;
mod processing;
mod reporting;

// After: validation.rs, processing.rs, reporting.rs (~500 lines each)
```

### 2. Extract Trait
```rust
// Before: monolithic struct
impl LargeService {
    fn validate(&self) { ... }
    fn process(&self) { ... }
    fn report(&self) { ... }
}

// After: focused traits
trait Validator { fn validate(&self); }
trait Processor { fn process(&self); }
trait Reporter { fn report(&self); }
```

### 3. Extract Constants
```rust
// Before: inline constants throughout
const TIMEOUT: u64 = 30;
const MAX_RETRIES: u32 = 3;

// After: constants module
mod constants {
    pub const TIMEOUT: u64 = 30;
    pub const MAX_RETRIES: u32 = 3;
}
```

## Peer-Reviewed References

1. Nagappan, N., Ball, T. (2006). "Using Software Dependencies and Churn Metrics to Predict Field Failures." IEEE TSE.
2. Zimmermann, T., Nagappan, N. (2008). "Predicting Defects using Network Analysis on Dependency Graphs." ICSE.
3. Ohno, T. (1988). "Toyota Production System: Beyond Large-Scale Production." Productivity Press.
4. Bird, C., et al. (2011). "Don't Touch My Code! Examining the Effects of Ownership on Software Quality." FSE.
5. Bacchelli, A., Bird, C. (2013). "Expectations, Outcomes, and Challenges of Modern Code Review." ICSE.

## Popperian Falsifiability

The file health system uses testable hypotheses:

### Falsifiable Claims
1. **Claim**: Files > 500 lines have higher defect rates
   - **Test**: Compare defect density in small vs large files
   - **Threshold**: 2x higher in large files

2. **Claim**: TLR < 0.5 correlates with bugs
   - **Test**: Track bug rates by TLR quartile
   - **Threshold**: Bottom quartile has 3x more bugs

3. **Claim**: Ratchet prevents regression
   - **Test**: Measure average file size over 6 months
   - **Threshold**: Average must not increase

## Configuration

Configure file health thresholds in `.pmat/project.toml`:

```toml
[file-health]
max_lines_new = 500
max_lines_critical = 2000
required_tlr_scaling = true
enforce_ratchet = true

[file-health.thresholds]
optimal = 200
acceptable = 500
warning = 1000
critical = 2000
```

## Summary

File Health enforcement prevents the accumulation of technical debt through:

1. **Hard limits** on new file sizes (500 lines)
2. **Ratchet mechanism** preventing growth of existing files
3. **TLR scaling** requiring more tests for larger files
4. **Health scoring** with actionable grades
5. **Pre-commit hooks** for automated enforcement

This implements Toyota Way principles (Jidoka, Kaizen, Muda elimination) with evidence-based thresholds from peer-reviewed research.
