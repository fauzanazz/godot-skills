# Physics & Movement

## CharacterBody2D (Top-Down)

```gdscript
extends CharacterBody2D

@export var max_speed := 200.0
@export var acceleration := 1200.0
@export var friction := 1000.0

func _ready() -> void:
    motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if input_dir != Vector2.ZERO:
        velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
    move_and_slide()
```

## CharacterBody3D (Platformer)

```gdscript
extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 4.5

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("left", "right", "up", "down")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    move_and_slide()
```

## Motion Modes

- **GROUNDED** (default) — has `is_on_floor()`, `is_on_wall()`, `is_on_ceiling()`, floor snap, slope handling. Use for platformers.
- **FLOATING** — no floor/wall detection, no gravity helpers. Required for:
  - 2D top-down movement
  - 3D vehicles on slopes (GROUNDED's `floor_stop_on_slope` fights slope movement)
  - Any non-platformer movement

```gdscript
motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
```

## Collision Layers & Masks

`collision_layer` = what this body IS. `collision_mask` = what this body DETECTS.

**CRITICAL: bitmask values, not layer numbers.** UI Layer 1 = bitmask 1, Layer 2 = bitmask 2, Layer 3 = bitmask 4, Layer 4 = bitmask 8.

```gdscript
collision_layer = 1    # This body is on layer 1
collision_mask = 6     # Detects layers 2 (2) and 3 (4): 2+4=6

# Helper for readable layer setting:
func set_layer(layer_num: int) -> void:
    collision_layer = 1 << (layer_num - 1)
```

## Area2D/3D Detection

```gdscript
# Signals
$Area3D.body_entered.connect(_on_body_entered)
$Area3D.body_exited.connect(_on_body_exited)
$Area3D.area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        collect()
```

**Deferred state changes:** Changing collision shape `.disabled` inside `body_entered`/`body_exited` → "Can't change state while flushing queries". Use `set_deferred("disabled", false)`.

**Spawn immunity:** Items spawned inside an active Area2D get `area_entered` immediately → destroyed same frame. Fix: track `_alive_time` in `_process()`, ignore `area_entered` for ~0.8s.

## RigidBody2D/3D

```gdscript
# _integrate_forces for low-level control (called before engine applies forces):
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    var lv = state.get_linear_velocity()
    state.set_linear_velocity(lv)
    for i in range(state.get_contact_count()):
        var normal = state.get_contact_local_normal(i)
        var collider = state.get_contact_collider_object(i)

# Collision exceptions (bullet ignores shooter):
bullet.add_collision_exception_with(shooter)
```

## Spawning Patterns

```gdscript
# Path-based random spawning (enemies, pickups):
var spawn_loc: PathFollow2D = $SpawnPath/SpawnLocation
spawn_loc.progress_ratio = randf()
var mob = MobScene.instantiate()
mob.position = spawn_loc.position

# Auto-cleanup off-screen objects:
$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

# Screen bounds clamping:
position = position.clamp(Vector2.ZERO, screen_size)
```

## Navigation

```gdscript
# 2D: NavigationAgent2D as child of CharacterBody2D
func set_target(pos: Vector2) -> void:
    $NavigationAgent2D.target_position = pos

func _physics_process(_delta: float) -> void:
    if $NavigationAgent2D.is_navigation_finished():
        return
    var next = $NavigationAgent2D.get_next_path_position()
    velocity = global_position.direction_to(next) * speed
    move_and_slide()

# 3D server API:
var path = NavigationServer3D.map_get_path(nav_map, start, target, true)
```

## Jump/Gravity Patterns

```gdscript
# Terminal velocity:
velocity.y = minf(TERMINAL_VELOCITY, velocity.y + gravity * delta)

# Variable jump height (early release):
if Input.is_action_just_released("jump") and velocity.y < 0:
    velocity.y *= 0.6

# Stomp detection via slide collisions:
for i in range(get_slide_collision_count()):
    var col = get_slide_collision(i)
    if col.get_normal().dot(Vector3.UP) > 0.7:
        col.get_collider().squash()
```

## Movement Feel

```gdscript
# Walk/stop force asymmetry for momentum:
if abs(input_dir) > 0.2:
    velocity.x = move_toward(velocity.x, input_dir * MAX_SPEED, WALK_FORCE * delta)
else:
    velocity.x = move_toward(velocity.x, 0, STOP_FORCE * delta)

velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

# 3D smooth acceleration:
horizontal_vel = horizontal_vel.lerp(target_vel, accel * delta)

# Analog input (triggers, sticks):
var throttle: float = Input.get_action_strength("accelerate")  # 0.0-1.0
```

## 2D Top-Down Patterns

- `motion_mode = MOTION_MODE_FLOATING` — required for top-down 2D.
- Collision shape slightly smaller than tile (48px in 64px grid) allows smooth cornering through 1-tile corridors.
- Grid alignment assist: when moving horizontally, snap Y to nearest row center (`round(pos.y / tile_size) * tile_size + tile_size / 2`).
- For modifiable grids (breakable blocks), Sprite2D + StaticBody2D per cell is simpler than TileMapLayer.
- TileMapLayer coordinate conversion: `local_to_map(position)` → cell coords, `map_to_local(cell)` → world position.

## Server API (500+ objects without nodes)

```gdscript
# PhysicsServer2D for bullets, particles:
var shape = PhysicsServer2D.circle_shape_create()
var body = PhysicsServer2D.body_create()
PhysicsServer2D.body_add_shape(body, shape)
PhysicsServer2D.body_set_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM, xform)
PhysicsServer2D.body_set_collision_mask(body, 0)
# MUST cleanup: PhysicsServer2D.free_rid(body) in _exit_tree()

# Custom drawing for server-managed objects:
func _process(_delta: float) -> void:
    queue_redraw()
func _draw() -> void:
    for bullet in bullets:
        draw_texture(bullet_tex, bullet.position)
```

## Physics Gotchas

- **BoxShape3D on RigidBody3D** snags on trimesh collision edges (Godot/Jolt bug). Use CapsuleShape3D for objects sliding across trimesh surfaces.
- **`reset_physics_interpolation()`** — call when teleporting or switching cameras to prevent visible interpolation glitch.
- **Pass-by-value types** — `Vector3`, `AABB`, `Transform3D` etc. are value types. Assigning to a parameter inside a function does NOT update the caller. Use Array accumulator for out-parameters.
- **Collision shapes for imported GLBs** — always use simple primitives (BoxShape3D, SphereShape3D, CapsuleShape3D). Never use `create_convex_shape()` or `create_trimesh_shape()` on high-poly models — causes <1 FPS.
