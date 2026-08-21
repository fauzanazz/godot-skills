# Contributing to Godot Skills

## Philosophy

This repo publishes a thin runtime — a manifest, an engine guide, and an asset skill — that a coding agent builds games inside. The goal is to generate the best possible games with as little human guidance as possible. Every piece of this repo exists to serve that goal.

The default answer to "should we document this?" is no. The agent is a capable model, `dotnet build` reports anything the compiler can see, and the deliverable surfaces the rest — so the guides carry only silent failures and exact tooling invocations. Guidance that merely restates what the model already knows costs context on every run and makes the output worse, not better. Deletions are as welcome as additions.

## How to Contribute

### Step 1: Open an Issue First

**All contributions start with an issue. Do not open a PR without an approved issue.**

In your issue, explain:

- **What** you want to change or add.
- **Why** — how does this improve the autonomous pipeline? What concrete problem does it solve? Show evidence if you can (failed generations, error logs, before/after comparisons).
- **Why not something simpler** — if there's a lighter-weight way to achieve the same result, explain why your approach is better.

Wait for maintainer approval before writing code. This saves everyone's time — yours included.

### Step 2: Get Approval

A maintainer will respond to your issue. Possible outcomes:

- **Approved** — go ahead and implement.
- **Needs discussion** — the idea has merit but the approach needs refinement.
- **Closed** — doesn't fit the project direction. This isn't personal; the bar is high because scope discipline is how this project stays healthy.

### Step 3: Open a PR

Once approved, open a PR that references the issue. Keep it focused on what was discussed — avoid scope creep.

## What We're Looking For

**Good contributions** typically:

- Fix a bug that causes generation failures or degraded output.
- Improve output quality in a measurable way (better scenes, fewer broken scripts, more reliable asset generation).
- Reduce token usage or API costs without sacrificing quality.
- Improve reliability of the pipeline (fewer crashes, better error recovery).
- Add a silent-failure trap — something that builds clean and still breaks at runtime — that cost you a real debugging session.

**We'll likely close contributions that:**

- Add features the pipeline doesn't need to function.
- Introduce alternative approaches when the existing one works fine.
- Add configuration options for things that should have good defaults.
- Are large refactors without a demonstrated problem they solve.
- Touch many files with cosmetic or stylistic changes.

## Code Expectations

- Match the existing style and conventions in the repo.
- Keep changes minimal and surgical. Small, focused PRs are easier to review and merge.
- If your change touches the engine guide or the asset skill, publish a game repo and run it end-to-end; include the output or a summary of results.

## PRs Without an Approved Issue Will Be Closed

This isn't to be unwelcoming — it's to protect both maintainer time and contributor effort. The worst outcome is someone spending hours on a PR that was never going to be merged. The issue-first process prevents that.

## Bug Reports and Questions

Bug reports don't need prior approval — just open an issue with reproduction steps. Questions and discussions are welcome in issues too.
