# Chapter 28: Mutation Testing

Mutation testing is a powerful technique to measure the quality of your test suite by introducing small changes (mutations) to your code and verifying that your tests catch these changes.

PMAT's mutation testing implementation uses **AST-based mutations** (no source recompilation required) and provides production-ready parallel execution with comprehensive output formats.

## What is Mutation Testing?

Mutation testing answers the question: **"Who tests the tests?"**

Traditional code coverage tells you which lines are executed, but not whether your tests actually validate the behavior. Mutation testing goes further by:

1. **Creating mutants**: Small, deliberate bugs introduced into your code
2. **Running tests**: Executing your test suite against each mutant
3. **Measuring results**:
   - **Killed mutant**: Tests caught the bug ✅
   - **Survived mutant**: Bug went undetected ❌

A high mutation score means your tests are effective at catching bugs.

## Quick Start

```bash
# Basic mutation testing
pmat mutate --target src/calculator.rs

# With color-coded output (v2.175.0+)
pmat mutate --target src/

# Show only failures for focused debugging
pmat mutate --target src/ --failures-only
```

## The `pmat mutate` Command

### Basic Usage

```bash
pmat mutate --target <PATH>
```

**Required**:
- `-t, --target <PATH>` - File or directory to mutate

**Optional Flags** (v2.175.0):
- `--failures-only` - Show only survived mutants, compile errors, and timeouts
- `-f, --output-format <FORMAT>` - Output format: `text` (default), `json`, `markdown`
- `-o, --output <FILE>` - Write output to file (default: stdout)
- `--threshold <SCORE>` - Fail if mutation score below threshold (e.g., `80.0`)
- `--timeout <SECONDS>` - Timeout per mutant (default: 30)
- `-j, --jobs <COUNT>` - Parallel workers (default: CPU core count)

### Output Formats

#### 1. Text Output (Color-Coded - v2.175.0)

Default terminal output with semantic colors:

```bash
pmat mutate --target src/math.rs
```

**Color Scheme**:
- 🟢 **Green**: Killed mutants, passing scores (≥80%)
- 🔴 **Red**: Survived mutants, failing scores (<60%)
- 🟡 **Yellow**: Compile errors, timeouts, warning scores (60-80%)
- 🔵 **Cyan**: File paths, operator names, locations

**Example Output**:
```
Generated 42 mutants

Executing mutants...
[========================================] 42/42 (100.0%)

Completed in 12.3s

Mutation Testing Results

Total mutants:  42
Killed:         35 (83.3%)
Survived:       5 (11.9%)
Compile errors: 2 (4.8%)

Mutation Score: 87.5%

Survived Mutants (needs test coverage):
1. src/math.rs:45:12
   Operator: BinaryOp(+ → -)
   Code: return a + b;
   Time: 0.15s
```

#### 2. JSON Output (CI/CD Integration)

Machine-readable format with code snippets (v2.175.0+):

```bash
pmat mutate --target src/ --output-format json > results.json
```

**JSON Structure**:
```json
{
  "score": {
    "total": 42,
    "killed": 35,
    "survived": 5,
    "compile_errors": 2,
    "timeouts": 0,
    "equivalent": 0,
    "score": 0.875
  },
  "results": [
    {
      "mutant": {
        "original_file": "src/math.rs",
        "location": {"line": 45, "column": 12, "end_line": 45, "end_column": 17},
        "operator": "BinaryOp",
        "mutated_source": "return a - b;"
      },
      "status": "Survived",
      "execution_time_ms": 150,
      "original_code_snippet": "return a + b;",
      "mutated_code_snippet": "return a - b;"
    }
  ]
}
```

**Use with jq**:
```bash
# Extract survived mutants
pmat mutate --target src/ -f json | jq '.results[] | select(.status == "Survived")'

# Get mutation score
pmat mutate --target src/ -f json | jq '.score.score * 100'
```

#### 3. Markdown Output (GitHub PR Comments)

PR-ready reports with diff blocks (v2.175.0+):

```bash
pmat mutate --target src/ --output-format markdown > MUTATION_REPORT.md
```

**Markdown Features**:
- Summary table with metrics
- Mutation score badge-ready format
- Survived mutants section with **code diffs**
- Test gap identification

**Example Markdown**:
```markdown
# Mutation Testing Results

## Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Mutants** | 42 | 100.0% |
| Killed | 35 | 83.3% |
| Survived | 5 | 11.9% |
| Compile Errors | 2 | 4.8% |

## Mutation Score: **87.5%**

## Survived Mutants (Test Gaps)

The following mutants survived, indicating potential test coverage gaps:

### Mutant #1
- **Location**: src/math.rs:45:12
- **Operator**: BinaryOp(+ → -)
- **Status**: Survived

**Code Change:**
\```diff
- return a + b;
+ return a - b;
\```
```

