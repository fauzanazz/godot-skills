# Autoloads (Singletons)

## Setup in project.godot

```ini
[autoload]
GameManager="*res://scripts/game_manager.gd"
EventBus="*res://scripts/event_bus.gd"
```

The `*` prefix means the autoload is enabled. Autoloads are added as direct children of the scene tree root, before the main scene loads.

## Access Pattern

```gdscript
# Any script can reference autoloads by name:
GameManager.start_level(2)
EventBus.score_changed.emit(new_score)
```

## GameManager Pattern

Central game state and level transitions:

```gdscript
# game_manager.gd
extends Node

var current_level: int = 0
var score: int = 0
var is_paused: bool = false

func start_level(level_id: int) -> void:
    current_level = level_id
    get_tree().change_scene_to_file("res://scenes/level_%d.tscn" % level_id)

func game_over() -> void:
    get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func restart() -> void:
    score = 0
    start_level(current_level)
```

## EventBus Pattern

Decoupled signal routing — avoids direct node references across scenes:

```gdscript
# event_bus.gd
extends Node

signal score_changed(new_score: int)
signal player_died
signal level_completed(level_id: int)
signal enemy_spawned(enemy: Node)
signal ui_message(text: String, duration: float)
```

Emitters and listeners never know about each other. Any node emits via `EventBus.signal.emit()`, any node connects via `EventBus.signal.connect()`.

## When to Use Autoloads

**Use autoloads for:**
- Global game state (score, lives, settings)
- Cross-scene communication (EventBus)
- Audio manager (music persists across scene changes)
- Save/load system

**Don't use autoloads for:**
- Scene-specific logic (use the scene's root script)
- Data that only one system needs (use a Resource)
- Temporary state (use node properties)

## Gotcha: Autoloads in SceneTree Scripts

Scene builders and test harnesses that `extend SceneTree` cannot reference autoload singletons by name — causes a compile error. Find them via the tree:

```gdscript
# In a SceneTree script:
var game_manager: Node = null
for child in root.get_children():
    if child.name == "GameManager":
        game_manager = child
        break
```
