# Godogen: AI skills that build complete Godot 4 projects (Claude Code + OpenCode)

[![Watch the video](https://img.youtube.com/vi/eUz19GROIpY/maxresdefault.jpg)](https://youtu.be/eUz19GROIpY)

[Watch the demos](https://youtu.be/eUz19GROIpY) · [Prompts](demo_prompts.md)

You describe what you want. An AI pipeline designs the architecture, generates the art, writes every line of code, captures screenshots from the running engine, and fixes what doesn't look right. The output is a real Godot 4 project with organized scenes, readable scripts, and proper game architecture. Handles 2D and 3D, runs on commodity hardware.

## How it works

- **Two skills orchestrate the entire pipeline** — one plans (`godogen`), one executes (`godot-task`). Each task runs in a fresh context to stay focused.
- **Godot 4 output** — real projects with proper scene trees, scripts, and asset organization.
- **Asset generation** — Gemini creates 2D art and textures; Tripo3D converts selected images to 3D models. Budget-aware: maximizes visual impact per cent spent.
- **GDScript expertise** — custom-built language reference and lazy-loaded API docs for all 850+ Godot classes compensate for LLMs' thin training data on GDScript.
- **Visual QA closes the loop** — captures actual screenshots from the running game and analyzes them with Gemini Flash vision. Catches z-fighting, missing textures, broken physics.
- **Runs on commodity hardware** — any PC with Godot and either Claude Code or OpenCode works.

## Getting started

### Prerequisites

- [Godot 4](https://godotengine.org/download/) (headless or editor) on `PATH`
- One agent runtime:
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code), or
  - [OpenCode](https://opencode.ai/)
- API keys as environment variables:
  - `GOOGLE_API_KEY` — Gemini, used for image generation and visual QA
  - `TRIPO3D_API_KEY` — [Tripo3D](https://platform.tripo3d.ai/), used for image-to-3D model conversion (only needed for 3D games)
- Python 3 with pip (asset tools install their own deps)
- Tested on Ubuntu and Debian. macOS is untested — screenshot capture depends on X11/xvfb/Vulkan and will need a native capture path to work.

### Create a game project

This repo is the skill development source. To set up a game project with skills installed, use `godot-ai-init`:

```bash
# Claude Code setup (default mode)
./godot-ai-init ~/my-game
./godot-ai-init ~/my-game local.md              # custom CLAUDE.md template

# OpenCode setup
./godot-ai-init --mode opencode ~/my-game

# Generate both Claude + OpenCode instruction files
./godot-ai-init --mode both ~/my-game
```

What gets created:
- `.claude/skills/` — skill files (`godogen`, `godot-task`)
- `CLAUDE.md` (Claude mode)
- `AGENTS.md` + `.opencode/opencode.json` (OpenCode mode)
- Git repo initialization

### Run with Claude Code

Open the generated folder in Claude Code and run:

```text
/godogen <your game request>
```

### Run with OpenCode

Open the generated folder in OpenCode and run:

```text
/godogen <your game request>
```

The initializer creates an OpenCode `/godogen` command in `.opencode/opencode.json`.

### Claude vs OpenCode instruction files

| Runtime | Primary instruction file | Notes |
|--------|---------------------------|-------|
| Claude Code | `CLAUDE.md` | Default template is `teleforge.md` |
| OpenCode | `AGENTS.md` | Includes OpenCode-specific workflow guidance |
| OpenCode config | `.opencode/opencode.json` | Adds `/godogen`, skills path, and `godot-task` subagent |

### Running on a VM

A single generation run can take several hours. Running on a cloud VM keeps your local machine free and gives the pipeline a GPU for Godot screenshot capture. A basic GCE instance with a T4 or L4 GPU works well.

The default `CLAUDE.md` (`teleforge.md`) is set up for [Teleforge](https://github.com/htdt/teleforge) — a lightweight Telegram bridge that lets you monitor progress and send messages to the running session from your phone. If you don't use Teleforge, pass your own template to `godot-ai-init` (second positional arg or `--claude-md`).

## Troubleshooting

### OpenCode: "Model not found"

If OpenCode fails with provider/model errors:

1. List available models:
   ```bash
   opencode models
   ```
2. Ensure your provider auth is configured:
   ```bash
   opencode providers
   ```
3. If needed, set a valid model in `.opencode/opencode.json` (`"model": "provider/model"`).

### OpenCode: `godogen` / `godot-task` skills not found

- Ensure `.opencode/opencode.json` exists and has:
  - `skills.paths` including `../.claude/skills`
- Ensure `.claude/skills/godogen/SKILL.md` and `.claude/skills/godot-task/SKILL.md` exist.
- Re-open OpenCode in the project root.

### `CLAUDE_SKILL_DIR` missing

On OpenCode, `CLAUDE_SKILL_DIR` may not be set. Skills in this repo now use fallback paths automatically. For custom commands/scripts, use:

```bash
SKILL_DIR="${CLAUDE_SKILL_DIR:-.claude/skills/<skill-name>}"
```

## Is Claude Code the only option?

No. Both Claude Code and OpenCode are supported.

- Claude Code with Opus 4.6 generally gives the best autonomous generation quality.
- OpenCode works well and supports the same skill structure with project-local setup.

## Roadmap

- Migrate image generation to `grok-imagine-image` (cheaper per image)
- Migrate spritesheets to `grok-imagine-video` (animated sprites from video)
- Add recipes for game builds (Android export)
- Explore C# as GDScript alternative
- Publish a full game end-to-end as a public demo
- Explore Bevy Engine as Godot alternative

Follow progress: [@alex_erm](https://x.com/alex_erm)
