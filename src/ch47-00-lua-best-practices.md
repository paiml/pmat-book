# Chapter 47: Lua Best Practices (CB-600 to CB-619)

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

**String-aware scanning**: The deep field access counter skips over quoted strings and bracket expressions. This prevents false positives on patterns like `corrections["H.N.S.W."] = "HNSW"` where dots appear inside string-literal table keys.

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

**Variable-aware status checking**: The detector extracts the actual pcall status variable name from the assignment, so prefixed variable names are correctly recognized:

```lua
-- ✅ Correctly detected as handled (no false positive):
local wrap_ok, err = pcall(risky_fn)
if not wrap_ok then
    handle_error(err)
end
```

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

**Severity tiers**: The severity depends on how the API is called:

| Usage Pattern | Severity | Rationale |
|---------------|----------|-----------|
| Hardcoded string argument: `os.execute("make clean")` | Info | Known command, no injection risk |
| Variable or concatenation argument: `os.execute(cmd)` | Warning | Potential command injection |
| No argument analysis possible | Warning | Default to cautious |

**Inline suppression**: Add `-- pmat:ignore CB-603` (or bare `-- pmat:ignore`) on the same line to suppress individual violations:

```lua
os.execute("make clean")              -- pmat:ignore CB-603
io.popen("git status")                -- pmat:ignore
```

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
| Bracket expression skipping | CB-601 | Flagging dots inside `["key.with.dots"]` as field access |
| Variable name extraction | CB-602 | Flagging pcall as unchecked when prefixed var (e.g. `wrap_ok`) is checked |
| Severity tiers (hardcoded vs variable args) | CB-603 | Over-warning on safe hardcoded `os.execute("make")` calls |
| Inline suppression (`-- pmat:ignore`) | CB-603 | False positives on intentional dangerous API usage |
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

## Dead Code Detection

Lua projects receive module-export-aware dead code analysis via `pmat analyze dead-code`:

```bash
pmat analyze dead-code --path /path/to/lua/project

# Example output:
# Language: lua
# Total functions: 5
# Dead functions: 1
#   - truly_dead (line 12): Function defined but never called
# Dead code: 20.0%
```

**Module export awareness**: Functions attached to a returned module table are correctly excluded from dead code analysis:

```lua
local M = {}

function M.public_api()      -- NOT dead: exported via return M
    return M.helper()
end

function M.helper()          -- NOT dead: called by public_api
    return 42
end

local function truly_dead()  -- DEAD: local, never called
    return "nobody calls me"
end

return M                     -- signals M.* functions are exported
```

The detector identifies the `return M` pattern at the end of the file and marks all `M.name` and `M:name` functions as exported. Both `function M.name()` declarations and `M.name = function()` table field assignments are recognized.

**Test file handling**: Test files (`test_*.lua`, `*_test.lua`, `*_spec.lua`, files under `test/`/`tests/`/`spec/` directories) are excluded from dead function reporting but their function calls are still tracked — so a function called only from tests is not falsely flagged as dead.

## Advanced Checks (CB-608 to CB-619)

The CB-608 through CB-619 checks detect deeper Lua defect patterns covering error handling, coroutines, FFI safety, require cycles, and ecosystem-specific concerns (OpenResty, LuaJIT). These were added in v3.0.7 based on empirical analysis of large Lua projects (Kong, APISIX, xmake, KOReader, AwesomeWM).

### Error Handling & Safety (CB-608, CB-609, CB-610)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-608 | Unchecked nil,err Return | Warning | Caller ignores the `nil, err` error return pattern |
| CB-609 | assert() in Library Code | Warning | `assert()` in non-test code — terminates without recovery |
| CB-610 | String Accumulator in Loop | Info | `result = result .. x` pattern in loops (O(n²)) |

#### CB-608: Unchecked nil,err Return

The dominant Lua error handling pattern (>80% of real-world error handling) returns `nil, err` on failure. CB-608 flags callers that ignore this:

```lua
-- ❌ Unchecked nil,err (CB-608 Warning):
local data = socket:read("*a")       -- ignores error return
process(data)                          -- crashes if data is nil

-- ✅ Proper error handling:
local data, err = socket:read("*a")
if not data then
    log.error("read failed: " .. err)
    return nil, err
end
process(data)
```

Reference: Kong (1,725 instances), APISIX (716), xmake (254).

