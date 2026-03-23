# Debugging (Headless)

## Output Functions

| Function | When to use |
|---|---|
| `print()` | General debug output, state inspection |
| `print_rich()` | Formatted output with BBCode (`[color=red]error[/color]`) |
| `push_error("msg")` | Reports as `ERROR:` in Godot output, includes stack trace |
| `push_warning("msg")` | Reports as `WARNING:` in output |
| `printerr("msg")` | Prints to stderr (no stack trace, no ERROR prefix) |

Use `push_error()` for conditions that should never happen — it gives you the call stack for free. Use `print()` for state inspection during development.

## Assert

```gdscript
assert(x > 0, "x must be positive")
assert(node != null, "Player node missing")
```

**CRITICAL:** `assert()` is stripped in release builds. The expression is NOT evaluated in release. Never put side effects in asserts:

```gdscript
# WRONG — do_something() won't run in release:
assert(do_something(), "failed")

# CORRECT:
var ok := do_something()
assert(ok, "failed")
```

## Reading Godot Error Output

When running `godot --headless 2>&1`, parse output for:

1. **`SCRIPT ERROR:`** — your bug. Read the `at: (res://file.gd:line)` to locate it.
2. **`ERROR:`** — engine issue. May be caused by your code (null reference) or benign.
3. **`WARNING:`** — usually safe. Fix if it's a real API misuse.
4. **`Parser Error:`** — syntax error. Fix immediately.

## Breakpoint-less Debug Patterns

No interactive debugger in headless mode. Strategies:

### State dumps
```gdscript
func _physics_process(delta: float) -> void:
    if Engine.get_physics_frames() % 60 == 0:  # Every ~1 second
        print("Player state: pos=%s vel=%s floor=%s" % [
            position, velocity, is_on_floor()])
```

### Conditional breakpoints via print
```gdscript
if velocity.length() > 1000:
    push_error("Velocity explosion: %s at frame %d" % [velocity, Engine.get_physics_frames()])
```

### Signal tracing
```gdscript
func _ready() -> void:
    for sig in get_signal_list():
        connect(sig.name, func(...args): print("Signal: %s args=%s" % [sig.name, args]))
```

### Frame-by-frame in test harness
The test harness captures screenshots per frame. Print state at key frames to correlate visual output with internal state:
```gdscript
func _process(_delta: float) -> bool:
    _frame += 1
    print("Frame %d: %s" % [_frame, describe_state()])
    return false
```

## Debug Workflow

1. **Reproduce** — run headless, capture output: `timeout 30 godot --headless --quit 2>&1`
2. **Locate** — find `SCRIPT ERROR` or `ERROR` lines, note `file:line`
3. **Inspect** — read the file at that line, understand the context
4. **Instrument** — add `print()` or `push_error()` near the failure point
5. **Re-run** — check output, iterate until root cause is clear
6. **Fix** — make the change
7. **Validate** — `timeout 60 godot --headless --quit 2>&1` to confirm clean
8. **Clean up** — remove debug prints before committing
