# Chapter 47: Lua Best Practices (CB-600 to CB-607)

The CB-600 series detects Lua-specific defect patterns that apply to **any** Lua project. These checks are grounded in academic research on Lua taint analysis (LuaTaint), progressive taint analysis (FLuaScan), the Luau type system, and the luacheck static analyzer. They target the most common sources of runtime errors in Lua: implicit globals, nil-unsafe access, swallowed errors, dangerous APIs, and structural anti-patterns.

## Overview

```bash
# Run all compliance checks including CB-600 series
pmat comply check

# Example output:
# ⚠ CB-600: Lua Best Practices (CB-600 to CB-607): [Advisory] 0 errors, 3 warnings, 2 info:
# CB-600: Implicit global `count` — missing `local` keyword (src/main.lua:15)
# CB-601: Nil-unsafe: chained access on function return value (src/init.lua:42)
# CB-603: Dangerous API `os.execute()` (src/deploy.lua:8)
# CB-604: Unused variable `tmp` — prefix with `_` if intentional (src/util.lua:23)
# CB-605: String concatenation (`..`) in loop — O(n²), use table.concat() (src/render.lua:67)
```

The CB-600 series is **advisory** — it reports with `Warn` status but does not block CI or commits. Violations are categorized into three severity tiers:

| Severity | Meaning | Example |
|----------|---------|---------|
| Error | Likely defect in production | >10 implicit globals per file |
| Warning | Code smell, should fix | Nil-unsafe access, unchecked pcall, dangerous APIs |
| Info | Suggestion, low priority | Unused variables, string concat in loop, missing module return |

## Defect Taxonomy

### Variable Hygiene (CB-600, CB-604)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-600 | Implicit Globals | Warning/Error | Assignment without `local` keyword (luacheck W111/W113) |
| CB-604 | Unused Variables | Info | `local var = ...` where var is never referenced again (luacheck W211) |

### Safety (CB-601, CB-602, CB-603)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-601 | Nil-Unsafe Access | Warning | Chained calls on function returns (`).`/`):`) or 3+ deep field access |
| CB-602 | pcall Error Handling | Warning/Error | Uncaptured or unchecked pcall/xpcall return values |
| CB-603 | Deprecated/Dangerous API | Warning | `os.execute()`, `io.popen()`, `loadstring()`, `setfenv()` |

### Structure & Performance (CB-605, CB-606, CB-607)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-605 | String Concat in Loop | Info | `..` operator inside for/while/repeat — O(n²) |
| CB-606 | Missing Module Return | Info | `local M = {}` pattern without final `return M` |
| CB-607 | Colon/Dot Confusion | Info | Mixed `:` and `.` method calls on same table |

## Detection Algorithms

### CB-600: Implicit Globals

Detects assignment to variables without the `local` keyword. This is Lua's most common source of hard-to-find bugs — any unqualified assignment creates or overwrites a global:

```lua
-- ❌ Implicit global (CB-600 Warning):
count = 0
result = compute(data)

-- ✅ Explicit local:
local count = 0
local result = compute(data)
```

The detector tracks three categories of known locals to avoid false positives:

1. **Function parameters**: `function foo(a, b)` — `a` and `b` are local
2. **For-loop variables**: `for i, v in ipairs(t)` — `i` and `v` are local
3. **Local declarations**: `local x = 1` — `x` is local for subsequent lines

Additionally, **brace depth tracking** prevents false positives on table constructor fields:

```lua
-- NOT flagged (inside table constructor):
local config = {
    width = 800,    -- table field, not global assignment
    height = 600,   -- table field, not global assignment
}
```

When a file has >10 implicit globals, the severity escalates from Warning to Error.

### CB-601: Nil-Unsafe Access

Detects patterns that will throw a runtime error if an intermediate value is `nil`:

```lua
-- ❌ Pattern 1: Chained access on function return (CB-601):
get_player():set_health(100)     -- crashes if get_player() returns nil
find_widget().visible = true      -- crashes if find_widget() returns nil

-- ✅ Safe alternatives:
local player = get_player()
if player then
    player:set_health(100)
end

local widget = find_widget()
if widget then
    widget.visible = true
end

-- ❌ Pattern 2: Deep field access chain (CB-601):
local val = config.server.database.host    -- 3+ levels deep

-- ✅ Safe alternative:
local db = config.server and config.server.database
local host = db and db.host
```

Two detection patterns:
1. **Function return chaining**: `).` or `):` outside string literals
2. **Deep field access**: 4+ consecutive dot-separated identifiers (`a.b.c.d`)

### CB-602: pcall Error Handling

Detects `pcall()`/`xpcall()` calls where the error status is not properly handled:

