# Node Types

## Decision Tree

### 2D Physics Bodies

| Node | Use when |
|---|---|
| `CharacterBody2D` | Player/NPC movement with `move_and_slide()`, collision response |
| `RigidBody2D` | Physics-driven objects (projectiles, crates, ragdolls) |
| `StaticBody2D` | Immovable collision (walls, floors, platforms) |
| `AnimatableBody2D` | Moving platforms, elevators (moves but isn't pushed) |
| `Area2D` | Triggers, pickups, damage zones (detects overlap, no collision response) |

### 3D Physics Bodies

| Node | Use when |
|---|---|
| `CharacterBody3D` | Player/NPC with custom movement logic |
| `RigidBody3D` | Physics-simulated objects |
| `StaticBody3D` | Static collision geometry |
| `AnimatableBody3D` | Kinematic platforms |
| `Area3D` | Triggers, proximity detection |
| `VehicleBody3D` | Wheeled vehicles (has engine/steering/brake built in) |

### Visuals

| Node | Use when |
|---|---|
| `Sprite2D` | Single 2D image |
| `AnimatedSprite2D` | Frame-by-frame sprite animation |
| `MeshInstance3D` | 3D mesh rendering |
| `MultiMeshInstance3D` | Instanced rendering (grass, debris, crowds) |
| `GPUParticles2D/3D` | Particle effects (fire, smoke, sparks) |
| `CPUParticles2D/3D` | Particle effects (compatibility renderer) |
| `CSGBox3D/Cylinder/Sphere` | Rapid prototyping with collision |

### UI (Control)

| Node | Use when |
|---|---|
| `Label` | Text display |
| `Button` | Clickable action |
| `TextureRect` | Image display in UI |
| `ProgressBar` | Health bar, loading bar |
| `HBoxContainer/VBoxContainer` | Auto-layout children horizontally/vertically |
| `PanelContainer` | Background panel with content |
| `ScrollContainer` | Scrollable content area |

### Utility

| Node | Use when |
|---|---|
| `Timer` | Delayed or repeated callbacks |
| `Camera2D/Camera3D` | Viewport camera |
| `CanvasLayer` | UI layer above game world |
| `AudioStreamPlayer` | Non-positional audio |
| `AudioStreamPlayer2D/3D` | Positional audio |
| `NavigationAgent2D/3D` | Pathfinding |
| `RayCast2D/3D` | Line-of-sight, ground detection |
| `ShapeCast2D/3D` | Volumetric collision query |

## Common Compositions

Every physics body needs a collision shape child:

```
CharacterBody2D
├── Sprite2D (or AnimatedSprite2D)
├── CollisionShape2D
└── Area2D (optional hitbox/hurtbox)
    └── CollisionShape2D

CharacterBody3D
├── MeshInstance3D (or imported GLB)
├── CollisionShape3D
└── Camera3D (if player)
```

## @onready Reference Patterns

```gdscript
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimationPlayer = $AnimationPlayer

# Optional node (may not exist in all scene variants):
@onready var hitbox: Area2D = get_node_or_null("Hitbox")

# Scene-unique nodes (set % in editor, accessible from anywhere in scene):
@onready var player: CharacterBody2D = %Player
```

## Node Reference Syntax

```gdscript
$NodeName                    # Direct child
$Path/To/Node                # Nested path
%UniqueNode                  # Scene-unique (set in editor)
get_node("Path")             # Equivalent to $
get_node_or_null("Path")     # Returns null if not found
has_node("Path")             # Check existence
get_parent()                 # Parent node
get_tree()                   # SceneTree
```

## Gotchas

- **`init()`/`setup()` before `add_child()`** — calling a setup method before the node is in the tree means `@onready` vars are null. Store params in plain vars, apply to nodes in `_ready()`.
- `@onready var x = $Node if has_node("Node") else null` is unreliable. Use `var x: Type = null` and resolve in `_ready()` with `get_node_or_null()`.
- `get_path()` is a built-in Node method (returns NodePath). Never override it — name yours `get_track_path()`, `get_road_path()`, etc.
