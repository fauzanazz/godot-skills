# Headless Execution

## CLI Reference

```bash
# Run game headless, capture all output:
godot --headless --path /project 2>&1 | tee /tmp/godot.log

# Run a utility/tool GDScript directly (no scene needed):
godot --headless -s tools/my_tool.gd

# Type-check a single script:
godot --headless --check-only -s res://scripts/player.gd

# Import assets (re-scan after file changes):
godot --headless --import --quit-after 2

# Run scene builder:
timeout 60 godot --headless --script scenes/build_main.gd

# Validate all project scripts (parse check):
timeout 60 godot --headless --quit 2>&1

# Run with specific renderer:
godot --rendering-method forward_plus
godot --rendering-driver vulkan
```

## Import Gotcha

`--import --quit` has a race condition bug — Godot may quit before imports finish. Use `--quit-after 2` instead:

```bash
timeout 60 godot --headless --import --quit-after 2
```

## Error Output Taxonomy

Parse Godot's stdout/stderr to determine error type and action:

```
SCRIPT ERROR: ...     → GDScript runtime error. Has file:line + stack trace.
                        Action: read the stack trace, fix the script.

ERROR: ...            → Engine-level error (C++ side). Often non-fatal.
                        Action: investigate but may not need fixing.

WARNING: ...          → Non-fatal. Usually safe to ignore unless accumulating.
                        Action: fix if it indicates a real problem.

FATAL: ...            → Engine crash. Null deref or corrupt scene.
                        Action: critical fix needed.

Parser Error          → Syntax error in GDScript.
                        Action: fix the line indicated.

print() output        → Plain stdout, no prefix. Your code's output.
```

## Stack Trace Parsing

Godot stack traces look like:

```
SCRIPT ERROR: Invalid access to property or key 'position' on a base object of type 'null instance'.
   at: _physics_process (res://scripts/player.gd:42)
   at: _process_internal (core/object/object.cpp:1234)
```

Key info: `file:line` after `at:`. The first `res://` line is usually where the bug is.

## Common Runtime Crash Patterns

| Error | Cause | Fix |
|---|---|---|
| `Invalid access ... null instance` | Node ref is null (`@onready` failed or node freed) | Check node path, use `get_node_or_null()` |
| `No loader found for resource` | Asset not imported | Run `--import --quit-after 2` |
| `Cannot call method on a null value` | Variable not initialized | Initialize in `_ready()` or check for null |
| `Stack overflow` | Infinite recursion | Check recursive calls, add base case |
| `Scene cycle detected` | Scene A instances Scene B which instances Scene A | Break the cycle, use signals or deferred loading |
| `method not found` | Wrong node type or 3.x API | Check `extends` type, look up in `doc_api` |
| `Cannot infer type` | `:=` with Variant-returning function | Use explicit type annotation |
| Script hangs (timeout) | Missing `quit()` in scene builder | Add `quit()` at end of `_initialize()` |

## Timeout Patterns

Always wrap headless commands in `timeout`:

```bash
timeout 60 godot --headless --script build.gd    # Scene builders
timeout 60 godot --headless --import --quit-after 2  # Asset import
timeout 60 godot --headless --quit 2>&1           # Validation
timeout 30 godot --headless -s test.gd            # Quick scripts
```

Exit code 124 = timeout fired (script hung or took too long).
