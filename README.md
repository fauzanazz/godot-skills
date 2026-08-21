# Godot Skills

Autonomous Godot 4 game development with Claude Code, Codex, OpenCode, and OMP.

Describe a game. The agent builds it, generates assets, runs the engine, and proves the result — as a project you run and watch, or as a recorded video when you're not there. It reads the situation and decides which, in the run.

This repo is not a game. It is the source for a generator that produces games: **godot-skills → game repo → game**. You publish into a fresh game repo — choosing the host-agent flavor — then the agent runs inside that repo and builds the actual game from a short engine guide.

Fork of [htdt/godogen](https://github.com/htdt/godogen), narrowed to Godot and extended with OpenCode support.

## Source layout

A published repo is intentionally thin: a runtime manifest, a one-page engine guide, the asset-generation skill, and the `Bridge.gd` TCP command bridge. The agent recreates everything else (project scaffold, scene builders, capture tooling) from the guide.

- `prompts/runtime.md` — the runtime manifest
- `engines/` — `godot.md` (engine guide) + `Bridge.gd` (the shipped TCP command bridge)
- `asset-gen/` — the asset-generation skill
- [publish.sh](publish.sh) — renders the runtime layout for the chosen host agent

Host agent (Claude vs Codex vs OpenCode vs OMP) is a publish-time render choice, not a separate source tree.

## What the agent does

- **Godot 4 / C#** — .NET projects with build-time scene generation from headless `SceneTree` builders, runtime scripts, and Jolt physics.
- **Asset generation** — Gemini for precise references and characters, xAI Grok for textures and simple objects, Tripo3D for image-to-3D and rigged biped animation; animated sprites via Grok video with loop detection and background removal.
- **Proof over claims** — the agent judges results from the running game, not from a clean build, so visible defects drive the next iteration.
- **You choose your involvement** — run the project yourself and steer at decision points, or leave the run unattended and get a 15–20s proof recording at the end. The agent takes its cue from how you frame the task.

## Getting started

### Prerequisites

- [Godot 4](https://godotengine.org/download/) (**.NET build**) on `PATH`, with `GodotSharp/` next to the binary
- .NET 9 SDK or newer
- Python 3.10+ with pip
- System packages and API keys from [setup.md](setup.md): `vulkan-tools`, `xvfb`, `ffmpeg`, `imagemagick`, plus `GOOGLE_API_KEY` / `XAI_API_KEY` / `TRIPO3D_API_KEY`
- Tested on macOS and Ubuntu/Debian
- Claude Code, Codex, OpenCode, or OMP

### Publish a game repo

```bash
./publish.sh --agent claude   --out ~/my-game    # CLAUDE.md + .claude/skills/
./publish.sh --agent codex    --out ~/my-game    # AGENTS.md + .agents/skills/
./publish.sh --agent opencode --out ~/my-game    # AGENTS.md + .opencode/skills/
./publish.sh --agent omp      --out ~/my-game    # AGENTS.md + .omp/skills/
```

Pass `--force` to wipe existing contents at the target before re-publishing.

Then open the game repo in your agent and describe the game. [Prompts](docs/demo_prompts.md).

## Running on a server

A full generation run can take hours, so it's convenient to offload it to a server — ideally a GPU instance, since engine rendering and video capture are much faster with hardware acceleration.

- Keep the session alive across SSH drops with `tmux` or `screen`.
- Enable remote control so you can check in and steer the run from any device — Claude Code, Codex, OpenCode, and OMP all have remote-control interfaces.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