## The Failures-Only Flag (v2.175.0)

**Reduce noise by 70-90%** by filtering output to show only actionable failures:

```bash
pmat mutate --target src/ --failures-only
```

**Shows Only**:
- ❌ **Survived mutants** - Test gaps that need fixing
- ⚠️  **Compile errors** - Invalid mutations to investigate
- ⏱️  **Timeouts** - Potentially infinite loops

**Hides**:
- ✅ Killed mutants (working as expected)
- 🟰 Equivalent mutants (semantically identical)

**Perfect for**:
- Debugging test gaps
- CI/CD failure analysis
- Large codebases with 100+ mutants

**Example**:
```bash
# Instead of 239 lines of output...
pmat mutate --target src/large_file.rs

# Get only 15 failures to fix
pmat mutate --target src/large_file.rs --failures-only
```

## Mutation Operators

PMAT supports mutations across multiple languages. As of v3.0.7, supported languages include Rust, Lua, Go, and C++.

### Binary Operators
```rust
// Original
let x = a + b;

// Mutants
let x = a - b;  // + → -
let x = a * b;  // + → *
let x = a / b;  // + → /
```

### Comparison Operators
```rust
// Original
if x > y { }

// Mutants
if x >= y { }  // > → >=
if x < y { }   // > → <
if x == y { }  // > → ==
```

### Boolean Operators
```rust
// Original
if a && b { }

// Mutants
if a || b { }  // && → ||
if a { }       // Remove b
```

### Return Value Mutations
```rust
// Original
return true;

// Mutant
return false;  // true → false
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Mutation Testing

on: [pull_request]

jobs:
  mutation-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Run Mutation Testing
        run: |
          pmat mutate \
            --target src/ \
            --output-format json \
            --failures-only \
            --threshold 80.0 \
            > mutation_results.json

      - name: Comment on PR
        if: failure()
        run: |
          pmat mutate \
            --target src/ \
            --output-format markdown \
            --failures-only \
            > mutation_report.md
          gh pr comment ${{ github.event.pull_request.number }} \
            --body-file mutation_report.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### GitLab CI

```yaml
mutation-testing:
  stage: test
  image: rust:latest
  script:
    - cargo install pmat
    - pmat mutate --target src/ --output-format json --threshold 80.0 > results.json
  artifacts:
    reports:
      junit: results.json
    when: always
```

### Pre-commit Hook

Add mutation testing to your quality gates:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Only run on changed Rust files
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rs$')

if [ -n "$CHANGED_FILES" ]; then
    echo "Running mutation testing on changed files..."
    for FILE in $CHANGED_FILES; do
        pmat mutate --target "$FILE" --failures-only --threshold 80.0 || exit 1
    done
fi
```

## Best Practices

### 1. Set Realistic Thresholds

Don't aim for 100% mutation score initially:

```bash
# Start with 70%
pmat mutate --target src/ --threshold 70.0

# Gradually increase to 80-85%
pmat mutate --target src/ --threshold 85.0
```

**Industry Standards**:
- 60-70%: Good test coverage
- 70-80%: Very good coverage
- 80-90%: Excellent coverage
- 90-100%: Exceptional (diminishing returns)

### 2. Use Failures-Only Mode for Large Codebases

```bash
# For files with 100+ mutants
pmat mutate --target src/large_module.rs --failures-only
```

### 3. Focus on Critical Code First

```bash
# Test your core business logic
pmat mutate --target src/payment_processor.rs --threshold 90.0

# Less critical utilities can have lower thresholds
pmat mutate --target src/utils/ --threshold 70.0
```

### 4. Integrate with Code Coverage

```bash
# Run coverage first
cargo llvm-cov --html

# Then mutation testing
pmat mutate --target src/ --failures-only

# Coverage tells you WHAT is tested
# Mutation testing tells you HOW WELL it's tested
```

### 5. Parallel Execution for Speed

```bash
# Use all CPU cores
pmat mutate --target src/ --jobs $(nproc)

# Or limit workers to avoid system overload
pmat mutate --target src/ --jobs 4
```

## Interpreting Results

### Mutation Score Formula

```
Mutation Score = (Killed Mutants) / (Total Mutants - Equivalent Mutants)
```

### Status Types

| Status | Meaning | Action Required |
|--------|---------|-----------------|
| **Killed** | ✅ Test caught the bug | None - working correctly |
| **Survived** | ❌ Bug went undetected | **Add test to cover this case** |
| **Compile Error** | ⚠️  Invalid mutation | Investigate (usually benign) |
| **Timeout** | ⏱️  Mutant caused hang | Check for infinite loops |
| **Equivalent** | 🟰 No behavioral change | None - mutation is equivalent |

### Example: Fixing a Survived Mutant

