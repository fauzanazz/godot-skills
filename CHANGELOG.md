# Changelog

**2026-08-21 — Docs-only runtime**
- Replaced the two-skill pipeline with a thin runtime: a single manifest (`prompts/runtime.md`), a one-page engine guide (`engines/godot.md`), and the `asset-gen` skill. The model plans, scaffolds, and decomposes the work itself.
- Dropped the orchestrator, decomposer, asset planner, visual-target, scaffold, coordination, scene/script-generation, test-harness, and visual-QA docs, along with the 15 `godot-*.md` domain references and the 862-file `doc_api/` tree and its converters. The traps that survive a build but fail at runtime moved into the engine guide; everything derivable was deleted.
- Migrated generated code from GDScript to C# / .NET 9, following upstream. `dotnet build` type-checks the whole project, so the language reference and the type-inference trap list are gone — the compiler reports them. What remains in the engine guide is the silent-failure set: serialization, shadows, physics shapes, culling, and the exact run/capture invocations.
- Adopted upstream's `asset-gen` skill: Grok video animated sprites with loop detection, BiRefNet multi-signal matting with QA preview, Tripo3D v3.1 with biped rig/retarget and resume-without-double-charge.
- `publish.sh` renders per host agent — `--agent claude|codex|opencode` — replacing `godot-ai-init`. Codex support comes from upstream; OpenCode support is this fork's.
- Dropped the Teleforge `CLAUDE.md` template and the Telegram hooks. Claude Code, Codex, and OpenCode all ship their own remote-control interfaces.
- One runtime manifest covers delivery: the agent reads how the task is framed in-run — an open-ended direction gets the game early with checkpoints at taste/scope/cost decisions; a finished brief runs on reasonable calls and closes with a 15–20s proof recording, watched back before done.
- Rewrote the run/capture recipes against a real macOS run (Godot 4.7.2 mono, Metal): a bare `ln -s` into `Godot_mono.app` hangs `--headless` with no error (use a wrapper), `--write-movie` into a missing directory reports success and writes nothing, `--quit-after` counts movie frames while `_PhysicsProcess` runs at 60 Hz, nodes added in `_Initialize()` aren't in the tree yet, and `DirectionalLight3D.ShadowEnabled` defaults to false.

**2026-04-22 — OpenCode support**
- Added OpenCode as a host agent alongside Claude Code: `AGENTS.md` manifest plus `.opencode/opencode.json` for skill discovery
- Compatibility fallbacks for subagent invocation

**2026-04-20 — Domain-specific references**
- Split the monolithic GDScript reference into 15 domain files (nodes, physics, signals, input, UI, animation, state machines, resources, autoload, project, run, validate, debug, test, export)

**2026-03-09 — Fork point**
- Forked from [htdt/godogen](https://github.com/htdt/godogen) at the initial Godot/GDScript release