#### CB-609: assert() in Library Code

`assert()` is appropriate in tests but problematic in library code — it terminates the entire process without allowing callers to recover:

```lua
-- ❌ assert in library (CB-609 Warning):
function M.parse(input)
    assert(type(input) == "string")   -- kills the process
    -- ...
end

-- ✅ Return error instead:
function M.parse(input)
    if type(input) ~= "string" then
        return nil, "expected string, got " .. type(input)
    end
    -- ...
end
```

Reference: AwesomeWM (1,817 asserts), xmake (913).

#### CB-610: String Accumulator in Loop

More precise than CB-605 — only flags the accumulator pattern (`result = result .. x`) where the same variable is both source and target. Single-use concatenation like `log("msg: " .. x)` is not flagged:

```lua
-- ❌ Accumulator pattern (CB-610 Info):
local result = ""
for _, item in ipairs(items) do
    result = result .. item .. ","    -- O(n²) due to copy each iteration
end

-- ✅ Use table.concat:
local parts = {}
for _, item in ipairs(items) do
    parts[#parts + 1] = item
end
local result = table.concat(parts, ",")
```

### Weak Tables & Test Frameworks (CB-611, CB-612)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-611 | Weak Table Misuse | Warning | String/numeric keys with `__mode = "k"` (never GC'd) |
| CB-612 | Test Framework Detection | Info | Auto-detects busted, luaunit, lust, Test::Nginx |

#### CB-611: Weak Table Misuse

Weak tables are a common GC optimization in Lua, but using `__mode = "k"` (weak keys) with string or numeric keys is ineffective — value types are never garbage collected:

```lua
-- ❌ Weak key with string keys (CB-611 Warning):
local cache = setmetatable({}, { __mode = "k" })
cache["user:123"] = expensive_data    -- string key is NEVER collected

-- ✅ Use weak values or explicit eviction:
local cache = setmetatable({}, { __mode = "v" })
-- OR
local cache = {}
local function evict_old() ... end
```

Also flags unbounded caches without weak references or explicit eviction.

#### CB-612: Test Framework Detection

Informational check that auto-detects which test framework(s) a Lua project uses. Supports hybrid projects (e.g., Kong uses both busted and Test::Nginx):

```bash
# Example output:
# CB-612: Detected test framework(s): busted, Test::Nginx
# CB-612: 47 Lua test files found (spec/ directory, *_spec.lua pattern)
```

### Module Safety (CB-613, CB-614)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-613 | Require Cycle Detection | Error | Circular `require()` chains via DFS |
| CB-614 | Global Protection | Warning | Missing `setmetatable(_G)` guards, unsafe `load`/`loadfile` |

#### CB-613: Require Cycle Detection

Builds a directed graph from top-level `require()` calls and detects cycles via DFS. Function-scoped requires are excluded (they use deferred loading and are safe):

```lua
-- ❌ Circular require chain (CB-613 Error):
-- a.lua: require("b")
-- b.lua: require("c")
-- c.lua: require("a")  -- cycle: a -> b -> c -> a

-- ✅ Break the cycle:
-- Extract shared types into a separate module
-- Use deferred (function-scoped) requires for cross-references
```

#### CB-614: Global Protection

Checks for global namespace protection patterns and security-sensitive load calls:

```lua
-- ❌ No global protection (CB-614 Warning):
-- Project has no setmetatable(_G, ...) anywhere

-- ✅ Protect globals:
setmetatable(_G, {
    __newindex = function(_, k, v)
        error("attempt to set global '" .. k .. "'", 2)
    end
})

-- ❌ Unsafe load (CB-614 Warning):
loadfile("plugin.lua")()           -- allows bytecode injection

-- ✅ Restrict to text mode:
loadfile("plugin.lua", "t")()     -- "t" mode blocks bytecode
```

### Coroutines & Type Annotations (CB-615, CB-616)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-615 | Coroutine Safety | Warning | `coroutine.resume` without pcall wrap |
| CB-616 | Type Annotation Coverage | Info | LuaLS/LDoc annotation coverage percentage |

#### CB-615: Coroutine Safety

Detects `coroutine.resume()` calls without proper error handling — errors inside coroutines are silent unless explicitly checked:

