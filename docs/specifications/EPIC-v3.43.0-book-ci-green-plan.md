# EPIC v3.43.0 — pmat-book CI green (#57)

The book has never been tagged. Its first tag mirrors the next pmat tag,
**v3.43.0** (pmat's last tag is v3.42.0, 2026-09-28). If pmat ships its next
release under a different number, this train takes that number instead; the
book never tags a version pmat has not tagged, and never moves or reuses a tag.

**Goal.** CI reports real results again: every workflow is admitted, runs its
steps, and is green on main, so a tag can be cut from measured evidence.

## Core rows (milestone v3.43.0)

| Row | Item | done_when | Baseline (measured 2026-10-10) | First-green proof |
|---|---|---|---|---|
| C1 | #56 artifact-v3 admission failure (PR #59; #54 is a duplicate of it) | `test.yml` and `pmat-dogfood.yml` jobs start and run steps on main | every job refused at admission | run URL on the merge commit |
| C2 | #10 `pmat analyze <path>` printed 131 times (PR #62) | every printed `pmat analyze` line parses under the pinned pmat (`pmat analyze <sub> --help` exit 0 per line) | 131 lines exit 2 | PR #62 CI run |
| C3 | #9 pmat-dogfood pins pmat 2.69.0 | `pmat-dogfood.yml` installs the pmat release this book documents and its link-check step runs | 200/200 runs failed | run URL |
| C4 | #58 18 internal chapter links to missing files | dogfood link-check step green | 18 dead links | same run as C3 |
| C5 | #61 ch01 test_02 asserts removed JSON fields | `make test-ch01` green against the pinned pmat | red | `test.yml` run |

## Release gate (v3.43.0)

1. Open issues labelled `must-carry` on milestone v3.43.0: zero. Everything else
   open on the milestone moves to v3.44.0 (if E2 cites it) or to `backlog`.
2. pmat tag v3.43.0 exists on paiml/paiml-mcp-agent-toolkit.
3. On exactly the commit to be tagged: `pages.yml` (mdbook build), `test.yml`
   and `pmat-dogfood.yml` are green. The book publishes no crate, so there is no
   crates.io step; the Pages deploy is the publish.
4. The cut happens on `release/v3.43.0`; the tag goes on that branch and the
   branch merges back to main. No tag is created, moved or deleted outside a cut.

A check that cannot block a merge or this tag is LAB: one ticket, one owner.

## Workers

- **Core worker**: the five rows above, in order C1, C2, C3+C4, C5.
- **Look-ahead slot (la-v3.44)**: owns E2 and `docs/lookahead/v3.44.0.yaml`.
  Works on branch `la-v3.44/wip`; at most 1 open PR; yields CI queue priority
  during a release pass; proposes new tickets, never mints them. Shed first
  when the token budget runs short; core keeps running.
