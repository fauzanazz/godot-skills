# Godot Skills Source Repo

This repository is not a published game repo. It is the source that `publish.sh` renders into a runtime game repo for a chosen host agent.

## Source Layout

- `prompts/runtime.md` — the runtime manifest text
- `asset-gen/` — the asset-generation skill (CLI tools + docs), the one skill every published repo carries
- `engines/godot.md` — the engine guide (stack, project sketch, capture recipe, silent-failure traps)
- `publish.sh` — renders a runtime repo with `--agent {claude,codex,opencode,omp}`
- `scripts/` — render helpers: `render_dir.py` (token substitution), `generate_codex_metadata.py` (Codex `openai.yaml`)

## Editing Rules

- Do not create or maintain `.claude/skills/`, `.agents/skills/`, or `.opencode/skills/` in this source repo.
- Don't give obvious guidance. The agent is a highly capable LLM, and the deliverable (a recorded video, or a game the user runs) surfaces its own mistakes — so keep the guides to what the model can't infer or discover fast.
- `dotnet build` is the oracle. Anything the compiler catches does not belong in the guide — the guide carries only what survives a clean build and fails silently at runtime, plus the exact tooling invocations.
- When you change or remove a feature, describe the new state on its own terms. Name the new thing as if it were always the design.
