# Godot engine guide

Stack: **Godot 4 (.NET / Mono build)**, **C#**. All Godot C# classes must be `partial`.

## Project shape

- `project.godot` — config, input actions, display, physics. **Match version-sensitive fields to the installed toolchain** (`config_version`, and in `.csproj` the `Godot.NET.Sdk/...` version + `TargetFramework`) — run `godot --version` / `dotnet --version` and don't hardcode values from memory; on an existing project preserve them. For 3D, set `3d/physics_engine="Jolt Physics"` and a fixed `physics_ticks_per_second`.
- Autoloads live under `[autoload]` as `GameManager="*res://scripts/GameManager.cs"` — **the `*` prefix is what enables them**; without it the autoload silently never loads.
- `{ProjectName}.csproj` — name must match `assembly_name`; `<EnableDynamicLoading>true</EnableDynamicLoading>`.
- `scripts/*.cs` runtime behavior · `scenes/Build*.cs` headless scene builders · `scenes/*.tscn` generated scenes · `assets/` **only** files the running game loads (keep generation inputs and reference images outside it).
- Build gate: `dotnet build`, then `godot --headless --import` after asset changes, then `godot --headless --quit` (RID-leak warnings on headless exit are benign).

The user watches by running the project themselves (`godot --path .` or the editor) — keep it building and importing cleanly so each run reflects current state.

## Scenes are generated at build time, not by hand

Write scenes as **C# `SceneTree` scripts** that run once headless and emit a `.tscn`: `godot --headless --script scenes/BuildX.cs`. A builder builds the node hierarchy, sets properties, attaches scripts, packs, and **must `Quit()`** or Godot runs forever (exit code 124 from your `timeout`). It contains **no** runtime logic — no `_Ready`/`_Process`, no signal connections, no game state. Build **leaf scenes first**, parents after.

The serialization rules below are silent-failure — they compile and only drop nodes or bloat files in the saved `.tscn`:

- **Owner chain:** every node must have `Owner` set to the scene root or it won't serialize. After building, walk the tree and set `child.Owner = root` on all descendants — but **do not recurse into instantiated GLB/`.tscn` nodes** (those have a non-empty `SceneFilePath`). Recursing into a GLB inlines all its meshes as text → 100MB+ `.tscn`. Setting owner only on direct children silently drops every grandchild.
- **Validate the pack:** count nodes before packing, `Instantiate()` the `PackedScene` after, and compare counts; gate `ResourceSaver.Save()` on the match. A silent drop otherwise looks like success.
- **`SetScript()` disposes the C# wrapper** — set scripts *last*, after the hierarchy is built. For the root, add it under a temp `Node`, set the script, then re-fetch it via `temp.GetChild(0)` before packing.
- Always set `Name` on every node you create — `GetNode` paths in runtime scripts depend on predictable names.
- A builder can't reference an autoload singleton by name; find it via `root.GetChildren()` and match on `Name`. Nodes aren't in the tree yet either, so `LookAt()` / `ToGlobal()` fail — set `RotationDegrees` or compute transforms manually.

Sketch of the shared save path:

```csharp
void PackAndSave(Node root, string path) {
    SetOwnerRecursive(root, root);               // skip nodes with SceneFilePath set
    int expected = CountNodes(root);
    var packed = new PackedScene();
    if (packed.Pack(root) != Error.Ok) { Quit(1); return; }
    var test = packed.Instantiate(); int got = CountNodes(test); test.Free();
    if (got < expected) { GD.PushError("nodes dropped"); Quit(1); return; }   // serialization failed silently
    ResourceSaver.Save(packed, path);
    Quit(0);
}
```

GLB models: instantiate the `PackedScene`, measure the `MeshInstance3D` AABB to scale, and use a **primitive** collision shape (Box/Sphere/Capsule) from the AABB — never `CreateTrimeshShape()`/`CreateConvexShape()` on imported meshes (drops to <1 FPS). The AABB's longest axis also tells you which way the model faces; rotate if it doesn't match the movement direction.

## C# specifics

The compiler catches most of what goes wrong here — run `dotnet build` and read it. These are the ones it can't:

- **Field initializers run before the node is in the tree**, so `GetNode<T>()` there returns null. Resolve children in `_Ready()`.
- **`[Export]` values are applied after the constructor**, so a constructor never sees the inspector value. Read exports in `_Ready()`.
- `Debug.Assert` is compiled out of Release builds and its expression is never evaluated — never put a side effect in one.
- **C# enum names:** training data is GDScript-biased, so guessed C# enum names are often wrong (`BGMode.Sky`, not `BGModeEnum.Sky`). Verify against the installed Godot — read the C# API in the Godot docs/assemblies rather than guessing.

## Silent failures

Everything else Godot does the model already knows; these fail with no error:

- Children's `_Ready()` runs in tree order, so a sibling can emit before another sibling connected. After connecting, check whether the emitter already has data and call the handler once manually.
- `CollisionLayer`/`CollisionMask` are bitmasks, not layer numbers: layer 3 is `1 << 2` = 4. A mask of 6 detects layers 2 and 3.
- `CharacterBody` defaults to `MotionModeEnum.Grounded`, where `FloorStopOnSlope` fights slope movement — use `MotionModeEnum.Floating` for 2D top-down and 3D vehicles.
- Toggling a shape's `Disabled` inside `BodyEntered`/`BodyExited` errors with `Can't change state while flushing queries` — use `SetDeferred("disabled", value)`.
- A pickup spawned inside an active `Area2D` gets `AreaEntered` on the same frame and dies instantly. Track an alive time and ignore the signal for the first ~0.8s.
- `BoxShape3D` on a `RigidBody3D` catches on trimesh edges — use `CapsuleShape3D` for bodies sliding over trimesh terrain. Call `ResetPhysicsInterpolation()` after any teleport or camera swap.
- **Raycasts don't reliably hit `ConcavePolygonShape3D`** (trimesh) — use a shape query or sample terrain height analytically.
- A procedural mesh needs real vertex normals to *receive* shadows: build it with `SurfaceTool` and call `GenerateNormals()` before `Commit()`, or write `ArrayMesh.ArrayType.Normal` yourself. (`ArrayMesh` has no `GenerateNormals` — `RegenNormalMaps` is a different thing.) Without normals, or with `CullMode.Disabled` bolted on as a "safety net", shadows silently vanish — fix winding instead.
- `DirectionalLight3D.ShadowEnabled` defaults to **false**: a lit scene renders, no error, and nothing casts a shadow. Set it on the sun (fill lights should stay off).
- `MultiMeshInstance3D`: `Mesh.Duplicate()` before freeing the source GLB instance or the mesh is collected; set `CustomAabb` to cover the visible extent or it frustum-culls at screen edges; it has no `SetSurfaceOverrideMaterial()` — use `MaterialOverride`. A GLB mesh in a MultiMesh is lost entirely on pack/save; use individual instances. `MaterialOverride` on GLB-internal nodes also won't serialize (their owner is skipped) — build a procedural `ArrayMesh` when a custom material matters.
- `ProceduralSkyMaterial` draws its sun disk from every `DirectionalLight3D` whose `SkyMode` is `LightAndSky` — and that is the default, so each fill light you add silently paints another sun. Set every light except the real sun to `DirectionalLight3D.SkyModeEnum.LightOnly`.
- Wrap a yaw delta before lerping or the camera spins the long way: `var diff = Mathf.PosMod(target - current + Mathf.Pi, Mathf.Tau) - Mathf.Pi;`.
- An invisible or zero-size `Control` still eats clicks at the default `MouseFilterEnum.Stop` — set `Ignore` on overlays and pass-through containers.
- Frame-rate-independent damping is `speed *= Mathf.Exp(-rate * delta)`, not `speed *= (1 - drag)` per tick.
- Z-fighting between layered surfaces (a road on terrain): offset 0.15–0.30m vertically and set `RenderPriority = 1`. Don't combine world-space UVs with `Uv1Scale` — pick one, or you get extreme moiré.
- **`.gdignore`** in a directory makes the importer skip it silently — only `screenshots/` should have one, never `assets/`.

## Running and validating

```bash
dotnet build
timeout 60 godot --headless --path . --import --quit-after 2   # --import alone races and can exit early
timeout 60 godot --headless --quit 2>&1                        # load the project, surface runtime init errors
timeout 60 godot --headless --script scenes/BuildLevel.cs      # run a builder
```

Always wrap headless Godot in `timeout` (`gtimeout` on macOS, from coreutils); exit code 124 means a hang. Usual causes: a `SceneTree` script that never calls `Quit()`; a `godot` on `PATH` that can't resolve `GodotSharp/` (a bare symlink into `Godot_mono.app` hangs with no error — use a wrapper script); or a modal error dialog, which `--quit-after` does not dismiss (a windowed run with no `run/main_scene` waits forever).

Read the output by prefix: `SCRIPT ERROR:` is your bug (the first `res://` frame after `at:` is the culprit), `ERROR:` is engine-level and often non-fatal, `WARNING:` is safe. Ignore RID-leak warnings on headless exit (always present, benign) and editor-only feature warnings. If `godot --headless --quit` crashes with assembly errors, check that `GodotSharp/` sits next to the `godot` binary — Godot resolves it relative to itself. For your own diagnostics, `GD.PushError()` gets a stack trace, `GD.PushWarning()` doesn't, `Console.Error` goes to stderr bare.

