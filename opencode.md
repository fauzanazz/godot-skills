Use `/godogen` to generate or update this game from a natural language description.

Visual quality is the top priority. Example failures:
- Generating a detailed image then shrinking it to a tile — details become tiny and clunky. Generate with shapes appropriate for the target size.
- Tiling textures where a single high-quality drawn background is needed.
- Using sprite sheets for fire, smoke, or water instead of procedural particles or shaders.

# Session Instructions

## OpenCode workflow

1. Prefer `/godogen <request>` (configured in `.opencode/opencode.json`).
2. If not using the command, load skill `godogen` directly.
3. For per-task execution, use a fresh sub-agent:
   - Preferred: `task` with `subagent_type: godot-task`
   - Fallback: `task` with `subagent_type: general`, then load skill `godot-task` in the prompt.

## Progress updates

- After creating `PLAN.md`: summarize the plan and reference `reference.png` path.
- After each task: report best screenshot path, task summary, and visual QA verdict (`pass`/`warning`/`fail`).
- Never skip the VQA verdict, even on pass.

# Project Structure

Game projects follow this layout once `/godogen` runs:

```
project.godot          # Godot config: viewport, input maps, autoloads
reference.png          # Visual target — art direction reference image
STRUCTURE.md           # Architecture reference: scenes, scripts, signals
PLAN.md                # Task DAG — Goal/Requirements/Verify/Status per task
ASSETS.md              # Asset manifest with art direction and paths
MEMORY.md              # Accumulated discoveries from task execution
scenes/
  build_*.gd           # Headless scene builders (produce .tscn)
  *.tscn               # Compiled scenes
scripts/*.gd           # Runtime scripts
test/
  test_task.gd         # Per-task visual test harness (overwritten each task)
  presentation.gd      # Final cinematic video script
assets/                # gitignored — img/*.png, glb/*.glb
screenshots/           # gitignored — per-task frames
visual-qa/*.md         # Gemini vision QA reports
```

The working directory is the project root. NEVER `cd` — use relative paths for all commands.

## Limitations

- No audio support
- No animated GLBs — static models only
