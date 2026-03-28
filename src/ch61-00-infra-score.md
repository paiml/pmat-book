# Chapter 61: Infrastructure Score (`pmat infra-score`)

The Infrastructure Score evaluates CI/CD pipeline quality across GitHub Actions workflows,
scoring projects on a 0-100 scale (with 10 bonus points for provable contracts). This
command was introduced in PMAT v3.8.0 and reflects the Toyota Production System principle
that build infrastructure is the foundation of software quality.

## Scoring Categories

| Category | Points | What It Measures |
|----------|--------|-----------------|
| Workflow Architecture | 25 | Matrix strategy, concurrency groups, gate jobs, branch protection |
| Build Reliability | 25 | CI success rate, no `continue-on-error`, deterministic builds, caching, pinned actions |
| Quality Pipeline | 20 | Test jobs, lint jobs, coverage reporting, security audit, format checks |
| Deployment & Release | 15 | Release workflows, cross-platform, release automation, registry publishing, semver |
| Supply Chain Security | 15 | Branch protection, no hardcoded secrets, dependency review, SLSA provenance, signed commits |
| Provable Contracts (bonus) | 10 | `pv lint`, contract score, proof level, contracts directory |

**Hard cutoff**: Projects scoring below 90 receive an auto-fail status.

## Quick Start

```bash
# Score the current project
pmat infra-score

# JSON output for CI/CD integration
pmat infra-score --format json

# Show only failures and recommendations
pmat infra-score --failures-only

# Score a different project
pmat infra-score --path /path/to/repo
```

## Sample Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Infra Score v1.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary
  Score: 93.0/100.0
  Grade: A
  Status: PASS

Categories
  ✓ Workflow Architecture: 25.0/25.0 (100.0%)
  ⚠ Build Reliability: 20.0/25.0 (80.0%)
  ✓ Quality Pipeline: 20.0/20.0 (100.0%)
  ✓ Deployment & Release: 15.0/15.0 (100.0%)
  ⚠ Supply Chain Security: 13.0/15.0 (86.7%)

Findings
  ✗ [BR-01]: 0/10 runs succeeded (0%) — need >=90%
  ℹ [SC-05]: No signed commits configuration found.

Recommendations
  BR-01: 0/10 runs succeeded (0%) — need >=90% (+5 pts, ~30 minutes)
  SC-05: No signed commits configuration found (+2 pts, ~5 minutes)
```

## Check Reference

### Workflow Architecture (WA)

| Check | Points | Description |
|-------|--------|-------------|
| WA-01 | 5 | Matrix build strategy (`matrix:` in workflows) |
| WA-02 | 5 | Minimum 2 workflow files for separation of concerns |
| WA-03 | 5 | Reusable workflows (`uses: ./.github/workflows/`) |
| WA-04 | 3 | Concurrency groups with `cancel-in-progress` |
| WA-05 | 3 | Gate job with `if: always()` for required status checks |
| WA-06 | 2 | Branch protection (PR triggers on `main`/`master`) |
| WA-07 | 2 | Required status check patterns |

### Build Reliability (BR)

| Check | Points | Description |
|-------|--------|-------------|
| BR-01 | 5 | CI success rate >= 90% (checks last 10 GitHub Actions runs) |
| BR-02 | 5 | No `continue-on-error: true` on test/lint jobs |
| BR-03 | 5 | Deterministic builds (`--locked`, `CARGO_INCREMENTAL=0`) |
| BR-04 | 3 | Build caching (`actions/cache`, `sccache`) |
| BR-05 | 3 | Pinned action versions (SHA or specific version tags) |
| BR-06 | 2 | No `\|\| true` escape hatches in test/lint steps |
| BR-07 | 2 | `timeout-minutes` configured on jobs |

### Quality Pipeline (QP)

| Check | Points | Description |
|-------|--------|-------------|
| QP-01 | 5 | Test job (`cargo test`, `pytest`, etc.) |
| QP-02 | 5 | Lint job (`cargo clippy`, `eslint`, etc.) |
| QP-03 | 4 | Coverage reporting (`cargo llvm-cov`, `codecov`) |
| QP-04 | 3 | Security audit (`cargo audit`, `npm audit`) |
| QP-05 | 3 | Format check (`cargo fmt --check`, `prettier`) |

### Deployment & Release (DR)

| Check | Points | Description |
|-------|--------|-------------|
| DR-01 | 5 | Release/nightly workflow with schedule trigger |
| DR-02 | 3 | Cross-platform builds (>= 2 OS targets) |
| DR-03 | 3 | Automated release (action-gh-release, cargo publish) |
| DR-04 | 2 | Registry publishing (Cargo.toml with version) |
| DR-05 | 2 | Semantic versioning (x.y.z pattern, workspace-inherited OK) |

### Supply Chain Security (SC)

| Check | Points | Description |
|-------|--------|-------------|
| SC-01 | 3 | Branch protection (PR trigger on main branches) |
| SC-02 | 3 | No hardcoded secrets (detects API keys, tokens) |
| SC-03 | 3 | Dependency review tool (dependabot, renovate) |
| SC-04 | 2 | SLSA provenance or attestation |
| SC-05 | 2 | Signed commits configuration |
| HD-01 | 2 | No dangerous context interpolation in `run:` blocks |

### Provable Contracts Bonus (PV)

| Check | Points | Description |
|-------|--------|-------------|
| PV-01 | 3 | `pv lint contracts/` passes |
| PV-02 | 3 | Contract score >= 0.5 |
| PV-03 | 2 | Proof level L2+ |
| PV-04 | 2 | `contracts/` directory exists |

## Sovereign CI Credit

Projects using the `sovereign-ci.yml` reusable workflow automatically receive implied
credit for checks that the shared workflow guarantees (deterministic builds, caching,
pinned actions, test/lint/coverage/format, SLSA provenance).

## CI/CD Integration

```yaml
# .github/workflows/quality.yml
- name: Check infra score
  run: |
    pmat infra-score --format json -o infra-report.json
    score=$(jq '.score' infra-report.json)
    if (( $(echo "$score < 90" | bc -l) )); then
      echo "::error::Infra score $score < 90"
      exit 1
    fi
```

## Cross-Repo Analysis

Use `pmat stack status` to check infra scores across the entire sovereign AI stack:

```bash
# Check all batuta stack repos
for repo in aprender trueno trueno-graph trueno-db; do
  echo "$repo: $(cd ~/src/$repo && pmat infra-score --format json | jq -r '.grade')"
done
```
