# Chapter 34: Unified GitHub/YAML Workflow Management

The `pmat work` command suite provides a unified workflow management system that seamlessly integrates GitHub Issues with local YAML tracking. This hybrid write-through architecture enables both online and offline work, with automatic synchronization when online.

## Overview

The workflow system supports:
- **GitHub Integration**: Fetch issue metadata from GitHub automatically
- **Offline Mode**: Work entirely in YAML without a GitHub account
- **Hybrid Tracking**: Track both GitHub issues and YAML-only tickets
- **Auto-Detection**: Automatically detect your GitHub repository from git remote
- **Acceptance Criteria Parsing**: Extract checklists from GitHub issue bodies
- **Specification Generation**: Create linked specification templates
- **Progress Tracking**: Monitor completion percentage across all work items

## Quick Start

### Initialize Your Workflow

```bash
# Auto-detect GitHub repository from git remote
pmat work init

# Or specify repository manually
pmat work init --github-repo owner/repo

# Disable GitHub integration (YAML-only mode)
pmat work init --no-github
```

**Example Output:**
```
🚀 Initializing unified GitHub/YAML workflow...

✅ Created roadmap: ./docs/roadmaps/roadmap.yaml

📋 Configuration:
   GitHub integration: ✅ enabled
   GitHub repository: paiml/pmat

🎯 Next steps:
   1. Create GitHub issue or edit roadmap.yaml
   2. Start work: pmat work start <issue-number-or-ticket-id>
   3. Continue: pmat work continue <id>
   4. Complete: pmat work complete <id>
```

## Core Commands

### `pmat work start`

Start work on a GitHub issue or create a new YAML ticket.

**GitHub Issue (with API Integration):**
```bash
# Fetch GitHub issue #75 metadata
pmat work start 75

# Fetch issue and create specification template
pmat work start 75 --with-spec

# Create GitHub issue from YAML ticket
pmat work start my-feature --create-github
```

**YAML Ticket (Offline Mode):**
```bash
# Create YAML-only ticket
pmat work start implement-caching

# Create with specification template
pmat work start implement-caching --with-spec
```

**Example Output (GitHub Issue):**
```
🚀 Starting work on: 75

📋 Type: GitHub issue #75
   ✅ Fetched from GitHub: Unified GitHub/YAML workflow
   ✅ Extracted 44 acceptance criteria
✅ Updated roadmap: ./docs/roadmaps/roadmap.yaml

🎯 Next steps:
   1. Review specification (if created)
   2. Write failing tests (RED phase)
   3. Implement feature (GREEN phase)
   4. Refactor (REFACTOR phase)
   5. Continue: pmat work continue 75
   6. Complete: pmat work complete 75
```

### `pmat work continue`

Resume work on an existing task with progress display.

```bash
# Continue work on GH-75
pmat work continue GH-75

# Continue YAML ticket
pmat work continue my-feature
```

**Example Output:**
```
🔄 Continuing work on: GH-75

📊 Progress: 50% complete
   Status: InProgress
   Title: Unified GitHub/YAML workflow

🎯 Next steps:
   Continue working on: Unified GitHub/YAML workflow
   When done: pmat work complete GH-75
```

### `pmat work complete`

Mark work as complete and get next steps.

```bash
# Complete work (runs quality gates by default)
pmat work complete GH-75

# Skip quality gates (for testing)
pmat work complete GH-75 --skip-quality
```

**Example Output:**
```
✅ Completing work on: GH-75

✅ Marked as complete: Unified GitHub/YAML workflow
✅ Updated roadmap: ./docs/roadmaps/roadmap.yaml

🎯 Next steps:
   1. Create commit: git commit -m "feat: Unified GitHub/YAML workflow (Refs GH-75)"
   2. Close GitHub issue: gh issue close 75
```

### `pmat work status`

View all work items and their progress.

```bash
# View all items
pmat work status

# View active items only
pmat work status --active

# View specific item
pmat work status GH-75
```

**Example Output:**
```
📋 Roadmap items: 2 total

   ✅ ml-model-serialization - ML model serialization (100%)
   ⏳ GH-75 - Unified GitHub/YAML workflow (50%)
      GitHub: #75
```

### `pmat work sync`

Synchronize GitHub and YAML (planned for Phase 6).

