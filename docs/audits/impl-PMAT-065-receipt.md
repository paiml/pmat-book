# PMAT-065 implementation receipt (#65)

## What changed

`.github/workflows/gate.yml` adds two jobs:

- `book-build`: installs mdBook v0.4.40 (the version `pages.yml` deploys with),
  runs `mdbook build`, and fails when `book/index.html` is missing or the book
  has one HTML page or fewer.
- `gate`: a fan-in with `if: always()` and `needs: [book-build]`. It fails when
  `needs` is empty, and when any needed job's result is not `success`
  (failure, cancelled and skipped all fail it).

The `main` ruleset requires a check named `gate`. Before this file no workflow
on main had a job by that name, so no PR could merge.

## Planted controls (measured on GitHub Actions, 2026-10-14)

Each planted branch is `fix/gate-job` plus a push trigger for
`planted/PMAT-065-*`. They are not for merge.

| branch | change | run id | book-build | gate | expected |
|---|---|---|---|---|---|
| planted/PMAT-065-green | trigger only | 38635295391 | success | success | PASS |
| planted/PMAT-065-red | SUMMARY.md lists a missing chapter | 38635300918 | failure (`Chapter file not found, ch99-planted-missing.md`) | failure (`1 of 1 needed job(s) did not succeed`) | FAIL |
| planted/PMAT-065-vacuous | `needs: []` | 38635306647 | success | failure (`gate needs no jobs`) | FAIL |

`fix/gate-job` itself has no run yet: its triggers are `pull_request` and
`merge_group` on main, `push` to main, and manual `workflow_dispatch`, so it
first runs on its own when its PR opens.
The green control is the same tree with one trigger line added.

## Scope question for reviewers

The gate needs `book-build` only. The link check (#58), `mdbook test`, the
`test.yml` chapter matrix (#53, #56) and `pmat-dogfood.yml` have never had a
green run on main. A check joins the gate only after three green nights on
main and an owner's explicit yes; until then it cannot block a merge. Is
gating on `book-build` alone right? Answer in your summary.

## Out of scope

No ruleset is changed. No other workflow is changed.

## Quorum rounds (author claude-opus-5-5; no Opus lane)

- Round A, planted control: `needs: []` on top of 3a4925f (local commit
  02e97f5, not for merge). gemini-4-argon-high, claude-sonnet-5-5 and
  claude-haiku-4-5 each returned FAIL naming `.github/workflows/gate.yml:78`.
  Artifact: `docs/audits/quorum-PMAT-065-A-control.json`.
- Round B, the real diff at 3a4925f: the same three lanes returned PASS. All
  three answered the scope question: gating on `book-build` alone is right.
  Artifact: `docs/audits/quorum-PMAT-065-B.json`. Its one note (this receipt
  left out `workflow_dispatch`) is fixed above.
- Sign-off: a separate round with a different lane set, bound to the commit
  that adds this section. Artifact: `docs/audits/quorum-PMAT-065-signoff.json`.