```lua
-- ❌ Unprotected resume (CB-615 Warning):
coroutine.resume(co, data)         -- error swallowed silently

-- ✅ Check return value:
local ok, err = coroutine.resume(co, data)
if not ok then
    log.error("coroutine error: " .. tostring(err))
end
```

#### CB-616: Type Annotation Coverage

Reports type annotation coverage for LuaLS (`---@param`, `---@return`) and LDoc (`-- @tparam`, `-- @treturn`) annotation systems:

```bash
# Example output:
# CB-616: Type annotation coverage: 23% (47/204 functions annotated)
# CB-616: Annotation system: LuaLS (---@param style)
```

### Ecosystem-Specific (CB-617, CB-618, CB-619)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-617 | OpenResty Performance | Warning | Stdlib globals in hot paths, unchecked ngx.var |
| CB-618 | LuaJIT FFI Safety | Warning | Unchecked ffi.new buffers, C function calls |
| CB-619 | OOP Pattern Detection | Info | Metatable, prototypal, __call constructor patterns |

#### CB-617: OpenResty Performance

Only runs on detected OpenResty projects. Flags performance anti-patterns specific to the OpenResty/ngx_lua environment:

```lua
-- ❌ Global stdlib in handler (CB-617 Warning):
function _M.handler(ngx)
    local data = string.format(...)  -- allocates on every request
    local match = string.match(...)
end

-- ✅ Cache at module level:
local str_format = string.format
local str_match = string.match
function _M.handler(ngx)
    local data = str_format(...)     -- uses cached local
end

-- ❌ Unchecked ngx.var (CB-617 Warning):
local host = ngx.var.host            -- can be nil

-- ✅ Check for nil:
local host = ngx.var.host or "default"
```

#### CB-618: LuaJIT FFI Safety

Detects LuaJIT FFI patterns that can cause memory corruption or crashes:

```lua
-- ❌ Unchecked FFI allocation (CB-618 Warning):
local buf = ffi.new("char[?]", size)   -- no NULL check
ffi.copy(buf, data, size)

-- ❌ Unchecked C function call (CB-618 Warning):
local fd = C.open(path, flags)         -- return value unchecked

-- ✅ Check returns:
local buf = ffi.new("char[?]", size)
if buf == nil then error("allocation failed") end

local fd = C.open(path, flags)
if fd < 0 then error("open failed: " .. ffi.errno()) end
```

#### CB-619: OOP Pattern Detection

Informational check that recognizes and reports Lua OOP patterns for TDG awareness. Detects four styles:

1. **Separate metatable**: `setmetatable(obj, { __index = Class })`
2. **Prototypal inheritance**: `Child.__index = Parent`
3. **__call constructor**: `setmetatable(Class, { __call = function(...) ... end })`
4. **Self-as-metatable**: `Class.__index = Class`

```bash
# Example output:
# CB-619: OOP patterns detected: self-as-metatable (12 classes),
#          __call constructor (3 classes), prototypal (2 hierarchies)
```

## Mutation Testing Support

As of v3.0.7, Lua projects support mutation testing via the busted test framework integration:

```bash
pmat mutate --target src/main.lua
```

The Lua mutation adapter (`LuaAdapter`) provides:
- **AST-based operators**: Arithmetic, relational, conditional, unary replacement
- **Project root detection**: Finds `.busted`, `*.rockspec`, or `init.lua`
- **Test runner integration**: Uses `busted` command with configurable timeout
- **File extension**: `.lua`

Mutation operators applied to Lua code:
- `+` ↔ `-`, `*` ↔ `/` (arithmetic)
- `>` ↔ `<`, `>=` ↔ `<=`, `==` ↔ `~=` (relational)
- `and` ↔ `or` (conditional)
- `not` insertion/removal (unary)

See [Chapter 28: Mutation Testing](ch28-00-mutation-testing.md) for full documentation.

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/lua_best_practices.rs`
TDG analyzer: `src/tdg/analyzer_ast/analyzer_impl1.rs` (`analyze_lua_ast`)
Consistency scorer: `src/tdg/analyzer_ast/analyzer_impl2.rs` (`score_consistency_lua`)
Visitor: `src/tdg/analyzer_ast/visitors.rs` (`LuaComplexityVisitor`)
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_lua_best_practices`)
Dead code strategy: `src/services/dead_code_multi_language.rs` (`LuaDeadCodeStrategy`)