```bash
# Full bidirectional sync
pmat work sync --dry-run

# Sync YAML to GitHub
pmat work sync --direction yaml-to-github

# Sync GitHub to YAML
pmat work sync --direction github-to-yaml
```

## GitHub API Integration

### Authentication

The workflow system uses the `GITHUB_TOKEN` environment variable for GitHub API access.

**Set your GitHub token:**
```bash
# Personal Access Token (classic)
export GITHUB_TOKEN=ghp_your_token_here

# Or use GitHub CLI
gh auth status  # Verify authenticated
```

**Rate Limits:**
- **Authenticated**: 5,000 requests/hour
- **Unauthenticated**: 60 requests/hour (read-only)

### Fetching Issue Metadata

When you run `pmat work start <issue-number>`, the system:

1. **Fetches Issue Details**: Title, labels, body, state
2. **Parses Acceptance Criteria**: Extracts markdown checklists
3. **Auto-Links to Roadmap**: Creates `GH-<number>` identifier
4. **Updates YAML**: Stores metadata locally

**Example Acceptance Criteria Parsing:**

GitHub Issue Body:
```markdown
## Acceptance Criteria

- [ ] Design YAML schema
- [ ] Implement parser with serde
- [ ] Add GitHub API client
- [x] Write unit tests
```

Roadmap YAML:
```yaml
acceptance_criteria:
  - Design YAML schema
  - Implement parser with serde
  - Add GitHub API client
  - Write unit tests
```

### Error Handling

The system gracefully handles errors:

- **No GITHUB_TOKEN**: Falls back to unauthenticated mode (rate-limited)
- **API Failure**: Creates placeholder, syncs later
- **Network Offline**: Works entirely in YAML mode

## Roadmap YAML Structure

The roadmap is stored in `docs/roadmaps/roadmap.yaml`:

```yaml
roadmap_version: '1.0'
github_enabled: true
github_repo: paiml/pmat
roadmap:
  - id: GH-75
    github_issue: 75
    item_type: task
    title: Unified GitHub/YAML workflow
    status: inprogress
    priority: medium
    assigned_to: null
    created: 2025-11-19T10:00:00Z
    updated: 2025-11-19T10:30:00Z
    spec: docs/specifications/075-spec.md
    acceptance_criteria:
      - Design YAML schema
      - Implement parser
    phases: []
    subtasks: []
    estimated_effort: null
    labels:
      - enhancement
      - workflow
```

### Item Status Values

- `planned`: Not yet started (0% progress)
- `inprogress`: Currently being worked on (50% progress)
- `completed`: Finished (100% progress)
- `blocked`: Cannot proceed (0% progress)
- `onhold`: Paused temporarily (previous progress)

### Priority Levels

- `low`: Nice to have
- `medium`: Standard priority
- `high`: Important
- `critical`: Urgent

## Specification Templates

The `--with-spec` flag generates a specification template:

**Filename Convention:**
- GitHub issues: `docs/specifications/075-spec.md`
- YAML tickets: `docs/specifications/feature-name-spec.md`

**Template Structure:**
```markdown
---
title: Feature Name
issue: GH-75
status: In Progress
created: 2025-11-19T10:00:00Z
updated: 2025-11-19T10:00:00Z
---

# Feature Name Specification

**Ticket ID**: GH-75
**Status**: In Progress

## Summary

[Brief overview of what this work accomplishes]

## Requirements

### Functional Requirements
- [ ] Requirement 1
- [ ] Requirement 2

### Non-Functional Requirements
- [ ] Performance: [target]
- [ ] Test coverage: ≥85%

## Architecture

### Design Overview

[High-level design approach]

### API Design

\`\`\`rust
// Example API design
pub struct Example {
    // ...
}
\`\`\`

## Implementation Plan

### Phase 1: Foundation
- [ ] Task 1
- [ ] Task 2

### Phase 2: Core Implementation
- [ ] Task 3
- [ ] Task 4

## Testing Strategy

### Unit Tests
- [ ] Test case 1

### Integration Tests
- [ ] Integration test 1

## Success Criteria

- ✅ All acceptance criteria met
- ✅ Test coverage ≥85%
- ✅ Zero clippy warnings
- ✅ Documentation complete

## References

- [Related documentation]
```

## Workflow Examples

### Example 1: GitHub Issue Workflow

