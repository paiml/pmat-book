# Chapter 66: Kaizen Roadmap — R4 Research Tickets (KAIZEN-0017..0044)

In the pmat project, *kaizen* (改善, "continuous improvement") refers to a structured, evidence-driven backlog of enhancements derived from external research rather than internal feature planning. Round 4 of this research — tracked in GitHub issue [#337](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/337) and opened on 2026-04-18 — indexes 28 new tickets (`KAIZEN-0017` through `KAIZEN-0044`). Seventeen tickets originate from newly published arxiv papers in the 2604 series (post-dating the R1/R2/R3 rounds); eleven come from integration gaps exposed by Claude Code 3.7+ changelogs (v2.1.84 through v2.1.113). Each ticket maps a specific research finding or upstream feature to a concrete pmat capability, and this chapter catalogs them so book readers can trace proposed commands and MCP tools back to their scientific or product justification.

## Ticket Index (KAIZEN-0017..0044)

| # | Title | Source (arxiv ID or CC feature) | Priority | Status |
|---|---|---|---|---|
| KAIZEN-0017 | AgentOpt UCB-E model selection | [arxiv:2604.06296](https://arxiv.org/abs/2604.06296) | M | Proposed |
| KAIZEN-0018 | Local-Splitter 7 tactics (45-79% token savings) | [arxiv:2604.12301](https://arxiv.org/abs/2604.12301) | M | Proposed |
| KAIZEN-0019 | SkillMOO NSGA-II optimization | [arxiv:2604.09297](https://arxiv.org/abs/2604.09297) | M | Proposed |
| KAIZEN-0020 | TSUBASA long-horizon memory distillation | [arxiv:2604.07894](https://arxiv.org/abs/2604.07894) | S | Proposed |
| KAIZEN-0021 | ContextCurator RL entropy-reducing policy | [arxiv:2604.11462](https://arxiv.org/abs/2604.11462) | M | Proposed |
| KAIZEN-0022 | ClawVM harness-managed typed pages | [arxiv:2604.10352](https://arxiv.org/abs/2604.10352) | M | Proposed |
| KAIZEN-0023 | ClawGuard runtime MCP middleware | [arxiv:2604.11790](https://arxiv.org/abs/2604.11790) | S | Proposed |
| KAIZEN-0024 | MCP-DPT 6-layer defense taxonomy | [arxiv:2604.07551](https://arxiv.org/abs/2604.07551) | S | Proposed |
| KAIZEN-0025 | Compiler-LLM cooperation for hot functions | [arxiv:2604.04238](https://arxiv.org/abs/2604.04238) | M | Proposed |
| KAIZEN-0026 | CascadeDebate confidence router (haiku→opus) | [arxiv:2604.12262](https://arxiv.org/abs/2604.12262) | M | Proposed |
| KAIZEN-0027 | Scaffold codegen (react / plan-exec / tree) | [arxiv:2604.03515](https://arxiv.org/abs/2604.03515) | S | Proposed |
| KAIZEN-0028 | Agentic bug taxonomy auto-labeling | [arxiv:2604.08906](https://arxiv.org/abs/2604.08906) | S | Proposed |
| KAIZEN-0029 | Argus SAST multi-agent orchestrator | [arxiv:2604.06633](https://arxiv.org/abs/2604.06633) | M | Proposed |
| KAIZEN-0030 | Beyond-Fluency trajectory verification gates | [arxiv:2604.04269](https://arxiv.org/abs/2604.04269) | S | Proposed |
| KAIZEN-0031 | WebXSkill executable skill mining | [arxiv:2604.13318](https://arxiv.org/abs/2604.13318) | M | Proposed |
| KAIZEN-0032 | AnyPoC universal PoC generator | [arxiv:2604.11950](https://arxiv.org/abs/2604.11950) | M | Proposed |
| KAIZEN-0033 | CCCE continuous dependency calibration | [arxiv:2604.13102](https://arxiv.org/abs/2604.13102) | M | Proposed |
| KAIZEN-0034 | `PreCompact` hook for `.pmat-work/` snapshots | CC v2.1.105 changelog | S | Proposed |
| KAIZEN-0035 | Hardened `Bash(pmat *)` denyRules | CC v2.1.113 changelog | S | Proposed |
| KAIZEN-0036 | `sandbox.network.deniedDomains` blocklist | CC v2.1.113 changelog | S | Proposed |
| KAIZEN-0037 | `/effort xhigh` advisor for pmat tasks | CC v2.1.111 changelog | S | Proposed |
| KAIZEN-0038 | Session recap (`pmat session-recap`) | CC v2.1.108 changelog | S | Proposed |
| KAIZEN-0039 | `monitors` manifest key for quality monitor | CC v2.1.105 changelog | M | Proposed |
| KAIZEN-0040 | Skill-chain automation via Skill tool | CC v2.1.108 changelog | S | Proposed |
| KAIZEN-0041 | `forceRemoteSettingsRefresh` for team drift | CC v2.1.92 changelog | M | Proposed |
| KAIZEN-0042 | `WorktreeCreate` auto-indexes new worktrees | CC v2.1.84 changelog | S | Proposed |
| KAIZEN-0043 | `pmat observe agents` subagent observability | CC v2.1.97 changelog | M | Proposed |
| KAIZEN-0044 | Skills `paths:` glob scoping for autoload | CC v2.1.84 changelog | S | Proposed |

Effort labels use the same convention as prior rounds: **S** ≈ one-sprint ticket, **M** ≈ multi-sprint with design doc.

## Execution Plan

The 28 tickets cluster into six themes. Sequencing below reflects dependency order and the issue-level triage notes: S-effort Claude Code gaps are queued first because they unblock downstream tickets, while larger arxiv-driven capabilities land after the CC integration surface is stable.

### 1. Claude Code Integration & Hook Ecosystem

- **KAIZEN-0034** — PreCompact hook preserving `.pmat-work/` state
- **KAIZEN-0042** — WorktreeCreate hook triggering `pmat context build --worktree`
- **KAIZEN-0039** — `monitors` manifest entry for background quality monitor
- **KAIZEN-0038** — `pmat session-recap` writing to `.pmat/recap/<date>.md`

These are the minimum-viable hook integrations needed so that pmat state survives compaction and worktree creation across a CC session.

### 2. MCP Conformance & Security

- **KAIZEN-0023** — ClawGuard MCP middleware with allowlist schema
- **KAIZEN-0024** — MCP-DPT audit across pmat's 6 defense layers
- **KAIZEN-0022** — ClawVM typed-page state abstraction (`pmat-state` MCP tool)
- **KAIZEN-0035** — Strict `Bash(pmat *)` denyRules template
- **KAIZEN-0036** — `sandbox.network.deniedDomains` recommendations

Security work must land before external-facing cost optimizations (theme 4) because ClawGuard validates adversarial tool returns that the cascading router would otherwise trust.

### 3. Settings, Skills, and SDK Updates

- **KAIZEN-0044** — `paths:` globs on shipped skills for autoload scoping
- **KAIZEN-0040** — Documented skill chains (coverage-gaps → tests → /compact)
- **KAIZEN-0041** — `pmat settings sync --remote` for managed team settings
- **KAIZEN-0037** — `/effort xhigh` advisor mapping pmat tasks to effort levels

### 4. Cost-Aware Cascading & MOO Delegation

- **KAIZEN-0017** — `pmat agent-opt` UCB-E model selection
- **KAIZEN-0018** — `pmat agent-split --tactics t1,t2,t3` local-route + compress
- **KAIZEN-0019** — `pmat skills-optimize --goals pass,cost,latency` NSGA-II
- **KAIZEN-0026** — `pmat ask --cascade` haiku→sonnet→opus by confidence

Quantified gains from the source papers: 13-32× cost gap (AgentOpt), 45-79% token savings (Local-Splitter), +131% pass rate (SkillMOO), +26.75% Pareto improvement (CascadeDebate).

### 5. Memory Fidelity & Context Curation

- **KAIZEN-0020** — `pmat memory-distill --session <id>` TSUBASA-style distillation
- **KAIZEN-0021** — `pmat context curate --budget 50000` RL entropy reduction
- **KAIZEN-0043** — `pmat observe agents` subagent + MCP-latency tail

### 6. Trajectory Integrity, Scaffolds & Debugging

- **KAIZEN-0027** — `pmat agent scaffold --pattern react|plan-exec|tree`
- **KAIZEN-0030** — `pmat trace verify --gates-per-step` contract validation
- **KAIZEN-0028** — `pmat work classify-bug --taxonomy agentic` auto-label + Five Whys
- **KAIZEN-0031** — `pmat skills-mine --from-history` reusable-sequence mining
- **KAIZEN-0032** — `pmat poc-gen --from-bug-report` regression-grade PoC
- **KAIZEN-0029** — `pmat security-scan --agents argus` Argus SAST orchestrator
- **KAIZEN-0025** — `pmat optimize --cooperate rustc,clippy,miri`
- **KAIZEN-0033** — `pmat deps autopatch --gate auto-validate`

This theme is the R4 "shift from endpoint accuracy to trajectory integrity" — every tool call is a verifiable step, mirroring pmat's existing Five Whys + contract-falsification posture.

## Cross-References

- Round 1–3 tickets (KAIZEN-0001..0016) were indexed in the previous chapter (see [Chapter 55 — Autonomous Continuous Improvement](ch55-00-kaizen.md) for the kaizen execution engine itself).
- Ticket status updates land on the GitHub issue first, then propagate here on each release of the book.
- For ClawVM (KAIZEN-0022), check whether the existing trueno-graph O(1) context layer already satisfies the typed-page requirement before reimplementing.
- For the agentic bug taxonomy (KAIZEN-0028), reconcile the 5-layer taxonomy against the categories already encoded in `pmat five-whys`.
