# Chapter 51: YAML Best Practices (CB-950 to CB-953)

YAML's design philosophy of human readability introduces a class of silent failure modes absent from stricter formats like JSON or TOML. Duplicate keys are silently merged (last writer wins), unquoted strings are auto-coerced to booleans or nulls, inconsistent indentation alters document structure, and special characters cause parse failures at deployment time rather than authoring time. The most infamous example is the **Norway Problem**: the country code `NO` is silently interpreted as boolean `false` under YAML 1.1, a defect that has affected real-world systems including Ruby on Rails i18n, Helm charts, and GitHub Actions workflows. The CB-950 series detects these defect patterns before they reach production.

## Overview

```bash
# Run all compliance checks including CB-950 series
pmat comply check

# Example output:
# ⚠ CB-950: YAML Best Practices (CB-950 to CB-953): [Advisory] 0 errors, 5 warnings, 2 info:
# CB-950: Duplicate key `database` at line 14 (overrides value at line 3) (config.yml:14)
# CB-951: Truthy string ambiguity: `yes` coerced to boolean true (deploy.yml:8)
# CB-952: Mixed indentation: tab character at line 12, expected spaces (settings.yaml:12)
# CB-953: Unquoted special character `:` in value (docker-compose.yml:25)
```

The CB-950 series is **advisory** — it reports with `Warn` status but does not block CI or commits. Violations are categorized into three severity tiers:

| Severity | Meaning | Example |
|----------|---------|---------|
| Error | Likely defect in production | Duplicate key overriding earlier value |
| Warning | Code smell, should fix | Truthy string ambiguity, unquoted special characters |
| Info | Suggestion, low priority | Inconsistent indentation width |

## Defect Taxonomy

### Correctness (CB-950, CB-952)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-950 | Duplicate Key | Warning/Error | Duplicate top-level or nested keys where later values silently override earlier ones |
| CB-952 | Incorrect Indentation | Warning/Info | Mixed tabs and spaces, or inconsistent indent width within a file |

### Safety (CB-951, CB-953)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-951 | Truthy String Ambiguity | Warning | Unquoted `yes`, `no`, `on`, `off`, `true`, `false` coerced to booleans by YAML 1.1 |
| CB-953 | Unquoted Special Characters | Warning | Unquoted values containing `:`, `{`, `}`, `[`, `]`, `#`, `&`, `*` |

## Detection Algorithms

### CB-950: Duplicate Key

Detects duplicate keys at the same nesting level in YAML files. The YAML specification states that duplicate keys are an error, but most parsers silently accept them and use the last occurrence, discarding the earlier value without warning:

```yaml
# ❌ Duplicate key — `database` at line 8 silently overrides line 1 (CB-950):
database:
  host: localhost
  port: 5432
  name: myapp_dev

# ... 200 lines later ...
database:
  host: prod-db.internal
  port: 5432
  name: myapp_prod

# ✅ Unique keys with explicit environment separation:
database_dev:
  host: localhost
  port: 5432
  name: myapp_dev

database_prod:
  host: prod-db.internal
  port: 5432
  name: myapp_prod
```

Nested duplicate keys are also detected:

```yaml
# ❌ Duplicate nested key — `timeout` appears twice under `server` (CB-950):
server:
  host: 0.0.0.0
  port: 8080
  timeout: 30
  max_connections: 100
  timeout: 60

# ✅ Single definition:
server:
  host: 0.0.0.0
  port: 8080
  timeout: 60
  max_connections: 100
```

When a duplicate key overrides a complex mapping (multiple nested values lost), severity escalates from Warning to Error.

### CB-951: Truthy String Ambiguity

Detects unquoted values that YAML 1.1 interprets as booleans rather than strings. This is the root cause of the **Norway Problem**: the ISO 3166-1 country code `NO` for Norway is coerced to boolean `false`, breaking localization, geographic data, and any system that uses two-letter country codes as YAML values.

The full set of YAML 1.1 truthy/falsy tokens:

- **Truthy**: `y`, `Y`, `yes`, `Yes`, `YES`, `on`, `On`, `ON`, `true`, `True`, `TRUE`
- **Falsy**: `n`, `N`, `no`, `No`, `NO`, `off`, `Off`, `OFF`, `false`, `False`, `FALSE`

```yaml
# ❌ Truthy string ambiguity (CB-951):
countries:
  - DK
  - NO      # Parsed as boolean false, not the string "NO"
  - SE

features:
  dark_mode: yes    # Parsed as boolean true
  legacy_api: off   # Parsed as boolean false

# ✅ Quote values to preserve string semantics:
countries:
  - "DK"
  - "NO"    # String "NO" preserved
  - "SE"

features:
  dark_mode: "yes"
  legacy_api: "off"
```

The detector scans value positions (after `:` in mappings and `-` in sequences) for bare tokens matching the truthy/falsy set. Values already enclosed in single or double quotes are excluded.

### CB-952: Incorrect Indentation

Detects two classes of indentation defects: mixed tabs and spaces (which YAML forbids), and inconsistent indent width within the same file:

```yaml
# ❌ Mixed tabs and spaces (CB-952 Warning):
server:
  host: localhost
	port: 8080        # Tab character — YAML parse error

# ❌ Inconsistent indent width (CB-952 Info):
server:
  host: localhost     # 2-space indent
  port: 8080          # 2-space indent
database:
    host: db.local    # 4-space indent — inconsistent
    port: 5432

# ✅ Consistent 2-space indentation throughout:
server:
  host: localhost
  port: 8080
database:
  host: db.local
  port: 5432
```

Two sub-checks:
1. **Mixed tabs/spaces**: Any line containing a tab character in its leading whitespace triggers a Warning. YAML 1.2 explicitly forbids tabs for indentation.
2. **Inconsistent width**: After inferring the dominant indent width from the file (e.g., 2 spaces), lines deviating from that unit trigger an Info.

### CB-953: Unquoted Special Characters

Detects unquoted values containing YAML special characters that can cause parse errors or unexpected structure:

```yaml
# ❌ Unquoted special characters (CB-953):
message: Please enter name: age    # Second colon splits the value
regex: [a-z]+                      # Parsed as a single-element sequence
selector: app & version            # Anchor reference attempted
pointer: *default                  # Alias dereference attempted
note: see # comment section        # Truncated at #

# ✅ Quoted values preserve literal content:
message: "Please enter name: age"
regex: "[a-z]+"
selector: "app & version"
pointer: "*default"
note: "see # comment section"
```

Detected special characters in unquoted values: `:` (when not the key-value separator), `{`, `}`, `[`, `]`, `#` (mid-value, not end-of-line comments), `&`, `*`.

The detector excludes:
- Key positions (the `:` that separates key from value)
- Values enclosed in single or double quotes
- Flow mappings and sequences where `{}` and `[]` are syntactically valid
- Anchor definitions (`&name`) and alias references (`*name`) when used at the start of a value position as intended

## Testing

All CB-950 checks are tested against synthetic YAML fixtures covering both violation and clean-file scenarios:

```bash
# Run CB-950 series tests
cargo test --lib -- yaml_best_practices

# Test categories:
# - Duplicate key detection at top-level and nested levels
# - Truthy token detection across all 22 YAML 1.1 boolean tokens
# - Tab detection in leading whitespace
# - Indent width consistency inference
# - Special character detection in value positions
# - False positive avoidance for quoted values, flow syntax, anchors
```

Test fixtures include real-world patterns from Docker Compose files, GitHub Actions workflows, Kubernetes manifests, and Helm charts where these defects commonly occur.

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/yaml_best_practices.rs`
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_yaml_best_practices`)