```bash
# 1. Initialize workflow
pmat work init
# ✅ Auto-detected: paiml/pmat

# 2. Start work on GitHub issue
pmat work start 75 --with-spec
# ✅ Fetched: "Unified GitHub/YAML workflow"
# ✅ Created: docs/specifications/075-spec.md

# 3. Work on the feature
# ... implement code, write tests ...

# 4. Continue work (shows progress)
pmat work continue GH-75
# 📊 Progress: 50%

# 5. Complete work
pmat work complete GH-75
# ✅ Marked complete
# 🎯 Next: git commit, gh issue close 75
```

### Example 2: YAML-Only Workflow (Offline)

```bash
# 1. Initialize without GitHub
pmat work init --no-github

# 2. Create YAML ticket
pmat work start implement-caching --with-spec
# ✅ Created: YAML ticket
# ✅ Created: docs/specifications/implement-caching-spec.md

# 3. Work on the feature
# ... implement code ...

# 4. Complete work
pmat work complete implement-caching --skip-quality
# ✅ Marked complete (100%)

# 5. View all work
pmat work status
# 📋 1 total: ✅ implement-caching (100%)
```

### Example 3: Hybrid Workflow

```bash
# 1. Initialize with GitHub
pmat work init

# 2. Create YAML ticket first
pmat work start add-metrics --with-spec
# ✅ YAML ticket created

# 3. Create GitHub issue from YAML
pmat work start add-metrics --create-github
# 🔄 Creating GitHub issue...
# ✅ Created GitHub issue #123
# ✅ Linked as GH-123

# 4. Continue work
pmat work continue GH-123

# 5. Complete
pmat work complete GH-123
```

## Progress Tracking

The system automatically calculates completion percentage:

### Status-Based Progress
- `planned`: 0%
- `inprogress`: 50%
- `completed`: 100%
- `blocked`: 0%
- `onhold`: Previous progress maintained

### Subtask-Based Progress
When subtasks are defined, progress is calculated from subtask completion:

```yaml
subtasks:
  - name: Write tests
    completion: 100
  - name: Implement feature
    completion: 50
  - name: Add documentation
    completion: 0

# Overall progress: (100 + 50 + 0) / 3 = 50%
```

### Phase-Based Progress
When phases are defined, progress is averaged across phases:

```yaml
phases:
  - name: Foundation
    completion: 100
  - name: Core Implementation
    completion: 50

# Overall progress: (100 + 50) / 2 = 75%
```

## Best Practices

### 1. Initialize Early
Run `pmat work init` at the start of your project to enable tracking from the beginning.

### 2. Use Specifications
Always use `--with-spec` for non-trivial features to document your design.

### 3. Track Progress
Regularly run `pmat work status` to monitor progress across all work items.

### 4. Commit References
Include work item references in commit messages:
```bash
git commit -m "feat: Add caching layer (Refs GH-123)"
```

### 5. Close Issues
After completing work on a GitHub issue, close it:
```bash
gh issue close 123  # Or via GitHub web UI
```

### 6. Sync Regularly
When working with GitHub, sync frequently to avoid conflicts:
```bash
pmat work sync --dry-run  # Preview changes
pmat work sync             # Apply sync
```

## Troubleshooting

### GitHub Token Not Found

**Error:**
```
GITHUB_TOKEN environment variable not set
```

**Solution:**
```bash
# Set token (Personal Access Token)
export GITHUB_TOKEN=ghp_your_token_here

# Or use GitHub CLI
gh auth login
```

### Issue Not Found

**Error:**
```
Failed to fetch issue #999
```

**Causes:**
- Issue number doesn't exist
- Issue is in a different repository
- No access to private repository

**Solution:**
```bash
# Verify issue exists
gh issue view 999

# Check repository configuration
cat docs/roadmaps/roadmap.yaml | grep github_repo
```

### Rate Limit Exceeded

**Error:**
```
API rate limit exceeded
```

**Solution:**
- Wait for rate limit reset (1 hour)
- Use authenticated requests (set GITHUB_TOKEN)
- Reduce API calls (use offline mode)

### Roadmap Not Found

**Error:**
```
Failed to load roadmap. Run `pmat work init` first.
```

**Solution:**
```bash
# Initialize workflow
pmat work init
```

## Integration with EXTREME TDD

