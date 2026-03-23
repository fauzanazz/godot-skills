# Resources

## Custom Resource Classes

```gdscript
# item_data.gd
class_name ItemData
extends Resource

@export var name: String
@export var description: String
@export var icon: Texture2D
@export var value: int = 0
@export var stackable: bool = true
@export var max_stack: int = 99
```

Create instances in code or as `.tres` files in the editor.

## .tres Text Format

```
[gd_resource type="Resource" script_class="ItemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/item_data.gd" id="1"]

[resource]
script = ExtResource("1")
name = "Health Potion"
description = "Restores 50 HP"
value = 25
stackable = true
max_stack = 10
```

## Loading & Saving Resources

```gdscript
# Load
var item: ItemData = load("res://data/health_potion.tres") as ItemData
var item2: ItemData = ResourceLoader.load("res://data/sword.tres")

# Save
var new_item := ItemData.new()
new_item.name = "Shield"
ResourceSaver.save(new_item, "res://data/shield.tres")

# Preload (compile-time, faster but path must be constant):
const ITEM_SCENE: PackedScene = preload("res://scenes/item.tscn")
# preload fails in headless/scene builders — use load() there
```

## Save/Load Game State

```gdscript
# save_data.gd
class_name SaveData
extends Resource

@export var player_position: Vector3
@export var current_level: int
@export var score: int
@export var inventory: Array[String]
@export var playtime_seconds: float

# Save
func save_game(data: SaveData) -> void:
    ResourceSaver.save(data, "user://savegame.tres")

# Load
func load_game() -> SaveData:
    if ResourceLoader.exists("user://savegame.tres"):
        return ResourceLoader.load("user://savegame.tres") as SaveData
    return null  # No save file
```

`user://` = user data directory (persistent across sessions). `res://` = project directory (read-only in exported builds).

## File I/O (FileAccess)

```gdscript
# Write
var f = FileAccess.open("user://config.json", FileAccess.WRITE)
f.store_string(JSON.stringify(data))

# Read
var text = FileAccess.get_file_as_string("user://config.json")
var data = JSON.parse_string(text)

# Check existence
if FileAccess.file_exists("user://savegame.tres"):
    pass
```

## Resource vs File I/O

- **Resource** (`.tres`) — typed, editor-friendly, supports `@export` variables, Godot-native. Use for game data, configs, save states.
- **FileAccess** — raw file operations. Use for JSON configs, log files, external data exchange.
- **ConfigFile** — INI-style key-value storage. Use for simple settings:

```gdscript
var config := ConfigFile.new()
config.set_value("audio", "volume", 0.8)
config.save("user://settings.cfg")

config.load("user://settings.cfg")
var vol: float = config.get_value("audio", "volume", 1.0)
```