```lua
-- ❌ Case 1: Return value not captured (CB-602 Warning):
pcall(dangerous_function)         -- error silently swallowed

-- ❌ Case 2: Status captured but error not checked (CB-602 Error):
local ok = pcall(dangerous_function)
-- ok is never checked with `if not ok`

-- ✅ Proper error handling:
local ok, err = pcall(dangerous_function)
if not ok then
    log_error("Operation failed: " .. tostring(err))
    return nil, err
end
```

Three sub-checks with escalating severity:
1. **Uncaptured** (no `=` before pcall) → Warning
2. **Captured but unchecked** (no `if not ok` within 5 lines) → Error
3. **Properly handled** (captured + checked) → no violation

### CB-603: Deprecated/Dangerous API

Detects usage of APIs that enable command injection, sandbox escape, or are deprecated:

```lua
-- ❌ Dangerous APIs (CB-603 Warning):
os.execute("rm -rf " .. user_input)   -- command injection
io.popen("curl " .. url)              -- command injection
loadstring(user_code)()               -- arbitrary code execution
setfenv(1, {})                        -- sandbox escape (deprecated in 5.2+)

-- ✅ Safe alternatives:
-- Use os.execute() only with hardcoded commands
os.execute("make clean")

-- Use structured subprocess APIs instead of string concatenation
-- Use load() with restricted environment instead of loadstring()
-- setfenv() is removed in Lua 5.2+ — use _ENV instead
```

Detected APIs:
- **Deprecated**: `table.getn()`, `table.foreach()`, `table.foreachi()`, `setfenv()`, `getfenv()`, `module()`
- **Dangerous**: `os.execute()`, `io.popen()`, `loadstring()`, `debug.getinfo()`, `debug.setlocal()`

### CB-604: Unused Variables

Detects `local` variable declarations where the variable is never referenced again in the file:

```lua
-- ❌ Unused variable (CB-604 Info):
local result = expensive_compute()    -- never used after this line

-- ✅ Prefix with underscore if intentional:
local _result = expensive_compute()   -- intentionally unused (e.g., side effect)

-- ✅ Or use the variable:
local result = expensive_compute()
print(result)
```

The detector counts occurrences of the identifier across all production lines. If the count is ≤1 (only the declaration itself), it flags the variable.

### CB-605: String Concat in Loop

Detects the `..` string concatenation operator inside loop bodies, which creates O(n²) behavior due to Lua's immutable string semantics:

```lua
-- ❌ O(n²) concatenation (CB-605 Info):
local s = ""
for i = 1, 1000 do
    s = s .. tostring(i) .. ","     -- copies entire string each iteration
end

-- ✅ O(n) with table.concat:
local parts = {}
for i = 1, 1000 do
    parts[#parts + 1] = tostring(i)
end
local s = table.concat(parts, ",")
```

The detector tracks loop depth (for/while/repeat) and flags `..` usage inside loops. The `..` operator inside string literals is excluded.

### CB-606: Missing Module Return

Detects the common Lua module pattern (`local M = {}`) without the corresponding `return M` at the end of the file:

```lua
-- ❌ Missing return (CB-606 Info):
local M = {}

function M.init()
    -- ...
end

function M.run()
    -- ...
end
-- forgot `return M` — require() returns true instead of the module table

-- ✅ Correct module pattern:
local M = {}

function M.init()
    -- ...
end

function M.run()
    -- ...
end

return M
```

The detector looks for `local <name> = {}` near the top of the file, then checks if any of the last lines contain `return <name>`.

### CB-607: Colon/Dot Confusion

Detects tables where methods are called with both `:` (method syntax, implicit `self`) and `.` (function syntax, no `self`) — indicating inconsistent self parameter handling:

```lua
-- ❌ Mixed syntax on same table (CB-607 Info):
player.getName()     -- calls without self
player:setHealth(100) -- calls with self — inconsistent

-- ✅ Consistent colon syntax:
player:getName()
player:setHealth(100)

-- ✅ Or consistent dot syntax (for static/module functions):
Utils.format(data)
Utils.validate(data)
```

The detector builds a per-table map of colon vs. dot call sites and flags tables that use both styles.

## Test Code Exclusion

All CB-600 checks exclude test code using two mechanisms:

1. **Test file exclusion**: Files matching `test_*.lua`, `*_test.lua`, `*_spec.lua`, or under `spec/`, `tests/`, `test/` directories
2. **Production line filtering**: Comment stripping via `compute_lua_production_lines()` — removes `--` line comments and `--[[ ]]` block comments

This prevents false positives from test code where implicit globals and dangerous APIs may be acceptable.

## False Positive Avoidance

The CB-600 detectors include several mechanisms to reduce false positives:

