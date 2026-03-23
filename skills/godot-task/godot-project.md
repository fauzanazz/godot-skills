# Project Setup

## project.godot Key Settings

```ini
[application]
config/name="GameName"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.4")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"     # Scale to window size
window/stretch/aspect="expand"         # Fill without letterboxing

[physics]
common/physics_ticks_per_second=60     # Default; 30 for less demanding games
3d/default_gravity=9.8

[rendering]
renderer/rendering_method="forward_plus"  # Or "mobile" or "gl_compatibility"
```

## Folder Structure

```
project.godot
scenes/
  build_*.gd       # Headless scene builders (produce .tscn)
  *.tscn            # Compiled scenes
scripts/*.gd        # Runtime scripts
assets/
  img/*.png         # 2D textures, sprites
  glb/*.glb         # 3D models
addons/             # Third-party plugins (GUT, etc.)
test/               # Test harnesses
```

## Renderer Selection

| Renderer | Use case | Features |
|---|---|---|
| `forward_plus` | Desktop, high-end | Full PBR, SSR, SSAO, volumetric fog, GI |
| `mobile` | Mobile, mid-range | Subset of forward_plus, no SSR/SSAO |
| `gl_compatibility` | Low-end, Web | OpenGL 3.3, no compute shaders, limited effects |

Set in project.godot or CLI: `godot --rendering-method forward_plus`

## Godot 4.x Hallucination Traps

Common API differences that Claude mixes up between Godot 3.x and 4.x:

| Wrong (3.x) | Correct (4.x) |
|---|---|
| `instance()` | `instantiate()` |
| `connect("signal", obj, "method")` | `signal_name.connect(method)` |
| `emit_signal("name", args)` | `signal_name.emit(args)` |
| `yield(obj, "signal")` | `await obj.signal` |
| `export var x` | `@export var x` |
| `onready var x` | `@onready var x` |
| `KinematicBody2D` | `CharacterBody2D` |
| `move_and_collide()` for movement | `move_and_slide()` (velocity is a property now) |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` |
| `PoolStringArray` | `PackedStringArray` |
| `var x = get_node("Path")` | `var x = $Path` or `%UniqueNode` |
| `tool` keyword | `@tool` annotation |
| `is_instance_valid(x) == false` | `not is_instance_valid(x)` |

## Input Actions in project.godot

```ini
[input]
move_left={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":65)]
}
```

Define all input actions before writing scripts that reference them. The plan's `inputs[]` field is the source of truth.
