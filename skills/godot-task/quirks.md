# Known Quirks

- **RID leak errors on exit** — headless scene builders always produce these. Harmless; ignore them.
- **`add_to_group()` in scene builders** — groups set at build-time persist in saved .tscn files.
- **MultiMeshInstance3D + GLBs** — does NOT render after pack+save (mesh resource reference lost during serialization). Use individual GLB instances instead.
- **`_ready()` skipped in `_initialize()`** — when running `--script`, `_ready()` on instantiated scene nodes does NOT fire during `_initialize()`. Call `node.generate()` or other init methods manually after `root.add_child()`.
- **`_process()` signature in SceneTree scripts** — must be `func _process(delta: float) -> bool:` (returns bool), not void.
- **Autoloads in SceneTree scripts** — cannot reference autoload singletons by name (compile error). Find them via `root.get_children()` and match by `.name`.
- **`free()` vs `queue_free()` in test harnesses** — `queue_free()` leaves the node in `root.get_children()` until frame end, blocking name reuse. Use `free()` when immediately replacing scenes.
- **Camera2D has no `current` property** — use `make_current()`, and only after the node is in the scene tree.
- **`--write-movie` frame 0** — the first movie frame renders before `_process()` runs. Camera position set in `_process()` won't appear until frame 1. Pre-position the camera in `_initialize()` (via `position`/`rotation_degrees`, NOT `look_at()`) or accept a junk frame 0.
- **`await` during `--write-movie`** — `await get_tree().process_frame` advances the movie frame counter each tick. A single await takes many movie frames, not 1. Use `_init_frames` counter in `_physics_process()` instead of await chains.
- **GLB `material_override` doesn't serialize** — setting `material_override` on GLB-internal MeshInstance3D nodes does NOT persist in .tscn because `set_owner_on_new_nodes()` skips GLB children (has `scene_file_path`). Use procedural ArrayMesh when custom material is required.
- **Camera lerp from origin** — cameras using `lerp()` in `_physics_process()` will visibly swoop from (0,0,0) on the first frame. Use an `_initialized` flag to snap position on the first frame, then lerp on subsequent frames.
- **Chase camera `current` re-assertion** — game cameras that set `current = true` in `_physics_process()` override the test harness camera every frame. Test harnesses must disable the game camera EVERY frame.
## Type Inference Errors

Three common issues — applies in both scene builders and runtime scripts:

```gdscript
# WRONG — load() returns Resource, which has no instantiate():
var scene := load("res://assets/glb/car.glb")
var model := scene.instantiate()  # Error: Resource has no instantiate()

# WRONG — := with instantiate() causes Variant inference error:
var scene: PackedScene = load("res://assets/glb/car.glb")
var model := scene.instantiate()  # Error: Cannot infer type from Variant

# CORRECT — type load() AND use = (not :=) for instantiate():
var scene: PackedScene = load("res://assets/glb/car.glb")
var model = scene.instantiate()  # Works: no type inference attempted

# WRONG — := with array/dictionary element access (returns Variant):
var pos := positions[i]          # Error: Cannot infer type from Variant
var val := my_dict["key"]        # Error: Same problem

# CORRECT — explicit type or untyped:
var pos: Vector3 = positions[i]  # OK
var val = my_dict["key"]         # OK (untyped)
```

## Common Runtime Pitfalls

**UV tiling double-scaling:**
- Do NOT use world-space UV coords AND `uv1_scale` together — causes extreme Moire. Pick one: world-space UVs with `uv1_scale = Vector3(1,1,1)`, OR normalized UVs with `uv1_scale = Vector3(tiles, tiles, 1)`.

**Material visibility in forward_plus:**
- `StandardMaterial3D` with `no_depth_test = true` + `TRANSPARENCY_ALPHA` → invisible. Use opaque + unshaded for overlays.
- Z-fighting between layered surfaces (road on terrain): offset 0.15-0.30m vertically + `render_priority = 1`.
- `cull_mode = CULL_DISABLED` as safety net on all procedural meshes until winding is confirmed correct.
