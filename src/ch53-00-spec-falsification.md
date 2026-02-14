# Chapter 53: Spec Falsification Engine

The `pmat falsify` command validates specification claims against the actual codebase using Popperian falsification. Instead of confirming that specs are correct, it actively searches for **disconfirming evidence** — a strictly more powerful approach based on Karl Popper's philosophy of science.

## Overview

Specifications drift from reality. A spec might claim "MUST use SQLite for storage" when the code actually uses PostgreSQL, or reference a file path that no longer exists. The falsification engine extracts testable claims from markdown documents and cross-references them against the codebase to catch contradictions before they become bugs.

```
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│  Spec Document   │────▶│  Claim Extractor   │────▶│  94 Claims       │
│  (markdown/yaml) │     │  (RFC-2119, paths, │     │  extracted       │
│                  │     │   entities, etc.)  │     │                  │
└──────────────────┘     └───────────────────┘     └────────┬─────────┘
                                                            │
                                                            ▼
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│  Report          │◀────│  Falsification     │◀────│  Strategy Router │
│  (pass/fail per  │     │  Strategies        │     │  (per category)  │
│   claim)         │     │  (path, entity,    │     │                  │
│                  │     │   absence, etc.)   │     │                  │
└──────────────────┘     └───────────────────┘     └──────────────────┘
```

## Quick Start

```bash
# Falsify a single specification
pmat falsify docs/specifications/my-feature.md

# Falsify all specs in a directory
pmat falsify docs/specifications/

# Dry run — show extracted claims without checking
pmat falsify docs/specifications/my-feature.md --dry-run

# JSON output for CI/CD
pmat falsify docs/specifications/my-feature.md --format json 2>/dev/null

# Show only failures
pmat falsify docs/specifications/my-feature.md --failures-only
```

## Claim Extraction

The engine automatically extracts falsifiable claims from structured documents using nine pattern categories:

### RFC-2119 Keywords

Claims using MUST, SHALL, SHOULD, MAY (per RFC 2119) are extracted with priority based on keyword strength:

```markdown
<!-- These become falsifiable claims: -->
The system MUST store receipts in `.pmat-work/{id}/falsification/`
The API SHOULD return results within 200ms
Configuration files SHALL use TOML format
```

| Keyword | Priority | Meaning |
|---------|----------|---------|
| MUST / SHALL / REQUIRED | P0 (Critical) | Absolute requirement |
| SHOULD / RECOMMENDED | P1 (High) | Strong recommendation |
| MAY / OPTIONAL | P2 (Medium) | Truly optional |

### Path References

Any file or directory path is checked for existence:

```markdown
<!-- Extracted and verified against filesystem: -->
Configuration at `.pmat-metrics.toml`
Source in `src/services/spec_falsification.rs`
Schema at `docs/schemas/receipt.json`
```

### Code Entities

References to functions, structs, modules, and traits are searched in the codebase index:

```markdown
<!-- Verified via pmat query: -->
The `FalsificationEngine` struct handles all strategies
The `extract_claims()` method returns a `Vec<SpecClaim>`
```

### Numeric Thresholds

Measurable claims with specific numbers:

```markdown
<!-- Extracted as metric claims: -->
Response time MUST be under 200ms
Coverage SHOULD exceed 85%
Maximum file size: 500 lines
```

### Absence Assertions

Claims that something should NOT exist:

```markdown
<!-- Verified by searching for the forbidden pattern: -->
MUST NOT use unwrap() in production code
SHALL NOT store secrets in plaintext
```

## Claim Categories and Strategies

Each extracted claim is categorized and routed to the appropriate falsification strategy:

| Category | Strategy | How It's Falsified |
|----------|----------|-------------------|
| `PathReference` | Check filesystem | Path exists? Similar file found? |
| `CodeEntity` | Search codebase index | Entity found via `pmat query`? |
| `AbsenceClaim` | Reverse search | Forbidden pattern found? |
| `CommandClaim` | Validate executable | Command exists and is parseable? |
| `MetricClaim` | Check threshold | Metric within stated bounds? |
| `ArchitecturalClaim` | Structural analysis | Architecture matches description? |
| `BehaviorClaim` | Evidence search | Behavioral evidence found? |
| `Requirement` | Evidence search | Implementation evidence exists? |

## Verdict Statuses

Each claim receives one of four verdicts:

| Status | Meaning | Action |
|--------|---------|--------|
| **Survived** | Claim could not be falsified (evidence supports it) | No action needed |
| **Falsified** | Evidence contradicts the claim | Fix the spec or the code |
| **NotTestable** | Claim cannot be empirically tested | Consider rewriting |
| **Skipped** | Claim filtered or deferred | Review manually |

## Output Formats

### Human-Readable (Default)

