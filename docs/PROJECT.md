# Godot Skills: From Prompt to Playable Game

This project turns a natural-language game brief into a playable Godot 4 project. The agent builds the game, generates assets, runs the engine, and proves the result from the running game.

It is not a game engine, a code generator, or an asset marketplace. It is a source repo that publishes a thin runtime — a manifest, an engine guide, and an asset skill — into a fresh game repo that Claude Code, Codex, or OpenCode then builds in.

## Source Model

The repo holds three pieces:

- `prompts/runtime.md` — the runtime manifest
- `asset-gen/` — the asset skill
- `engines/godot.md` — the engine guide

The host agent is selected at render time:

```bash
./publish.sh --agent claude   --out ~/game
./publish.sh --agent opencode --out ~/game
```

Publishing writes `CLAUDE.md` + `.claude/skills/` for Claude Code, `AGENTS.md` + `.agents/skills/` for Codex, or `AGENTS.md` + `.opencode/skills/` for OpenCode — all three are locations the host agent discovers on its own, so no extra config file is generated. Codex `agents/openai.yaml` is generated from the `SKILL.md` frontmatter.

## How a Run Works

The runtime manifest is short: keep durable status in `README.md`, generate assets with the asset skill, and follow the engine guide for stack, project sketch, validation, and capture. There is no fixed multi-stage pipeline and no prescribed document protocol — a capable model plans and decomposes the work itself.

The two things the manifest fixes are *where durable state lives* (`README.md`, so a run survives compaction) and *that the result is proven from the running game*.

The engine guide carries only what the model can't infer or discover quickly: the project sketch, the build-time scene generation contract, the silent-failure traps that pass a clean build but break at runtime, and the run/validate/capture recipes.

## Delivery

The agent decides in-run how to involve the user, reading it from how the task is framed. A task phrased as an open-ended direction gets the game early, with the user steering at decisions of taste, scope, or cost. A task handed over as a finished brief doesn't block on anyone: the agent makes reasonable calls, finishes, and closes with a 15–20s recording of the running game, which it watches back before calling the work done.

## The Compiler Is the Oracle

Generated code is C# on .NET, not GDScript. `dotnet build` type-checks the whole project before anything runs, which turns a large class of runtime surprises into build errors the agent fixes in the same breath — wrong enum, wrong signature, wrong collection type, a class missing `partial`.

That is also what keeps the engine guide short. Anything the compiler reports does not need to be written down; the guide spends its words only on what survives a clean build and then fails silently at runtime — a node that doesn't serialize, a shadow that vanishes, a raycast that passes through terrain.

## What Makes This Different

**Trust the model.** The runtime ships no scaffold and no planner. The model recreates boilerplate from a short sketch and decomposes the work itself; the guides spend their words only on what it genuinely can't know.

**Proof over claims.** A run is judged on the running game — a recorded clip or a project the user runs — not on code that compiles.

**Cost-aware asset generation.** Gemini, Grok, and Tripo3D are used where they make economic sense — the agent confirms costs with the user before generating, and the asset manifest in `README.md` tracks paths, in-game sizes, and costs so implementation doesn't lose them.

## Runtime Limitations

The runtime does not ship an export pipeline or mobile/native packaging.
