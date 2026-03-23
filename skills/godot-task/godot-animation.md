# Animation

## AnimationPlayer

```gdscript
$AnimationPlayer.play("run")
$AnimationPlayer.speed_scale = velocity.length() / max_speed

# animation_finished for state transitions:
$AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name == &"attack":
        state = State.IDLE
```

## AnimatedSprite2D

```gdscript
$AnimatedSprite2D.play("walk")
$AnimatedSprite2D.play(anim_names.pick_random())

# Flip based on direction:
$AnimatedSprite2D.flip_h = velocity.x < 0
```

## AnimationTree

```gdscript
# Blend parameters (3D):
$AnimationTree.set("parameters/speed/blend_amount", velocity.length() / max_speed)

# State machine playback:
var playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
playback.travel(&"run")
playback.travel(&"idle")

# Check current state:
var current: StringName = playback.get_current_node()
```

## BlendSpace2D

For 2D directional animation (walk in 8 directions):
- Create AnimationTree with BlendSpace2D root
- Place directional animations at Vector2 positions (e.g., idle at origin, walk_right at (1,0))
- Drive with blend_position:

```gdscript
$AnimationTree.set("parameters/blend_position", velocity.normalized())
```

## Character Facing/Rotation

```gdscript
# 3D — face movement direction:
if direction != Vector3.ZERO:
    basis = Basis.looking_at(direction)

# 2D — flip sprite:
if velocity.x != 0:
    $Sprite2D.flip_h = velocity.x < 0

# Isometric 8-directional animation index:
var angle: float = rad_to_deg(direction.angle()) + 22.5
var dir_index: int = int(floor(angle / 45.0)) % 8
```

## @onready References

```gdscript
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
```

Resolve animation node references in `_ready()` or via `@onready` — never call `get_node()` in `_process()`.