```
Spec Falsification Report: docs/specifications/my-feature.md
============================================================

  94 claims extracted, 40 survived, 9 falsified, 45 not testable

  Health Score: 0.62 (FAIR)

  FALSIFIED Claims:
  ─────────────────
  [P1] Line 142: "SHOULD use trueno-rag for vector search"
       Category: CodeEntity
       Evidence: Entity 'trueno-rag' not found in codebase
       Suggestion: Update spec or implement trueno-rag integration

  [P2] Line 87: Schema at `docs/schemas/claim.json`
       Category: PathReference
       Evidence: Path does not exist
       Similar: docs/schemas/receipt.json
```

### JSON Output

```bash
pmat falsify docs/specifications/my-feature.md --format json 2>/dev/null
```

```json
{
  "file": "docs/specifications/my-feature.md",
  "total_claims": 94,
  "survived": 40,
  "falsified": 9,
  "not_testable": 45,
  "skipped": 0,
  "health_score": 0.62,
  "verdicts": [
    {
      "claim": "SHOULD use trueno-rag for vector search",
      "line": 142,
      "category": "CodeEntity",
      "priority": "P1",
      "status": "Falsified",
      "evidence": "Entity 'trueno-rag' not found in codebase"
    }
  ]
}
```

## Health Score

The health score (0.0 to 1.0) is calculated as:

```
health = survived / (survived + falsified)
```

Claims that are `NotTestable` or `Skipped` are excluded from the calculation. This means a spec with many vague claims won't get a high score just because those claims can't be disproven.

| Score Range | Rating | Meaning |
|-------------|--------|---------|
| 0.90 - 1.00 | Excellent | Spec is highly aligned with codebase |
| 0.75 - 0.89 | Good | Minor drift, review falsified claims |
| 0.50 - 0.74 | Fair | Significant drift, update needed |
| 0.00 - 0.49 | Poor | Spec is largely contradicted by code |

## Directory Mode

Falsify all specs in a directory at once:

```bash
# Scan entire specifications directory
pmat falsify docs/specifications/

# Only show failures across all specs
pmat falsify docs/specifications/ --failures-only
```

The engine collects all `.md`, `.yaml`, and `.yml` files recursively and produces a report for each.

## Integration with Work System

The `pmat falsify` command integrates with the work system in two ways:

### Work Item Falsification

When given a work item ID instead of a file path, the command delegates to the existing work contract falsification system:

```bash
# Falsify a work item's contract claims
pmat falsify GH-123

# With overrides
pmat falsify GH-123 --override-claims "claim-1,claim-2" --ticket "DEBT-456"
```

### Spec Falsification in Work Complete

The `pmat work complete` command automatically runs falsification on any linked specification files as part of the quality gate. See [Chapter 34](ch34-00-workflow-management.md) for details on the work contract system and falsification ledger.

## CI/CD Integration

Add spec falsification to your CI pipeline:

```yaml
# .github/workflows/quality.yml
- name: Falsify Specifications
  run: |
    pmat falsify docs/specifications/ --format json --failures-only 2>/dev/null > falsify.json
    FALSIFIED=$(jq '.verdicts | map(select(.status == "Falsified")) | length' falsify.json)
    if [ "$FALSIFIED" -gt 0 ]; then
      echo "::error::$FALSIFIED spec claims falsified by codebase"
      jq '.verdicts[] | select(.status == "Falsified")' falsify.json
      exit 1
    fi
```

## Dry Run Mode

Use `--dry-run` to see what claims would be extracted without running falsification:

```bash
pmat falsify docs/specifications/my-feature.md --dry-run
```

```
Dry Run: 94 claims extracted from docs/specifications/my-feature.md
─────────────────────────────────────────────────────────────────────

  [P0] Line 14: "MUST use SQLite for storage" (Requirement)
  [P1] Line 42: Path `src/services/cache.rs` (PathReference)
  [P1] Line 87: Entity `FalsificationEngine` (CodeEntity)
  [P2] Line 123: "SHOULD return within 200ms" (MetricClaim)
  ...
```

## Comparison with Related Commands

| Command | Purpose | Input | Focus |
|---------|---------|-------|-------|
| `pmat falsify` | Falsify spec claims | Spec files, work items | Disconfirming evidence |
| `pmat validate-readme` | Validate README accuracy | README.md | Confirmation of claims |
| `pmat work complete` | Gate work completion | Work contract | Contract claim verification |
| `pmat popper-score` | Score falsifiability | Project-wide | Falsifiability measurement |
| `pmat spec score` | Score spec quality | Spec file | Structural quality (95-point) |

## Summary

The `pmat falsify` command brings Popperian epistemology to specification management:

- Automatically extracts falsifiable claims from specs using RFC-2119 keywords, path references, code entities, and more
- Actively searches for **disconfirming** evidence rather than confirming matches
- Reports per-claim verdicts with evidence and suggestions
- Supports JSON output for CI/CD integration
- Works on individual files or entire directories
- Integrates with the work system for automated quality gates

For the underlying philosophy, see [Chapter 37: Popper Falsifiability Score](ch37-00-popper-score.md). For work system integration, see [Chapter 34: Unified Workflow Management](ch34-00-workflow-management.md).