| Mechanism | Applied To | What It Prevents |
|-----------|-----------|-----------------|
| Known locals tracking (params, loop vars, local decls) | CB-600 | Flagging function parameters as implicit globals |
| Brace depth tracking | CB-600 | Flagging table constructor fields as implicit globals |
| Lua keyword prefix check | CB-600 | Flagging `if`, `for`, `return`, etc. as assignments |
| String literal exclusion | CB-601, CB-602, CB-605 | Flagging patterns inside string content |
| `_` prefix convention | CB-604 | Flagging intentionally unused variables |
| Loop depth tracking | CB-605 | Flagging concat outside loops |

## Remediation Priority

When `pmat comply check` reports CB-600 violations, fix them in this priority order:

1. **CB-602 Errors** (unchecked pcall) — swallowed errors hide crashes
2. **CB-600 Errors** (>10 implicit globals/file) — global namespace pollution
3. **CB-603** — dangerous APIs enable command injection
4. **CB-601** — nil-unsafe access causes runtime crashes
5. **CB-600 Warnings** — implicit globals cause hard-to-trace bugs
6. **CB-605** — string concat in loop causes O(n²) performance
7. **CB-606** — missing module return breaks `require()` consumers
8. **CB-604, CB-607** — informational, fix at leisure

## CI/CD Integration

```yaml
# .github/workflows/lua-best-practices.yml
name: Lua Best Practices
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PMAT
        run: cargo install pmat
      - name: Check Lua Best Practices
        run: |
          OUTPUT=$(pmat comply check 2>&1)
          echo "$OUTPUT"
          # Fail on Error-severity violations
          if echo "$OUTPUT" | grep -q "CB-600.*errors: [1-9]"; then
            echo "::error::CB-600 series has Error-severity violations"
            exit 1
          fi
```

## Academic Foundations

The CB-600 checks are grounded in empirical research on Lua defect patterns:

| Paper | Finding | Applied To |
|-------|---------|-----------|
| Mendonca et al. (2017). "LuaTaint: A Static Taint Analysis System for Web Vulnerabilities in Lua Programs" | Taint flow through globals and function returns | CB-600, CB-601, CB-603 |
| Zhang et al. (2020). "FLuaScan: Progressive Taint Analysis for Lua" | Unchecked error propagation in pcall chains | CB-602, CB-603 |
| Petricek (2023). "Luau: Gradual Type System for Lua" | Method resolution confusion with `:` vs `.` | CB-601, CB-607 |
| Maidl et al. (2014). "Typed Lua: An Optional Type System for Lua" | Global variable pollution as top defect source | CB-600, CB-604 |
| luacheck documentation (2015-2024) | W111, W113, W211 warning codes | CB-600, CB-604 |

## TDG Integration

In addition to CB-600 compliance checks, Lua files receive full TDG (Technical Debt Grading) analysis via tree-sitter-lua. This provides the same 7-component quality scoring available for Rust, Python, JavaScript, TypeScript, and C/C++:

```bash
# TDG quality grading for a Lua file
pmat analyze tdg --path game.lua --format json

# Example output:
# {
#   "structural_complexity": 24.1,
#   "semantic_complexity": 20.0,
#   "duplication_ratio": 20.0,
#   "coupling_score": 15.0,
#   "doc_coverage": 7.3,
#   "consistency_score": 10.0,
#   "total": 96.4,
#   "grade": "APLus",
#   "confidence": 0.9,
#   "language": "Lua"
# }
```

**TDG scoring components for Lua:**

| Component | Max Points | What It Measures |
|-----------|-----------|-----------------|
| Structural Complexity | 25 | Cyclomatic/cognitive complexity, nesting depth, function length |
| Semantic Complexity | 20 | Parameter count, metatable usage (OOP patterns) |
| Duplication Ratio | 20 | Code clone detection across functions |
| Coupling Score | 15 | `require()` import count, external function calls |
| Doc Coverage | 10 | `--` comment lines, documented functions (preceding comments) |
| Consistency Score | 10 | Indentation consistency (tabs vs spaces), naming convention consistency (snake_case vs camelCase) |
| Entropy Score | 10 | Pattern repetition and diversity |

**Lua-specific detection:**
- **Control flow**: `if/elseif/for/while/repeat` and `and`/`or` operators
- **OOP patterns**: `setmetatable()` calls counted as type complexity
- **Imports**: `require()` calls counted as coupling
- **Documentation**: Preceding `--`/`---` comments on functions

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/lua_best_practices.rs`
TDG analyzer: `src/tdg/analyzer_ast/analyzer_impl1.rs` (`analyze_lua_ast`)
Consistency scorer: `src/tdg/analyzer_ast/analyzer_impl2.rs` (`score_consistency_lua`)
Visitor: `src/tdg/analyzer_ast/visitors.rs` (`LuaComplexityVisitor`)
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_lua_best_practices`)