**Mutant Survived**:
```rust
// Original: src/calculator.rs:15
pub fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {  // Mutated to: b != 0
        return Err("Division by zero".to_string());
    }
    Ok(a / b)
}
```

**Fix: Add Test**:
```rust
#[test]
fn test_divide_by_zero() {
    let result = divide(10, 0);
    assert!(result.is_err());
    assert_eq!(result.unwrap_err(), "Division by zero");
}

#[test]
fn test_divide_by_nonzero() {
    let result = divide(10, 2);
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), 5);
}
```

## Advanced Usage

### Custom Timeouts

```bash
# Increase timeout for complex tests
pmat mutate --target src/integration/ --timeout 60

# Decrease for unit tests
pmat mutate --target src/units/ --timeout 10
```

### Combining with Other Tools

```bash
# Full quality pipeline
cargo test &&                          # Unit tests
cargo llvm-cov --lcov > coverage.lcov && # Coverage
pmat mutate --target src/ --threshold 80.0 && # Mutation testing
pmat analyze tdg                      # Technical debt grading
```

### Selective Mutation Testing

```bash
# Test only critical files
pmat mutate --target src/auth.rs --threshold 90.0
pmat mutate --target src/payment.rs --threshold 90.0

# Test everything else with lower threshold
pmat mutate --target src/ --threshold 75.0
```

## Troubleshooting

### High Compile Error Rate

**Problem**: Many mutants cause compile errors

**Solution**: This is usually benign. Compile errors don't affect mutation score. Use `--failures-only` to filter them out:

```bash
pmat mutate --target src/ --failures-only
```

### Timeouts

**Problem**: Mutations cause infinite loops

**Solution**: Increase timeout or investigate the code:

```bash
# Increase timeout
pmat mutate --target src/ --timeout 60

# Find which mutants timeout
pmat mutate --target src/ --failures-only | grep "Timeout"
```

### Low Mutation Score

**Problem**: Many mutants survive

**Solution**: Add tests for uncovered edge cases. Use markdown output to identify gaps:

```bash
pmat mutate --target src/ --output-format markdown > gaps.md
# Review gaps.md for "Survived Mutants" section
```

## Roadmap

### Multi-Language Support (v3.0.7+)

PMAT's mutation testing now supports multiple languages through the `LanguageAdapter` trait:

| Language | Test Runner | Project Root Detection | Status |
|----------|------------|----------------------|--------|
| **Rust** | `cargo test` | `Cargo.toml` | Stable |
| **Lua** | `busted` | `.busted`, `*.rockspec`, `init.lua` | Stable |
| **Go** | `go test` | `go.mod` | Stable |
| **C++** | `cmake --build && ctest` | `CMakeLists.txt` | Stable |

```bash
# Lua mutation testing (requires busted)
pmat mutate --target src/main.lua

# Go mutation testing
pmat mutate --target pkg/handler.go

# C++ mutation testing (requires CMake)
pmat mutate --target src/parser.cpp
```

All adapters share the same four mutation operator categories (arithmetic, relational, conditional, unary) with language-appropriate syntax.

### Planned Features

- **Incremental Mutation Testing**: Only test changed files
- **Mutation Caching**: Skip equivalent mutants
- **IDE Integration**: VS Code plugin with inline mutation indicators
- **Custom Operators**: Define your own mutation rules
- **Additional Languages**: Python, TypeScript, Java

### Current Limitations

- **No Differential Mutations**: Test only changed code (planned)
- **Feature-gated**: Multi-language support requires `--features mutation-testing`

## Related Commands

- **`pmat analyze coverage`** - Code coverage analysis
- **`pmat analyze complexity`** - Identify complex code that needs better tests
- **`pmat quality-gate`** - Combine mutation testing with other quality checks
- **`pmat hooks install`** - Add mutation testing to pre-commit hooks

## Summary

Mutation testing is the **gold standard** for test quality measurement. PMAT's implementation provides:

✅ **AST-Based Mutations** - No source recompilation
✅ **Parallel Execution** - Fast results even on large codebases
✅ **Three Output Formats** - Text, JSON, Markdown
✅ **Failures-Only Mode** - Focus on actionable gaps (v2.175.0)
✅ **Color-Coded Output** - Instant readability (v2.175.0)
✅ **CI/CD Ready** - Threshold enforcement and machine-readable output

**Next Steps**:
- Run `pmat mutate --target src/` on your codebase
- Review survived mutants and add tests
- Integrate into your CI/CD pipeline
- Set threshold goals (start at 70%, aim for 80-85%)

**Learn More**:
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md) - Combining mutation testing with other checks
- [Chapter 23: Performance Testing Suite](ch23-00-testing.md) - Comprehensive testing strategies
- [Appendix B: Command Reference](appendix-b-commands.md) - Full `pmat mutate` options