The workflow system integrates seamlessly with PMAT's EXTREME TDD methodology:

### RED Phase: Start Work
```bash
pmat work start feature-name --with-spec
# ✅ Specification created
# Now write failing tests
```

### GREEN Phase: Implement
```bash
pmat work continue feature-name
# 📊 Progress: 50%
# Implement feature to make tests pass
```

### REFACTOR Phase: Complete
```bash
pmat work complete feature-name
# ✅ Runs quality gates
# ✅ Ensures test coverage ≥85%
# ✅ Checks clippy warnings
```

## Multi-Agent Concurrency Safety

**Version**: Added in PMAT v2.201.0
**Technology**: Cross-platform file locking via `fs2` crate

The workflow system implements production-grade concurrency safety to support multiple AI sub-agents working simultaneously on the same roadmap. This is essential for agentic workflows where several agents may be updating work items concurrently.

### The Problem: Race Conditions

Without file locking, concurrent writes cause data loss:

```
Agent A: Load roadmap (2 items)
Agent B: Load roadmap (2 items)      ← Same data
Agent A: Add item C (3 items)
Agent B: Add item D (3 items)        ← Different item
Agent A: Save roadmap (items: A, B, C)
Agent B: Save roadmap (items: A, B, D)  ← OVERWRITES Agent A's work!
Result: Item C is LOST ❌
```

### The Solution: Atomic Operations with File Locking

PMAT uses the `fs2` crate for cross-platform file locking:

**Lock File**: `roadmap.yaml.lock` (created automatically alongside `roadmap.yaml`)

**Lock Types**:
- **Shared Locks** (Read operations): Multiple concurrent readers allowed
  - `load()`, `find_item()`, `status` commands
- **Exclusive Locks** (Write operations): Blocks all other readers and writers
  - `save()`, `upsert_item()`, `start`, `continue`, `complete` commands

**Atomic Read-Modify-Write**:
```
Agent A: Acquire EXCLUSIVE lock 🔒
Agent A: Load roadmap (2 items)
Agent B: Try to acquire lock → WAITS ⏳
Agent A: Add item C (3 items)
Agent A: Save roadmap
Agent A: Release lock 🔓
Agent B: Acquire lock ✅
Agent B: Load roadmap (3 items)    ← Sees Agent A's changes
Agent B: Add item D (4 items)
Agent B: Save roadmap
Agent B: Release lock 🔓
Result: Both items preserved ✅
```

### Concurrency Guarantees

✅ **Zero Data Loss**: All concurrent writes succeed, no overwrites
✅ **Cross-Process Safety**: Works across multiple `pmat` processes
✅ **Cross-Platform**: Linux, macOS, Windows via `fs2` crate
✅ **Deadlock-Free**: RAII pattern ensures locks always released
✅ **Graceful Blocking**: Agents wait for lock, don't fail

### Performance Characteristics

**Lock Contention**: Sequential bottleneck by design
- **Write time**: ~1-5ms (YAML serialize + disk write)
- **10 agents**: ~50ms total (sequential, not parallel)
- **Trade-off**: Correctness > Performance (appropriate for CLI tool)

**Read Performance**: Concurrent reads have no contention (shared locks)

### Testing Validation

The concurrent safety is validated with comprehensive tests:

```bash
# Test 10 threads writing simultaneously
cargo test test_concurrent_operations

# Result: ✅ All 10 items present (no overwrites)
```

**Test Code** (`server/src/services/roadmap_service.rs`):
```rust
#[test]
fn test_concurrent_operations() {
    // Spawn 10 threads writing simultaneously
    for i in 0..10 {
        thread::spawn(|| {
            service.upsert_item(item_i).unwrap();
        });
    }

    // ✅ All 10 items present
    assert_eq!(roadmap.roadmap.len(), 10);
}
```

### Automatic and Transparent

**No user action required**:
- File locking happens automatically
- Lock files are created/cleaned up automatically
- Agents seamlessly coordinate via filesystem

**Typical Usage** (unchanged):
```bash
# Agent 1
pmat work start feature-a

# Agent 2 (simultaneously)
pmat work start feature-b

# Both succeed, no conflicts ✅
```

### When Locks Are Held

**Read Operations** (Shared Lock):
- `pmat work status` - Very brief (< 1ms)
- `pmat work continue` - Very brief (< 1ms)