## Driving a running game

The user's run is not a black box: an opt-in TCP command bridge sends data and input into a windowed game over `127.0.0.1`. This is also how you drive a game you launched yourself — no separate harness exists.

Add an autoload under `[autoload]` (the `*` rule above applies): `Bridge="*res://scripts/Bridge.gd"` — the GDScript port ships with the published repo and needs no build step. The bridge binds a port only when `OS.GetCmdlineUserArgs()` contains `--bridge` (an optional port follows, default `9080`) — enable with `godot --path . -- --bridge`, user args go after `--`. The gate is mandatory: autoloads instantiate in every run, including `--script` scene builders, `--headless --quit` validation, and `--write-movie` capture, so an ungated bridge binds a port in all of them and collides across concurrent runs.

Empty-project exception: a brand-new project has no `run/main_scene`, and `godot --path .` refuses to start at all — `Can't run project: no main scene defined` — so autoloads never instantiate and the bridge never binds. Create a minimal scene first (a bare root node is enough) and set `run/main_scene` before anything else. The shipped `Bridge.gd` is GDScript and needs no build step — don't convert the project to .NET just for the bridge; the C# contract below stays as the reference for porting to other languages or extending the script.

Wire contract:

- `server.Listen(port, "127.0.0.1")` — the default host is all interfaces; localhost only. Check the returned `Error`: a second listener returns `Error.AlreadyInUse`, which is silent unless read — log it with `GD.PushError` and leave the bridge off rather than crashing the game.
- One command per connection: accept, buffer bytes until `\n`, parse, reply with exactly one JSON line, `DisconnectFromHost()`. No client registry, no framing state across connections.
- Request `{"cmd":"<name>", ...}`; reply `{"ok":true, ...}` or `{"ok":false,"error":"<reason>"}`. Unknown `cmd` → `ok:false`, never silence.
- Commands: `ping` → `{"ok":true,"frame":<Engine.GetProcessFrames()>}`; `action` with `"name"` and optional `"hold"` in seconds (default `0.1`) → `Input.ActionPress(name)`, released from a `GetTree().CreateTimer(hold)` timeout; `state` → a game-defined snapshot dictionary serialized with `Json.Stringify`. The shipped `_snapshot()` carries generic facts (frame, scene, node count, uptime, fps, paused, perf monitors); a game adds its own keys there. Everything else is game-defined.
- Client is `nc`, no tool file: `printf '{"cmd":"ping"}\n' | nc -w 2 127.0.0.1 9080` — connection refused means the game isn't running with `--bridge`. No `nc`? `python3 -c 'import socket,sys;s=socket.create_connection(("127.0.0.1",9080),2);s.sendall(sys.argv[1].encode()+b"\n");print(s.recv(65536).decode())' '{"cmd":"ping"}'`.

Silent failures (each fails with no error):

