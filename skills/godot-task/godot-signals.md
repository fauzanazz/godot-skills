# Signals

## Declaration

```gdscript
signal my_signal
signal value_changed(new_val: int)
signal died
signal health_changed(new_value: int, old_value: int)
```

## Emit

```gdscript
my_signal.emit()
value_changed.emit(42)
```

## Connect

```gdscript
# Method reference
other_node.my_signal.connect(_on_signal)

# Lambda
other_node.my_signal.connect(func(): print("fired"))

# Bound arguments — handler receives (signal_args..., bound_args...)
other_node.my_signal.connect(_on_signal.bind("extra_data"))

# One-shot (auto-disconnects after first emit)
other_node.my_signal.connect(_on_signal, CONNECT_ONE_SHOT)
```

## Disconnect

```gdscript
other_node.my_signal.disconnect(_on_signal)
# Lambda connections cannot be disconnected — store a reference if needed:
var cb := func(): print("removable")
other_node.my_signal.connect(cb)
other_node.my_signal.disconnect(cb)
```

## Await

```gdscript
await my_signal
await get_tree().create_timer(1.0).timeout
var result = await some_async_func()
```

## Signal Bus Pattern

Decoupled cross-scene communication via an autoload:

```gdscript
# event_bus.gd (autoload)
extends Node
signal score_changed(new_score: int)
signal game_over
signal level_completed(level_id: int)
```

Any node emits: `EventBus.score_changed.emit(score)`. Any node connects: `EventBus.score_changed.connect(_on_score_changed)`.

## Gotchas

- **Sibling `_ready()` timing:** `_ready()` fires on children in tree order. If sibling A emits in its `_ready()`, sibling B hasn't connected yet. Fix: after connecting, check if the emitter already has data and call the handler manually.
- **Connect in `_ready()`, not scene builders** — scripts aren't instantiated at build-time. All signal connections belong in runtime scripts.
- **Lambda capture:** primitives captured by value at creation time. Changing the outer variable after creating the lambda has no effect on the lambda's copy.