**Write Operations** (Exclusive Lock):
- `pmat work start` - Brief (~1-5ms)
- `pmat work complete` - Brief (~1-5ms)

**Lock Duration**: Microseconds to milliseconds - users won't notice blocking

### Implementation Details

**Lock File Management**:
- Lock file: `docs/roadmaps/roadmap.yaml.lock`
- Created automatically on first use
- Never manually deleted (safe to leave)
- Size: 0 bytes (empty file, only used for locking)

**RAII Pattern**:
```rust
fn upsert_item(&self, item: RoadmapItem) -> Result<()> {
    let _lock = self.acquire_write_lock()?;  // 🔒 Lock acquired

    // ... read, modify, write ...

    Ok(())
    // 🔓 Lock automatically released when _lock drops
}
```

### Comparison with Other Approaches

| Approach | Data Safety | Performance | Complexity |
|----------|-------------|-------------|------------|
| **No Locking** | ❌ Data loss | ⚡ Fast | ✅ Simple |
| **Optimistic Locking** | ⚠️ Retry needed | ⚡ Fast | ⚠️ Medium |
| **File Locking (PMAT)** | ✅ Guaranteed | ✅ Adequate | ✅ Simple |
| **Database** | ✅ Guaranteed | ⚡ Fast | ❌ Complex |

**Why File Locking**: Best balance of safety, simplicity, and performance for a CLI tool.

### Multi-Agent Workflow Example

**Scenario**: 5 AI sub-agents working on different features simultaneously

```bash
# Terminal 1 - Agent working on authentication
pmat work start auth-system --with-spec
# 🔒 Lock acquired, item created, lock released

# Terminal 2 - Agent working on database (simultaneous)
pmat work start database-layer --with-spec
# ⏳ Waits for Terminal 1's lock
# 🔒 Lock acquired, item created, lock released

# Terminal 3 - Agent checking status (simultaneous)
pmat work status
# 🔒 Shared lock acquired (doesn't block)
# 📋 Shows: auth-system, database-layer
# 🔓 Shared lock released

# Terminal 4 & 5 - More agents (simultaneous)
pmat work start api-endpoints --with-spec
pmat work start testing-framework --with-spec

# Result: ✅ All 5 items created successfully, no data loss
```

### Future Enhancements (Planned)

### Pre-commit Hooks (Phase 6)
Automatically validate commit messages reference work items:
```bash
# Valid
git commit -m "feat: Add feature (Refs GH-75)"

# Invalid (blocked by hook)
git commit -m "Add feature"
```

### CHANGELOG Auto-Update (Phase 7)
Automatically update CHANGELOG.md from issue labels:
```bash
pmat work complete GH-75
# ✅ Added to CHANGELOG.md:
#    ## [Unreleased]
#    ### Added
#    - Unified GitHub/YAML workflow (#75)
```

### Quality Gates Integration (Phase 8)
Run quality gates before completion:
```bash
pmat work complete GH-75
# 🔄 Running quality gates...
# ✅ Tests passing
# ✅ Coverage ≥85%
# ✅ Zero clippy warnings
# ✅ Marked complete
```

### Epic Support (Phase 9)
Track epics with subtasks:
```bash
pmat work start 100 --epic
# ✅ Created epic: GH-100
# 📋 Subtasks:
#    - GH-101: Design
#    - GH-102: Implementation
#    - GH-103: Testing
```

## Summary

The `pmat work` command suite provides a powerful, flexible workflow management system that:

- ✅ Integrates GitHub Issues and YAML tracking
- ✅ Works offline without internet connection
- ✅ Auto-detects your GitHub repository
- ✅ Fetches real issue metadata via API
- ✅ Tracks progress automatically
- ✅ Generates specification templates
- ✅ Provides beautiful CLI output
- ✅ **Multi-agent concurrency safety** (v2.201.0+) - Multiple AI sub-agents can work simultaneously without data loss

**Next Steps:**
- Run `pmat work init` to get started
- Create your first work item with `pmat work start`
- Track progress with `pmat work status`
- Complete work with `pmat work complete`

For more details, see:
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md) - Quality gate integration
- [Chapter 9: Pre-commit Hooks](ch09-00-precommit-hooks.md) - Hook management
- [Appendix B: Command Reference](appendix-b-commands.md) - Full command list