- `GetUtf8String(n)` with `n` greater than `GetAvailableBytes()` blocks the main thread and freezes the window with no error — always read `GetAvailableBytes()` first, and poll from `_Process`, never a blocking read.
- `GetAvailableBytes()` on a peer the client already closed errors every frame (`Condition "!is_open()" is true`) and the peer never clears — `Poll()` first, drop a peer whose `GetStatus()` is `StatusNone`, and only then read. The `nc` client above closes the moment it has sent, so this is the normal path, not an edge case.
- Every value off the wire can be any JSON type: casting `cmd` to `string` or `hold` to `float` throws inside the handler, which aborts it before the reply is written — the client waits out its own timeout with no answer, breaking the `ok:false` rule above. Type-check each field, and build replies as a `Dictionary` passed through `Json.Stringify` — a concatenated reply string stops being JSON the moment it echoes an unknown `cmd` containing a quote.
- TCP splits and merges writes: a single read can hold half a command or two of them. Buffer per peer until `\n`.
- A peer that connects and never sends holds its slot forever; record the connect time and drop it after ~5s.
- `Input.ActionPress` without a matching `ActionRelease` leaves the action held for the rest of the session — the timed release is not optional.
- `Input.ActionPress` / `Input.ParseInputEvent` bypass the OS input path, so they register while the window is unfocused — the normal case when you drive a game the user launched.
- `--remote-debug` is the editor's debug protocol, not a data channel; don't reach for it.
- Mutating physics state from the command handler follows the `SetDeferred` rule above; capture runs still drive input from the capture script, not the bridge.

The non-blocking poll shape (accept, drain, then handle or drop per peer):

```csharp
public override void _Process(double delta) {
    if (_server == null) return;
    if (_server.IsConnectionAvailable()) {
        var peer = _server.TakeConnection();
        peer.SetNoDelay(true);
        _pending.Add(new Pending { Peer = peer, Since = Time.GetTicksMsec() });
    }
    for (int i = _pending.Count - 1; i >= 0; i--) {
        var p = _pending[i];
        p.Peer.Poll();
        if (p.Peer.GetStatus() == StreamPeerTcp.Status.None) { _pending.RemoveAt(i); continue; }  // client already hung up
        int avail = p.Peer.GetAvailableBytes();
        if (avail > 0) p.Buffer += p.Peer.GetUtf8String(avail);   // never ask for more than avail
        int nl = p.Buffer.IndexOf('\n');
        bool stale = Time.GetTicksMsec() - p.Since > 5000;
        if (nl < 0 && !stale) continue;
        if (nl >= 0) p.Peer.PutData((Handle(p.Buffer[..nl]) + "\n").ToUtf8Buffer());
        p.Peer.DisconnectFromHost();
        _pending.RemoveAt(i);
    }
}
```

## Capture (proof video)

Video needs a hardware GPU driver — Vulkan on Linux/Windows, Metal on macOS (`forward_plus` reports `Metal 4.0 - Forward+` there); a software rasterizer (`llvmpipe`/`lavapipe`) can still do stills but skip video and say so. Detect once per session, and on a headless Linux box run under `xvfb-run -a -s '-screen 0 1920x1080x24'`.

```bash
mkdir -p screenshots/result   # --write-movie into a missing dir writes nothing, silently
godot --headless --import --quit-after 2
timeout 120 godot --rendering-method forward_plus --write-movie screenshots/result/frame.png \
  --fixed-fps 30 --quit-after 450 --script test/Presentation.cs
ffmpeg -y -framerate 30 -pattern_type glob -i 'screenshots/result/frame*.png' \
  -c:v libx264 -pix_fmt yuv420p -crf 28 -vf "scale=min(1280\,iw):-2" -movflags +faststart \
  screenshots/result/video.mp4
```

`--quit-after N` is the length knob and is exact: N movie frames at `--fixed-fps 30` (450 = 15s). Don't bound the clip with a hand-rolled counter in `_PhysicsProcess` — physics keeps running at `physics/common/physics_ticks_per_second` (60 by default), so that counter reaches your target in half the movie frames; pin `Engine.PhysicsTicksPerSecond = 30` in `_Initialize()` if you want the two to line up. For the same reason `await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame)` burns many frames per await. Low fixed fps breaks physics, so keep it at 30 for anything moving. **Pre-position the camera in `_Initialize()`** — the first movie frame renders before `_Process()` — but nodes you add there are not in the tree yet, so `LookAt()` fails with `Node not inside tree`; use `LookAtFromPosition()` or assign `Transform` directly. Drive capture-time input from the script (`Input.ActionPress("jump")`, or `InputEventAction` + `Input.ParseInputEvent()`), not live keys. If a game camera asserts `Current = true` every frame, the capture script has to disable it every frame too. Godot exits 0 and still prints `Done recording movie ... N frames` when it wrote nothing, so verify the capture yourself: the frame count matches `--quit-after`, and the frames are not all identical. The clip must show the behavior progressing across the whole window — no dead time, no single looped frame.
