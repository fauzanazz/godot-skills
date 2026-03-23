# Validation

## LSP Path (Editor Open)

When the Godot editor is running, it exposes a built-in GDScript Language Server on `localhost:6005`. Access via MCP:

```
mcp__ide__getDiagnostics --uri file:///absolute/path/to/script.gd
```

**What it catches:**
- Syntax errors and parse failures
- Static type mismatches (`int` assigned to `String`)
- Unused variables/parameters
- Wrong signal argument counts
- Code warnings (`UNUSED_PARAMETER`, `RETURN_VALUE_DISCARDED`, etc.)

**Cache lag gotcha:** After changing a function signature or renaming a variable, the LSP diagnostic cache can lag — producing false positives for callers that haven't been re-analyzed yet. Fix: save the file, wait ~500ms, re-query. Don't fix "errors" that appear only on the first query after a change.

## CLI Path (Editor Closed)

### Single-file validation

```bash
godot --headless --check-only -s res://scripts/player.gd
```

Parses and type-checks the script without running it. Exit code 0 = clean.

### Project-wide validation

```bash
# Check all scripts on load (existing approach):
timeout 60 godot --headless --quit 2>&1

# Or loop over individual files:
for f in $(find scripts/ -name "*.gd"); do
    godot --headless --check-only -s "res://$f" 2>&1
done
```

The `--quit` approach loads the entire project and reports all parse errors in one pass. Faster for full-project checks. The loop approach gives per-file granularity.

## Decision Table

| Situation | Method |
|---|---|
| Editor open, iterating on a script | `mcp__ide__getDiagnostics` (LSP) |
| Editor closed, CI pipeline | `godot --headless --check-only` |
| Quick full-project check | `timeout 60 godot --headless --quit 2>&1` |
| After modifying multiple scripts | `--quit` full pass |
| Debugging a single file's errors | `--check-only -s` on that file |

## False Positive Patterns

Ignore these in validation output:
- `RID` leak warnings on headless exit — always happens, benign
- `WARNING: ...` about missing editor-only features in headless mode
- Deprecation warnings for APIs that still work in current Godot version

Act on these:
- `Parser Error` — syntax error, must fix
- `SCRIPT ERROR` — runtime error in loaded scripts
- `Cannot find member` / `method not found` — wrong node type or Godot 3.x API usage
- `Cannot infer type` — `:=` with Variant-returning function (see gdscript.md type inference rules)

## Validation Workflow

1. After writing/modifying scripts: validate immediately
2. If LSP available: prefer it (faster, more detailed diagnostics)
3. If LSP unavailable or stale: fall back to `--check-only` or `--quit`
4. Before running tests or capturing screenshots: always validate first
5. After fixing errors: re-validate to confirm clean
